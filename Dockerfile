# This dockerfile will create a base image that has rauth0 and all dependencies installed

FROM a0us-docker.jfrog.io/docker/data/r-base
LABEL AUTHOR=auth0/data-engineering
LABEL REPO=auth0/rauth0

COPY . /rauth0

RUN R cmd -e "install.packages('rjson')"
RUN R cmd -e "install.packages('uuid')"
RUN R cmd -e "install.packages('fs')"
RUN R cmd -e "install.packages('testthat')"

# Install non-CRAN dependencies
RUN R cmd -e "devtools::install_github('cloudyr/aws.s3')"
RUN R cmd -e "devtools::install_github('cloudyr/aws.ec2metadata')"
RUN R cmd -e "devtools::install_github('scottypate/redshiftTools')"
RUN R cmd -e "devtools::install('/rauth0', dependencies = TRUE)"

