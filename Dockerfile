FROM rocker/r-ver:4.3.2

ENV RSTUDIO_VERSION=2023.09.1+494
ENV PANDOC_VERSION=default
ENV PATH=/usr/lib/rstudio-server/bin:$PATH

# Install system dependencies first
RUN apt-get update && apt-get upgrade -y && apt-get install --no-install-recommends -y \
    apt-utils \
    libnss-wrapper \
    libnode72 \
    libbz2-dev \
    liblzma-dev \
    librsvg2-dev \
    libudunits2-dev \
    libgdal-dev \
    libgeos-dev \
    libproj-dev \
    libmysqlclient-dev \
    strace \
    mlocate \
    nano && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Environment variables
ENV TZ="Europe/Helsinki" \
    USERNAME="rstudio-server" \
    HOME="/home/" \
    TINI_VERSION=v0.19.0 \
    APP_UID=999 \
    APP_GID=999 \
    PKG_R_VERSION=4.3.1 \
    PKG_RSTUDIO_VERSION=2023.09.1+494 \
    PKG_SHINY_VERSION=1.5.21.1012

# Create necessary directories and set up initial permissions
RUN mkdir -p /home/rstudio-server && \
    mkdir -p /tmp/downloaded_packages && \
    mkdir -p /var/run/rstudio-server && \
    mkdir -p /var/lib/rstudio-server && \
    mkdir -p /var/log/rstudio && \
    mkdir -p /var/log/shiny-server && \
    mkdir -p /srv/shiny-server

# Install R packages one at a time to manage memory better
RUN R -e 'install.packages("shiny", repos="https://cloud.r-project.org/")' && \
    R -e 'install.packages("rmarkdown", repos="https://cloud.r-project.org/")' && \
    R -e 'install.packages("shinythemes", repos="https://cloud.r-project.org/")'

# Install RStudio and Shiny Server after R packages
RUN /rocker_scripts/install_rstudio.sh
RUN /rocker_scripts/install_shiny_server.sh

# Install Tini
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /sbin/tini
RUN chmod +x /sbin/tini

# Copy configuration files
COPY shiny-server.conf /etc/shiny-server/shiny-server.conf
COPY app.R /srv/shiny-server/
COPY start.sh /usr/local/bin/start.sh

# Set permissions for all directories
RUN chown -R rstudio-server:rstudio-server \
    /home/rstudio-server \
    /tmp/downloaded_packages \
    /var/run/rstudio-server \
    /var/lib/rstudio-server \
    /var/log/rstudio \
    /var/log/shiny-server \
    /srv/shiny-server && \
    chmod -R go+rwX \
    /home \
    /home/rstudio-server \
    /tmp/downloaded_packages \
    /var/run/rstudio-server \
    /var/lib/rstudio-server \
    /var/log/rstudio \
    /var/log/shiny-server \
    /srv/shiny-server \
    /usr/local/lib/R && \
    chmod ugo+rwx -R /usr/lib/rstudio-server/www && \
    echo 'r-libs-user=~/R/library' >>/etc/rstudio/rsession.conf && \
    echo "R_LIBS=\${R_LIBS-'/home/rstudio-server/R/library'}" >/usr/local/lib/R/etc/Renviron.site

# Verify installation
RUN rstudio-server verify-installation

# Clean up any leftover files
RUN rm -f /var/lib/rstudio-server/rstudio-os.sqlite \
    /var/run/rstudio-server/rstudio-rsession/rstudio-server-d.pid || true

USER rstudio-server
WORKDIR $HOME
EXPOSE 3838

ENTRYPOINT ["/sbin/tini", "-g", "--"]
CMD ["/usr/local/bin/start.sh"]