# view definitions #

view: pg_views {
  sql_table_name: pg_views ;;
  # dimensions #

  dimension: definition {
    type: string
    sql: ${TABLE}.definition ;;
  }

  dimension: schema {
    type: string
    sql: ${TABLE}.schemaname ;;
  }

  dimension: view {
    type: string
    sql: ${TABLE}.viewname ;;
  }
}

view: table_skew {
  derived_table: {
    sql: select *
      from svv_table_info
       ;;
  }

  # dimensions #

  dimension: database {
    type: string
    sql: ${TABLE}.database ;;
  }

  dimension: schema {
    type: string
    sql: ${TABLE}.schema ;;
  }

  dimension: table_id {
    type: number
    sql: ${TABLE}.table_id ;;
  }

  dimension: table {
    type: string
    sql: ${TABLE}."table" ;;
  }

  dimension: encoded {
    type: yesno
    sql: case ${TABLE}.encoded
        when 'Y'
        then true
        when 'N'
        then false
        else null
      end
       ;;
  }

  dimension: distribution_style {
    type: string
    sql: ${TABLE}.diststyle ;;
  }

  dimension: sortkey {
    type: string
    sql: ${TABLE}.sortkey1 ;;
  }

  dimension: max_varchar {
    type: number
    sql: ${TABLE}.max_varchar ;;
  }

  dimension: sortkey_encoding {
    type: string
    sql: ${TABLE}.sortkey1_enc ;;
  }

  dimension: number_of_sortkeys {
    type: number
    sql: ${TABLE}.sortkey_num ;;
  }

  dimension: size {
    type: number
    sql: ${TABLE}.size ;;
  }

  dimension: pct_used {
    type: number
    sql: ${TABLE}.pct_used ;;
  }

  dimension: empty {
    type: number
    sql: ${TABLE}.empty ;;
  }

  dimension: unsorted {
    type: number
    sql: ${TABLE}.unsorted ;;
  }

  dimension: stats_off {
    type: number
    sql: ${TABLE}.stats_off ;;
  }

  dimension: rows_in_table {
    type: number
    sql: ${TABLE}.tbl_rows ;;
  }

  dimension: skew_sortkey {
    type: number
    sql: ${TABLE}.skew_sortkey1 ;;
  }

  dimension: skew_rows {
    type: number
    sql: ${TABLE}.skew_rows ;;
    html: {% if value < 25 %}
      <div style="color:Black; background-color:#22CE7E; font-size:100%; text-align:center">{{ rendered_value }}</div>
      {% elsif value >= 25 and value < 50 %}
      <div style="color:Black; background-color:#95F047; font-size:100%; text-align:center">{{ rendered_value }}</div>
      {% elsif value >= 50 %}
      <div style="color:Black; background-color:#C64646; font-size:100%; text-align:center">{{ rendered_value }}</div>
      {% endif %}
      ;;
  }
}

view: db_space {
  derived_table: {
    sql: select name as table
        , trim(pgn.nspname) as schema
        , sum(b.mbytes) as megabytes
        , sum(a.rows) as rows
      from (select db_id
              , id
              , name
              , sum(rows) as rows
            from stv_tbl_perm a
            group by 1,2,3) as a
      join pg_class as pgc
      on pgc.oid = a.id
      join pg_namespace as pgn
      on pgn.oid = pgc.relnamespace
      join pg_database as pgdb
      on pgdb.oid = a.db_id
      join (select tbl
              , count(*) as mbytes
            from stv_blocklist
            group by 1) as b
      on a.id = b.tbl
      group by 1,2
       ;;
  }

  # dimensions #

  dimension: table {
    type: string
    sql: ${TABLE}.table ;;
  }

  dimension: schema {
    type: string
    sql: ${TABLE}.schema ;;
  }

  dimension: megabytes {
    type: number
    sql: ${TABLE}.megabytes ;;
  }

  dimension: rows {
    type: number
    sql: ${TABLE}.rows ;;
  }

  dimension: table_stem {
    sql: case
        when (${table} ~ '(lr|lc)\\$[a-zA-Z0-9]+_.*')
        then ltrim(regexp_substr(${table}, '_.*'), '_') || ' - Looker PDT'
        else ${table}
      end
       ;;
  }

  # measures #

  measure: total_megabytes {
    type: sum
    sql: ${megabytes} ;;
  }

  measure: total_rows {
    type: sum
    sql: ${rows} ;;
  }

  measure: total_tables {
    type: count_distinct
    sql: ${table} ;;
  }
}

view: etl_errors {
  derived_table: {
    sql: select starttime as error_time
        , filename as file_name
        , colname as column_name
        , type as column_data_type
        , position as error_position
        , raw_field_value as error_field_value
        , err_reason as error_reason
        , raw_line
      from stl_load_errors
       ;;
  }

  # dimensions #

  dimension_group: error {
    type: time
    timeframes: [time, date]
    sql: ${TABLE}.error_time ;;
  }

  dimension: file_name {
    type: string
    sql: ${TABLE}.file_name ;;
  }

  dimension: column_name {
    type: string
    sql: ${TABLE}.column_name ;;
  }

  dimension: column_data_type {
    type: string
    sql: ${TABLE}.column_data_type ;;
  }

  dimension: error_position {
    type: string
    sql: ${TABLE}.error_position ;;
  }

  dimension: error_field_value {
    type: string
    sql: ${TABLE}.error_field_value ;;
  }

  dimension: error_reason {
    type: string
    sql: ${TABLE}.error_reason ;;
  }

  dimension: raw_line {
    type: string
    sql: ${TABLE}.raw_line ;;
  }
}

view: data_loads {
  derived_table: {
    sql: select replace(regexp_substr(filename, '//[a-zA-Z0-9\-]+/'), '/', '') as root_bucket
        , replace(filename, split_part(filename, '/', regexp_count(filename, '/') + 1), '') as s3_path
        , regexp_replace(replace(filename, split_part(filename, '/', regexp_count(filename, '/') + 1), ''), '([\\d]{5,}|[\\d\-]{5,}/)', '') as s3_path_clean
        , split_part(filename, '/', regexp_count(filename, '/') + 1) as file_name
        , regexp_replace(split_part(filename, '/', regexp_count(filename, '/') + 1), '([\\d]{7,}|[\\d\-]{7,})', '') as file_stem
        , curtime as load_time
      from stl_load_commits
       ;;
  }

  # dimensions #

  dimension: root_bucket {
    type: string
    sql: ${TABLE}.root_bucket ;;
  }

  dimension: s3_path {
    type: string
    sql: ${TABLE}.s3_path ;;
  }

  dimension: s3_path_clean {
    type: string
    sql: ${TABLE}.s3_path_clean ;;
  }

  dimension: file_name {
    type: string
    sql: ${TABLE}.file_name ;;
  }

  dimension: file_stem {
    type: string
    sql: ${TABLE}.file_stem ;;
  }

  dimension_group: load {
    type: time
    timeframes: [raw, time, date]
    sql: ${TABLE}.load_time ;;
  }

  # measures #

  measure: most_recent_load {
    type: string
    sql: max(${load_raw}) ;;
  }

  measure: hours_since_last_load {
    type: number
    value_format_name: id
    sql: datediff('hour', ${most_recent_load}, getdate()) ;;
    html: {% if value < 24 %}
      <div style="color:Black; background-color:#22CE7E; font-size:100%; text-align:center">{{ rendered_value }}</div>
      {% elsif value >= 24 and value < 48 %}
      <div style="color:Black; background-color:#95F047; font-size:100%; text-align:center">{{ rendered_value }}</div>
      {% elsif value >= 48 %}
      <div style="color:Black; background-color:#C64646; font-size:100%; text-align:center">{{ rendered_value }}</div>
      {% endif %}
      ;;
  }
}

view: redshift_query_alerts {
  derived_table: {
    sql: select
       trim(s.perm_table_name)  as table,
       (sum(abs(datediff(seconds,
                 coalesce(b.starttime, d.starttime, s.starttime),
                 case
                   when
                 coalesce(b.endtime, d.endtime, s.endtime) >
                 coalesce(b.starttime, d.starttime, s.starttime) then
                 coalesce(b.endtime, d.endtime, s.endtime)
                 else coalesce(b.starttime, d.starttime, s.starttime)
                 end))) / 60 ) :: numeric(24, 0) as minutes,
       sum(coalesce(b.rows, d.rows, s.rows))     as rows,
       trim(split_part(l.event, ':', 1))         as event,
       substring(trim(l.solution), 1, 60)        as solution,
       max(l.query)                              as sample_query,
       count(distinct l.query)
from   stl_alert_event_log as l
       left join stl_scan as s
              on s.query = l.query
                 and s.slice = l.slice
                 and s.segment = l.segment
       left join stl_dist as d
              on d.query = l.query
                 and d.slice = l.slice
                 and d.segment = l.segment
       left join stl_bcast as b
              on b.query = l.query
                 and b.slice = l.slice
                 and b.segment = l.segment
where  l.userid > 1
       and l.event_time >= dateadd(day, -7, current_date)
group  by 1,
          4,
          5
order  by 2 desc,
          6 desc
 ;;
  }

  dimension: table {
    type: string
    sql: ${TABLE}."table" ;;
  }

  dimension: minutes {
    type: number
    sql: ${TABLE}.minutes ;;
  }

  dimension: rows {
    type: number
    sql: ${TABLE}.rows ;;
  }

  dimension: event {
    type: string
    sql: ${TABLE}.event ;;
  }

  dimension: solution {
    type: string
    sql: ${TABLE}.solution ;;
  }

  dimension: sample_query {
    type: number
    sql: ${TABLE}.sample_query ;;
  }

  dimension: count {
    type: number
    sql: ${TABLE}.count ;;
  }

  set: detail {
    fields: [table, minutes, rows, event, solution, sample_query, count]
  }
}

view: top_queries {
  derived_table: {
    sql: select trim(database) as DB, count(query) as n_qry, max(qrytext) as qrytext, min(run_seconds) as "min" ,
          max(run_seconds) as "max", avg(run_seconds) as "avg", max(query) as max_query_id,
          max(starttime) as last_run, aborted, event
          from (
          select userid, label, stl_query.query, trim(database) as database, trim(querytxt) as qrytext, md5(trim(querytxt)) as qry_md5, starttime, endtime, datediff(seconds, starttime,endtime)::numeric(12,2) as run_seconds,
                 aborted, decode(alrt.event,'Very selective query filter','Filter','Scanned a large number of deleted rows','Deleted','Nested Loop Join in the query plan','Nested Loop','Distributed a large number of rows across the network','Distributed','Broadcasted a large number of rows across the network','Broadcast','Missing query planner statistics','Stats',alrt.event) as event
          from stl_query
          left outer join ( select query, trim(split_part(event,':',1)) as event from STL_ALERT_EVENT_LOG where event_time >=  dateadd(day, -5, current_Date)  group by query, trim(split_part(event,':',1)) ) as alrt on alrt.query = stl_query.query
          where userid <> 1
          and starttime >=  dateadd(day, -5, current_Date)
           )
          where qrytext ilike 'select%'
          group by database, label, qry_md5, aborted, event
      ;;
  }

  dimension: database {
    sql: ${TABLE}.DB ;;
  }

  dimension: query_count {
    type: number
    sql: ${TABLE}.n_qry ;;
  }

  dimension: query_text {
    sql: ${TABLE}.qrytext ;;
  }

  dimension: query_text_short {
    sql: LEFT(${query_text}, 80) ;;
  }

  dimension: min_seconds {
    type: number
    sql: ${TABLE}.min ;;
  }

  dimension: max_seconds {
    type: number
    sql: ${TABLE}.max ;;
  }

  dimension: avg_seconds {
    type: number
    sql: ${TABLE}.avg ;;
  }

  dimension: max_query_id {
    type: number
    sql: ${TABLE}.max_query_id ;;
  }

  dimension: last_run {
    type: date_time
    sql: ${TABLE}.last_run ;;
    convert_tz: yes
  }

  dimension: aborted {
    type: number
    sql: ${TABLE}.aborted ;;
  }

  dimension: event {
    sql: ${TABLE}.event ;;
  }
}

view: redshift_table_schemas {
  derived_table: {
    sql: select * from pg_table_def
      ;;
  }

  measure: count {
    type: count
    drill_fields: [detail*]
  }

  dimension: schemaname {
    sql: ${TABLE}.schemaname ;;
  }

  dimension: tablename {
    sql: ${TABLE}.tablename ;;
  }

  dimension: column {
    sql: ${TABLE}.column ;;
  }

  dimension: type {
    sql: ${TABLE}.type ;;
  }

  dimension: encoding {
    sql: ${TABLE}.encoding ;;
  }

  dimension: distkey {
    sql: ${TABLE}.distkey ;;
  }

  dimension: sortkey {
    type: number
    sql: ${TABLE}.sortkey ;;
  }

  dimension: notnull {
    sql: ${TABLE}.notnull ;;
  }

  dimension: notnull_text {
    sql: case WHEN ${TABLE}.notnull then 'not null' else 'null' end ;;
  }

  dimension: distkey_text {
    sql: case WHEN ${TABLE}.distkey then 'distkey(' || ${TABLE}.column || ')'  else NULL end ;;
  }

  dimension: sortkey_text {
    sql: case WHEN ${TABLE}.distkey then 'distkey(' || ${TABLE}.column || ')'  else NULL end ;;
  }

  dimension: type_text {
    sql: REPLACE(
        REPLACE(
            REPLACE(${TABLE}.type, 'character varying', 'varchar'),
              'timestamp without time zone', 'timestamp'
        ),
        'numeric', 'decimal'
      )
       ;;
  }

  set: detail {
    fields: [schemaname, tablename, column, type, encoding, distkey, sortkey, notnull]
  }
}
