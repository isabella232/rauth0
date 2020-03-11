# This dockerfile will create a base image that has rauth0 and all dependencies installed

FROM rocker/tidyverse:latest
LABEL AUTHOR=auth0/data-engineering
LABEL REPO=auth0/rauth0

COPY . /rauth0

RUN install2.r --error \
    remotes \
    devtools

RUN R -e "devtools::install_github('cloudyr/aws.s3')"
RUN R -e "devtools::install_github('sicarul/redshiftTools')"
RUN R -e "remotes::install_local('/rauth0', dependencies = TRUE)"
