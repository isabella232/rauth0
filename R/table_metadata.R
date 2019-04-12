
#' Get table schema from DWH
#'
#' Obtains columns, primary keys, foreign key relationships not null and column order  from Amazon Redshift
#'
#' @param table_names Name of the tables to get schema
#' @param schema Name of the schema where the table is, defaults to public
#'
#' @examples
#'
#' schema = dwh_table_schema(c('tenants', 'users'))
#'
#' @export
dwh_table_schema = function(table_names, schema='public'){
  dwh_query(
sprintf("
select
  t.table_name as table,
  c.column_name as column,
  case when pk.column_name is null then 0 else 1 end as key,
  fk.ref,
  fk.ref_col,
  case c.is_nullable when 'YES' then 0 else 1 end as mandatory,
  c.data_type as type,
  c.ordinal_position as column_order

from
  information_schema.columns c
  inner join information_schema.tables t on
    t.table_name = c.table_name
    and t.table_catalog = c.table_catalog
    and t.table_schema = c.table_schema

  left join  -- primary keys
  ( SELECT
      tc.constraint_name, tc.table_name, kcu.column_name
      FROM
      information_schema.table_constraints AS tc
      JOIN information_schema.key_column_usage AS kcu ON
      tc.constraint_name = kcu.constraint_name
    WHERE constraint_type = 'PRIMARY KEY'
  ) pk on
    pk.table_name = c.table_name
    and pk.column_name = c.column_name

  left join  -- foreign keys
    ( SELECT
        tc.constraint_name, kcu.table_name, kcu.column_name,
        ccu.table_name as ref,
        ccu.column_name as ref_col
      FROM
        information_schema.table_constraints AS tc
        JOIN information_schema.key_column_usage AS kcu ON
        tc.constraint_name = kcu.constraint_name
        JOIN information_schema.constraint_column_usage AS ccu ON
        ccu.constraint_name = tc.constraint_name
      WHERE tc.constraint_type = 'FOREIGN KEY'
    ) fk on
      fk.table_name = c.table_name
      and fk.column_name = c.column_name

where
  c.table_schema = '%s'
  and t.table_type = 'BASE TABLE'
  and t.table_name in ('%s')
order by c.ordinal_position
            ", schema, paste0(table_names, collapse="','")))

}

#' Load metadata from YAML
#'
#' Use YAML file to load metadata into a data.frame
#'
#' @param yaml_file Path of the file to load into the data.frame to return
#'
#' @examples
#'
#' metadata = dwh_metadata_yaml_process('metadata.yaml')
#'
#' @importFrom tibble rownames_to_column
#' @importFrom yaml yaml.load_file
#' @export
dwh_metadata_yaml_process = function(yaml_file){

  metadata = yaml.load_file(yaml_file)
  all_columns = data.frame(Column=as.character(), Description=as.character(), Table=as.character())
  for(i in 1:length(metadata$tables)){
    table=metadata$tables[[i]]
    name=table$name
    columns=table$columns
    columns_df = data.frame(unlist(columns), stringsAsFactors = F)
    columns_df = rownames_to_column(columns_df)
    columns_df$Table = name
    names(columns_df) = c('Column', 'Description', 'Table')
    all_columns=rbind(all_columns, columns_df)
  }
  all_columns
}
