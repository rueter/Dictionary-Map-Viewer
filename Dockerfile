FROM rocker/shiny:4.3.2

# Install R packages all at once to optimize build
RUN R -e "install.packages(c('shiny', 'leaflet', 'dplyr', 'tidyr', 'readr', 'stringr', 'xml2'), repos='https://cloud.r-project.org/', dependencies=TRUE)"

# Copy your app and data
COPY app.R /srv/shiny-server/

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