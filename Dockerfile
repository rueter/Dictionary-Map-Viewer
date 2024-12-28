FROM ubuntu:latest

# Install R and required system dependencies
RUN apt-get update && apt-get install -y \
    r-base \
    r-base-dev \
    libcurl4-gnutls-dev \
    libxml2-dev \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Install R packages
RUN R -e "install.packages(c('shiny', 'dplyr', 'xml2', 'tidyr', 'leaflet'), repos='https://cloud.r-project.org/')"

# Download and install Shiny Server
RUN apt-get update && apt-get install -y \
    gdebi-core \
    && wget https://download3.rstudio.org/ubuntu-14.04/x86_64/shiny-server-1.5.17.973-amd64.deb \
    && gdebi -n shiny-server-1.5.17.973-amd64.deb \
    && rm shiny-server-1.5.17.973-amd64.deb \
    && rm -rf /var/lib/apt/lists/*

# Copy your app into the image
COPY app.R /srv/shiny-server/
COPY data/ /srv/shiny-server/data/  # Uncomment if you have data files

# Make the app available at port 3838
EXPOSE 3838

CMD ["/usr/bin/shiny-server"]
