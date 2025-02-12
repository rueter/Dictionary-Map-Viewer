#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above when the project is opened in RStudio.
#
# This app has been developed by Niko Partanen and Jack Rueter.

library(shiny)
library(dplyr)
library(xml2)
library(tidyr)
library(leaflet)

# Read the XML file
#xml_data <- read_xml("data/test_paasonen_mw_2024_12_27.xml")

# Add error handling for URL access
tryCatch({
  xml_data <- read_xml("https://raw.githubusercontent.com/rueter/Dictionary-Map-Viewer/refs/heads/main/data/test_paasonen_mw_2024_12_27.xml")
}, error = function(e) {
  # Log the error and provide a user-friendly message
  message("Error loading XML data: ", e$message)
  # You might want to return a default/empty XML or stop the app gracefully
})

# Function to safely extract text from nodes
safe_text <- function(node) {
  if(length(node) > 0) {
    return(xml_text(node))
  }
  return(NA)
}

# Extract entries
entries <- xml_find_all(xml_data, "//e")

# Create empty lists to store data
data_list <- list()
row_counter <- 1

# Process each entry
for(i in seq_along(entries)) {
  entry <- entries[i]

  # Get the base lemmas - modified to get the id attribute and parse it
  myv_l <- xml_find_first(entry, ".//lb[@iso_lang='myv']/l")
  mdf_l <- xml_find_first(entry, ".//lb[@iso_lang='mdf']/l")

  lemma_myv <- if(!is.na(myv_l)) {
    id_str <- xml_attr(myv_l, "id")
    # Extract the base form from the id (assuming format like "E:1:N+Sg+Nom+Indef:кедь")
    strsplit(id_str, ":")[[1]][length(strsplit(id_str, ":")[[1]])]
  } else NA

  lemma_mdf <- if(!is.na(mdf_l)) {
    id_str <- xml_attr(mdf_l, "id")
    strsplit(id_str, ":")[[1]][length(strsplit(id_str, ":")[[1]])]
  } else NA

  # Get translations
  rus_trans <- safe_text(xml_find_first(entry, ".//tg[@iso_lang='rus']/t"))
  deu_trans <- safe_text(xml_find_first(entry, ".//tg[@iso_lang='deu']/t"))

  # Process Erzya (myv) variants
  myv_variants <- xml_find_all(entry, ".//lb[@iso_lang='myv']/l_var")
  for(variant in myv_variants) {
    orig_var <- xml_attr(variant, "orig_var")
    geo_nodes <- xml_find_all(variant, ".//geoU")

    for(geo in geo_nodes) {
      location <- xml_attr(geo, "orig_geo")
      if(!is.na(location) && location != "") {
        data_list[[row_counter]] <- data.frame(
          entry_num = i,
          language = "myv",
          base_form = lemma_myv,
          variant = orig_var,
          location = location,
          russian_translation = rus_trans,
          german_translation = deu_trans,
          stringsAsFactors = FALSE
        )
        row_counter <- row_counter + 1
      }
    }
  }

  # Process Moksha (mdf) variants
  mdf_variants <- xml_find_all(entry, ".//lb[@iso_lang='mdf']/l_var")
  for(variant in mdf_variants) {
    orig_var <- xml_attr(variant, "orig_var")
    geo_nodes <- xml_find_all(variant, ".//geoU")

    for(geo in geo_nodes) {
      location <- xml_attr(geo, "orig_geo")
      if(!is.na(location) && location != "") {
        data_list[[row_counter]] <- data.frame(
          entry_num = i,
          language = "mdf",
          base_form = lemma_mdf,
          variant = orig_var,
          location = location,
          russian_translation = rus_trans,
          german_translation = deu_trans,
          stringsAsFactors = FALSE
        )
        row_counter <- row_counter + 1
      }
    }
  }
}

# Combine all data frames
final_df <- dplyr::bind_rows(data_list)

# Clean up the data frame
final_df <- final_df %>%
  distinct() %>%  # Remove any duplicate rows
  dplyr::arrange(entry_num, language, location) %>%
  as_tibble()

# View the result
# View(as_tibble(final_df))

tryCatch({
  map_coordinates <- readr::read_csv("https://raw.githubusercontent.com/rueter/Dictionary-Map-Viewer/refs/heads/main/data/PMW_locale_01a.csv",
                              show_col_types = FALSE)
}, error = function(e) {
  message("Error loading CSV data: ", e$message)
  # Handle the error appropriately
})

location_lookup <- map_coordinates %>%
  select(id, coordinate, name_deu) %>%
  rename(name = name_deu) %>%
  separate(coordinate, into = c("latitude", "longitude"), sep = ", ") %>%
  mutate(latitude = stringr::str_squish(latitude)) %>%
  mutate(longitude = stringr::str_squish(longitude)) %>%
  filter(! is.na(longitude)) %>%
  filter(! is.na(latitude)) %>%
  rename(location = id) %>%
  mutate(location = stringr::str_replace(location, "Mdf:", "M:")) %>%
  mutate(location = stringr::str_replace(location, "Myv:", "E:"))

df <- final_df %>%
  left_join(location_lookup, by = "location") %>%
  mutate(latitude = as.double(latitude)) %>%
  mutate(longitude = as.double(longitude)) %>%
  filter(! is.na(longitude))

# final_df %>% filter(is.na(name)) %>%
#   distinct(location) %>%
#   pull(location)

# UI
ui <- fluidPage(
  titlePanel("Mordvin Dialect Map"),

  div(class = "row",
      # Left column containing sidebarPanel and the additional info
      div(class = "col-sm-4",
          # Original sidebar content
          div(class = "well",
              selectInput("german_word",
                          "Select German Translation:",
                          choices = unique(df$german_translation)),
              htmlOutput("variant_info")
          ),
          # Additional info panel
          div(class = "well",
              HTML("<h4>Additional Information</h4>
                   <p>This application has been developed by Niko Partanen and Jack Rueter. The application can be extended to display geographic variants of different terms in different languages.</p>
                   <p>It is part of the Finno-Ugrian Society's digitization work with the goal of making dialect dictionaries of Uralic languages more accessible online. It also connects to the Uralic-Amazonian collaboration coordinated by professors Pirjo Kristiina Virtanen (University of Helsinki), Sidney Facundes (Federal University of Pará (UFPA), Belém) and Thiago Cardoso Mota (Federal University of Amazonas, Manaus).</p>")
          )
      ),

      # Right column containing main panel
      div(class = "col-sm-8",
          # Leaflet map
          leafletOutput("dialect_map", height = "600px"),

          # Data table showing variants
          DT::dataTableOutput("variant_table")
      )
  )
)

# Server
server <- function(input, output, session) {
  
  # At the top of your app.R
  options(shiny.error = function() {
    cat(file=stderr(), "An error occurred:\n")
    traceback(2)
  })
  
  observe({
    query <- parseQueryString(session$clientData$url_search)
    if (!is.null(query[["health"]])) {
      cat(file=stderr(), "Health check passed\n")
    }
  })

  # Reactive filtered data based on selected German translation
  filtered_data <- reactive({
    # First get the entry_num(s) for the selected German translation
    entry_nums <- df %>%
      filter(german_translation == input$german_word) %>%
      pull(entry_num) %>%
      unique()

    # Then get all variants for those entry numbers
    df %>%
      filter(entry_num %in% entry_nums)
  })

  # Create the map
  output$dialect_map <- renderLeaflet({
    data <- filtered_data()

    # Create color palette for variants
    pal <- colorFactor(
      palette = "Set3",
      domain = data$variant
    )

    # Base map
    leaflet(data) %>%
      addTiles() %>%
      addCircleMarkers(
        ~longitude, ~latitude,
        color = ~pal(variant),
        radius = 8,
        fillOpacity = 0.9,
        opacity = 1,
        popup = ~paste(
          "<strong>Variant:</strong>", variant,
          "<br><strong>Location:</strong>", location,
          "<br><strong>Language:</strong>", language
        ),
        label = ~variant
      ) %>%
      addLegend(
        "bottomright",
        pal = pal,
        values = ~variant,
        title = "Variants"
      )
  })

  # Create information panel
  output$variant_info <- renderUI({
    data <- filtered_data()

    HTML(paste(
      "<h4>Word Information:</h4>",
      "<strong>Base forms:</strong>", paste(unique(data$base_form), collapse = ", "), "<br>",
      "<strong>Russian:</strong>", paste(unique(data$russian_translation), collapse = ", "), "<br>",
      "<strong>German:</strong>", input$german_word, "<br>",
      "<strong>Number of variants:</strong>", length(unique(data$variant)), "<br>",
      "<strong>Languages:</strong>", paste(unique(data$language), collapse = ", ")
    ))
  })

  # Create data table
  output$variant_table <- DT::renderDataTable({
    data <- filtered_data()

    DT::datatable(
      data %>%
        select(base_form, variant, location, language) %>%
        arrange(language, variant),
      options = list(pageLength = 5)
    )
  })
}

# Run the app
shinyApp(ui = ui, server = server)




