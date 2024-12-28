FROM ubuntu:latest

# Install R and required system dependencies
RUN apt-get update && apt-get install -y \
    r-base \
    r-base-dev \
    libcurl4-gnutls-dev \
    libxml2-dev \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Install R packages all at once to optimize build
#RUN R -e "install.packages(c('shiny', 'leaflet', 'dplyr', 'tidyr', 'readr', 'stringr', 'xml2'), repos='https://cloud.r-project.org/', dependencies=TRUE)"

# Install R packages
RUN R -e "install.packages(c('shiny', 'dplyr', 'xml2', 'tidyr', 'leaflet'), repos='https://cloud.r-project.org/')"

# Download and install Shiny Server
RUN apt-get update && apt-get install -y \
    gdebi-core \
    && wget https://download3.rstudio.org/ubuntu-14.04/x86_64/shiny-server-1.5.17.973-amd64.deb \
    && gdebi -n shiny-server-1.5.17.973-amd64.deb \
    && rm shiny-server-1.5.17.973-amd64.deb \
    && rm -rf /var/lib/apt/lists/*

# Copy your app and data
COPY app.R /srv/shiny-server/
#COPY data /srv/shiny-server/data

# Fix permissions for OpenShift
RUN chmod -R 777 /srv/shiny-server/ && \
    chmod -R 777 /var/lib/shiny-server/ && \
    chmod -R 777 /var/log/shiny-server/

# Update the ownership of the Shiny app files
RUN chgrp -R 0 /var/log/shiny-server/ && \
    chmod -R g=u /var/log/shiny-server/ && \
    chgrp -R 0 /srv/shiny-server/ && \
    chmod -R g=u /srv/shiny-server/ && \
    chgrp -R 0 /var/lib/shiny-server/ && \
    chmod -R g=u /var/lib/shiny-server/

EXPOSE 3838

# Modify shiny-server.conf to run as non-root
RUN sed -i 's/run_as shiny/run_as shiny\npreserve_logs true/' /etc/shiny-server/shiny-server.conf

CMD ["/usr/bin/shiny-server"]