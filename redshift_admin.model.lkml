# preliminaries #

# make sure this is a connection where the database user has access to pg_admin tables
connection: "redshift-production"

case_sensitive: no

include: "*dashboard"

include: "*view"

# views to explore—i.e., "base views" #

explore: data_loads {}

explore: db_space {
  label: "DB Space"
}

explore: etl_errors {
  label: "ETL Errors"
}

explore: table_skew {}

explore: view_definitions {
  from: pg_views
}

explore: redshift_table_schemas {}

explore: redshift_query_alerts {}

explore: top_queries {}
