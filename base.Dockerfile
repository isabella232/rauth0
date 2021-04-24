# This dockerfile will create a base image that has base R deps installed, including devtools

FROM r-base:3.6.0
LABEL AUTHOR=auth0/data-engineering
LABEL REPO=auth0/rauth0

# Install devtools and remotes to help us install dependencies for rauth0
RUN apt-get update
RUN apt-get install -y \
    gcc-8-base \
    build-essential \
    libcurl4-gnutls-dev \
    libxml2-dev \
    libssl-dev \
    libssh2-1-dev \
    libpq-dev \
    awscli \
    r-cran-devtools \
    default-jdk \
    default-jre \
    r-cran-rjava \
    r-base-dev
