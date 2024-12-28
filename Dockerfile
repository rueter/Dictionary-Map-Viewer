FROM rocker/shiny:latest

# Install system dependencies if needed
RUN apt-get update && apt-get install -y \
    libcurl4-gnutls-dev \
    libxml2-dev \
    libssl-dev

# Install R packages
RUN R -e "install.packages(c('shiny', 'other-packages-you-need'), repos='https://cloud.r-project.org/')"

# Copy your app into the image
COPY app.R /srv/shiny-server/
COPY data/ /srv/shiny-server/data/  # if you have data files

# Make the app available at port 3838
EXPOSE 3838

CMD ["/usr/bin/shiny-server"]
