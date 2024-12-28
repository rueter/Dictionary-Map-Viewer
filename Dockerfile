FROM rocker/shiny:latest

# Install system dependencies using install2.r
RUN R -e "install.packages(c('curl', 'xml2', 'openssl'), repos='https://cloud.r-project.org/')"

# Install R packages
RUN R -e "install.packages(c('shiny', 'dplyr', 'xml2', 'tidyr', 'leaflet'), repos='https://cloud.r-project.org/')"

# Copy your app into the image
COPY app.R /srv/shiny-server/
COPY data/ /srv/shiny-server/data/  # if you have data files

# Make the app available at port 3838
EXPOSE 3838

CMD ["/usr/bin/shiny-server"]
