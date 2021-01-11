# This dockerfile will create a base image that has rauth0 and all dependencies installed

FROM rocker/r-base:3.6.3
LABEL AUTHOR=auth0/data-engineering
LABEL REPO=auth0/rauth0

COPY . /rauth0

# Install devtools and remotes to help us install dependencies for rauth0
RUN apt-get update && \
  apt-get install -y libcurl4-openssl-dev libssl-dev libssh2-1-dev libxml2-dev libpq-dev awscli build-essential

RUN R cmd -e "install.packages('devtools', dependencies = TRUE)"

# Install non-CRAN dependencies
RUN R cmd -e "devtools::install_github('cloudyr/aws.s3')"
RUN R cmd -e "devtools::install_github('cloudyr/aws.ec2metadata')"
RUN R cmd -e "devtools::install_github('scottypate/redshiftTools')"
RUN R cmd -e "devtools::install('/rauth0', dependencies = TRUE)"

