# This dockerfile will create a base image that has rauth0 and all dependencies installed

FROM rocker/r-base:latest
LABEL AUTHOR=auth0/data-engineering
LABEL REPO=auth0/rauth0

COPY . /rauth0

# Install devtools and remotes to help us install dependencies for rauth0
RUN apt-get update && \
  apt-get install -y libcurl4-openssl-dev libssl-dev libssh2-1-dev libxml2-dev libpq-dev && \
  R -e "install.packages(c('devtools', 'testthat', 'roxygen2', 'remotes'))"

# Install non-CRAN dependencies
RUN R -e "devtools::install_github('cloudyr/aws.s3')"
RUN R -e "devtools::install_github('sicarul/redshiftTools')"
RUN R -e "remotes::install_local('/rauth0', dependencies = TRUE)"
