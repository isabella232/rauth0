# R for Auth0 (rauth0)

This package defines functions to connect to Auth0's DWH, and some common manipulations of data for internal usage in Auth0.

How to Install
--------------

This package relies on a number of dependencies that are not available on CRAN. This means that you will need to install 2 dependencies manually.

1. [aws.s3](https://github.com/cloudyr/aws.s3)
2. [redshiftTools](https://github.com/sicarul/redshiftTools)

If the `devtools` library is installed, you can install directly from GitHub. Open R or RStudio and run:

``` r
devtools::install_github("cloudyr/aws.s3")
devtools::install_github("sicarul/redshiftTools")
devtools::install_github("auth0/rauth0")
```

**note:** you may need to generate a personal access token and supply that as a parameter to the install function. Consult the help file for `install_github` for details.

Alternatively, you can clone these repos and then use the following command in the R console using the [remotes](https://cran.r-project.org/web/packages/remotes/remotes.pdf) package:

``` r
remotes::install_local("path to aws.s3 directory", dependencies = TRUE)
remotes::install_local("path to redshiftTools directory", dependencies = TRUE)
remotes::install_local("path to rauth0 directory", dependencies = TRUE)
```

## Functions

This package exports the following functions:

* dwh_connect
* dwh_create_view
* dwh_disconnect
* dwh_drop_view
* dwh_metadata_yaml_process
* dwh_query
* dwh_replace_inplace_from_sql
* dwh_replace_table_from_sql
* dwh_replace_table_from_temp_table
* dwh_set_execution_slots
* dwh_statement
* dwh_table_replace
* dwh_table_schema
* dwh_table_upsert
* get_metadata_value
* set_metadata_value
* clean_metadata_value

## Constants

This package exports the following constants:

* CONST_LOGIN_TYPES
* CONST_LOGIN_TYPES_STR
