FROM rocker/shiny-verse:4.3.2

# Install R packages all at once to optimize build
RUN R -e "install.packages(c(\
    'shiny', \
    'leaflet', \
    'dplyr', \
    'tidyr', \
    'readr', \
    'stringr', \
    'xml2' \
    ), \
    repos='https://cloud.r-project.org/', \
    dependencies=TRUE)"

# Copy your app and data
COPY app.R /srv/shiny-server/
#COPY data /srv/shiny-server/data

EXPOSE 3838

CMD ["/usr/bin/shiny-server"]