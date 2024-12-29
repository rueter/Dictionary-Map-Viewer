FROM rocker/shiny:4.3.2

# Install required system packages
RUN apt-get update && apt-get install -y \
    gettext-base \
    && rm -rf /var/lib/apt/lists/*

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

# Create shiny-server.conf that works with arbitrary UIDs
RUN echo '# Define the user we should use when spawning R Shiny processes\nrun_as :ENV_SHINY_USER:\n\n# Define a top-level server which will listen on a port\nserver {\n  listen 3838;\n\n  # Define the location available at the base URL\n  location / {\n    site_dir /srv/shiny-server;\n    log_dir /var/log/shiny-server;\n    directory_index on;\n  }\n}' > /etc/shiny-server/shiny-server.conf

# Create run script
RUN echo '#!/bin/bash\n\nexport ENV_SHINY_USER=$(id -u)\nenvsubst < /etc/shiny-server/shiny-server.conf > /etc/shiny-server/shiny-server.conf.tmp\nmv /etc/shiny-server/shiny-server.conf.tmp /etc/shiny-server/shiny-server.conf\n\nexec /usr/bin/shiny-server' > /usr/bin/run-shiny.sh && \
    chmod +x /usr/bin/run-shiny.sh

EXPOSE 3838

CMD ["/usr/bin/run-shiny.sh"]