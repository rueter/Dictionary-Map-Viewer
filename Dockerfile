FROM rocker/shiny:4.3.2
# Install R packages
RUN R -e "install.packages(c('shiny', 'leaflet', 'dplyr', 'tidyr', 'readr', 'stringr', 'xml2'), repos='https://cloud.r-project.org/', dependencies=TRUE)"
# Copy your app and data
COPY app.R /srv/shiny-server/
# Set up permissions for OpenShift
RUN chmod -R 777 /srv/shiny-server/ && \
    chmod -R 777 /var/lib/shiny-server/ && \
    chmod -R 777 /var/log/shiny-server/ && \
    chmod -R 777 /etc/shiny-server/ && \
    chmod -R 777 /opt/shiny-server/
# Create run script that will generate the config at runtime
RUN echo '#!/bin/bash\n\
USER_ID=$(id -u)\n\
echo "run_as $USER_ID;\n\
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