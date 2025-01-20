FROM rocker/r-ver:4.3.2

ENV RSTUDIO_VERSION=2023.09.1+494
ENV PANDOC_VERSION=default

ENV PATH=/usr/lib/rstudio-server/bin:$PATH

# Install core utilities and debconf-utils package
RUN apt-get update && apt-get install -y coreutils debconf-utils

RUN /rocker_scripts/install_rstudio.sh
RUN /rocker_scripts/install_shiny_server.sh
RUN apt\-get update && apt\-get upgrade \-y && apt\-get install \-\-no\-install\-recommends \-y \\
apt\-utils \\
libnss\-wrapper \\
libnode72 \\
libbz2\-dev \\
liblzma\-dev \\
librsvg2\-dev \\
libudunits2\-dev \\
libgdal\-dev \\
libgeos\-dev \\
libproj\-dev \\
libmysqlclient\-dev \\
strace \\
mlocate \\
nano && \\
apt\-get clean && rm \-rf /var/lib/apt/lists/\*
\# Setup various variables
ENV TZ\="Europe/Helsinki" \\
USERNAME\="rstudio\-server" \\
HOME\="/home/" \\
TINI\_VERSION\=v0\.19\.0 \\
APP\_UID\=999 \\
APP\_GID\=999 \\
PKG\_R\_VERSION\=4\.3\.1 \\
PKG\_RSTUDIO\_VERSION\=2023\.09\.1\+494 \\
PKG\_SHINY\_VERSION\=1\.5\.21\.1012
\# Setup Tini, as S6 does not work when run as non\-root users
ADD https\://github\.com/krallin/tini/releases/download/</span>{TINI_VERSION}/tini /sbin/tini
RUN chmod +x /sbin/tini

COPY shiny-server.conf /etc/shiny-server/shiny-server.conf

RUN install2.r -e shiny rmarkdown shinythemes shinydashboard && \
    mkdir -p /var/log/shiny-server && \
    chown rstudio:rstudio /var/log/shiny-server && \
    chmod go+w -R /var/log/shiny-server /usr/local/lib/R /srv /var/lib/shiny-server && \
    chmod ugo+rwx -R /usr/lib/rstudio-server/www && \
    echo 'r-libs-user=~/R/library' >>/etc/rstudio/rsession.conf && \
    echo "R_LIBS=\${R_LIBS-'/home/rstudio-server/R/library'}" >/usr/local/lib/R/etc/Renviron.site

COPY start.sh /usr/local/bin/start.sh

RUN rstudio-server verify-installation

RUN chmod -R go+rwX /home /home/rstudio /tmp/downloaded_packages /var/run/rstudio-server /var/lib/rstudio-server /var/log/rstudio && \
    rm /var/lib/rstudio-server/rstudio-os.sqlite /var/run/rstudio-server/rstudio-rsession/rstudio-server-d.pid

USER $APP_UID:$APP_GID
# Set working directory to /srv/shiny-server
WORKDIR /srv/shiny-server
EXPOSE 3838
