library(dplyr)
library(dplyr.snowflakedb)


snowflake_connect = function(credentials) {
    Sys.setenv(JAVA_HOME = credentials$javahome)
    options(dplyr.jdbc.classpath = credentials$snowflakejdbc)
    con = src_snowflakedb(
        user = credentials$user,
        password = credentials$password,
        account = credentials$account,
        opts = list(
            warehouse = credentials$warehouse,
            db = credentials$db,
            schema = credentials$schema
        )
    )

    con
}