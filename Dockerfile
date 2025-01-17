FROM rocker/shiny:4.3.2

# Install R packages
RUN R -e "install.packages(c('shiny', 'leaflet', 'dplyr', 'tidyr', 'readr', 'stringr', 'xml2'), repos='https://cloud.r-project.org/', dependencies=TRUE)"

# Copy your app and data
COPY app.R /srv/shiny-server/

# Set up permissions for OpenShift - using arbitrary user IDs
RUN mkdir -p /var/log/shiny-server && \
    chown -R root:0 /srv/shiny-server/ /var/lib/shiny-server/ /var/log/shiny-server/ /etc/shiny-server/ && \
    chmod -R g=u /srv/shiny-server/ /var/lib/shiny-server/ /var/log/shiny-server/ /etc/shiny-server/ && \
    chmod -R 777 /var/log/shiny-server/

# Create run script that will generate the config at runtime
RUN echo '#!/bin/bash\n\
echo "run_as \${SHINY_USER_ID:-1000};\n\
server {\n\
  listen 8080;\n\
  location / {\n\
    site_dir /srv/shiny-server;\n\
    log_dir /var/log/shiny-server;\n\
    directory_index on;\n\
  }\n\
}" > /etc/shiny-server/shiny-server.conf\n\
\n\
exec /usr/bin/shiny-server' > /usr/bin/run-shiny.sh && \
    chmod +x /usr/bin/run-shiny.sh

EXPOSE 8080
CMD ["/usr/bin/run-shiny.sh"]
