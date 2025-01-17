-- chains together 5 projects, reads their schemas, inserts a snapshot into a destination table.

delete from `<schema_history_table_id>`
where cal_date < date_sub(current_date(), INTERVAL 365 DAY);


create or replace temp table mq as (
 
with part_clust as(
  select
    table_catalog,
    table_schema,
    table_name,
    max(case 
          when is_partitioning_column = 'YES' then column_name
          else null
        end) as partitioned_on,
    max(case
          when CLUSTERING_ORDINAL_POSITION is not null then 1
          else 0
        end) as is_clustered,

  from <project_name>.`region-EU`.INFORMATION_SCHEMA.COLUMNS

  where is_partitioning_column = 'YES'
  or (is_partitioning_column = 'NO' and CLUSTERING_ORDINAL_POSITION = 1)

  group by table_catalog, table_schema, table_name

  union all

  select
    table_catalog,
    table_schema,
    table_name,
    max(case 
          when is_partitioning_column = 'YES' then column_name
          else null
        end) as partitioned_on,
    max(case
          when CLUSTERING_ORDINAL_POSITION is not null then 1
          else 0
        end) as is_clustered,

  from <project_name>.`region-EU`.INFORMATION_SCHEMA.COLUMNS

  where is_partitioning_column = 'YES'
  or (is_partitioning_column = 'NO' and CLUSTERING_ORDINAL_POSITION = 1)

  group by table_catalog, table_schema, table_name

  union all

  select
    table_catalog,
    table_schema,
    table_name,
    max(case 
          when is_partitioning_column = 'YES' then column_name
          else null
        end) as partitioned_on,
    max(case
          when CLUSTERING_ORDINAL_POSITION is not null then 1
          else 0
        end) as is_clustered,

  from <project_name>.`region-EU`.INFORMATION_SCHEMA.COLUMNS

  where is_partitioning_column = 'YES'
  or (is_partitioning_column = 'NO' and CLUSTERING_ORDINAL_POSITION = 1)

  group by table_catalog, table_schema, table_name

    union all

  select
    table_catalog,
    table_schema,
    table_name,
    max(case 
          when is_partitioning_column = 'YES' then column_name
          else null
        end) as partitioned_on,
    max(case
          when CLUSTERING_ORDINAL_POSITION is not null then 1
          else 0
        end) as is_clustered,

  from <project_name>.`region-EU`.INFORMATION_SCHEMA.COLUMNS

  where is_partitioning_column = 'YES'
  or (is_partitioning_column = 'NO' and CLUSTERING_ORDINAL_POSITION = 1)

  group by table_catalog, table_schema, table_name

      union all

  select
    table_catalog,
    table_schema,
    table_name,
    max(case 
          when is_partitioning_column = 'YES' then column_name
          else null
        end) as partitioned_on,
    max(case
          when CLUSTERING_ORDINAL_POSITION is not null then 1
          else 0
        end) as is_clustered,

  from <project_name>.`region-EU`.INFORMATION_SCHEMA.COLUMNS

  where is_partitioning_column = 'YES'
  or (is_partitioning_column = 'NO' and CLUSTERING_ORDINAL_POSITION = 1)

  group by table_catalog, table_schema, table_name
),


historic_schema as (
select
  cal_date,
  project_name as project_name_previous_day,
  dataset_name as dataset_name_previous_day,
  table_name as table_name_previous_day,
  total_rows as total_rows_previous_day,

  (avg(total_rows) over (partition by table_name, dataset_name, project_name order by cal_date rows between 6 preceding and 0 following)) as mean_total_rows_last_7_days,

  total_logical_bytes as total_logical_bytes_previous_day,
  (avg(total_logical_bytes) over (partition by table_name, dataset_name, project_name order by cal_date rows between 6 preceding and 0 following)) as mean_total_logical_bytes_last_7_days,
  total_logical_gigabytes as total_logical_gigabytes_previous_day,
  (avg(total_logical_gigabytes) over (partition by table_name, dataset_name, project_name order by cal_date rows between 6 preceding and 0 following)) as mean_total_logical_gigabytes_last_7_days,
  total_logical_terabytes as total_logical_terabytes_previous_day, 
  (avg(total_logical_terabytes) over (partition by table_name, dataset_name, project_name order by cal_date rows between 6 preceding and 0 following)) as mean_total_logical_terabytes_last_7_days,

  total_physical_bytes as total_physical_bytes_previous_day,
  (avg(total_physical_bytes) over (partition by table_name, dataset_name, project_name order by cal_date rows between 6 preceding and 0 following)) as mean_total_physical_bytes_last_7_days,
  total_physical_gigabytes as total_physical_gigabytes_previous_day,
  (avg(total_physical_gigabytes) over (partition by table_name, dataset_name, project_name order by cal_date rows between 6 preceding and 0 following)) as mean_total_physical_gigabytes_last_7_days,
  total_physical_terabytes as total_physical_terabytes_previous_day,
  (avg(total_physical_terabytes) over (partition by table_name, dataset_name, project_name order by cal_date rows between 6 preceding and 0 following)) as mean_total_physical_terabytes_last_7_days,
  

from `<schema_history_table_id>`
order by cal_date desc
),


live_schema as (
select
  current_date as cal_date,
  concat(table_catalog, '.',table_schema,'.',t.table_name) as full_name,
  table_catalog as project_name,
  table_schema as dataset_name,
  t.table_name,
  case
    when table_schema = 'daily_table_back_up' then 1
    else 0
  end as is_daily_back_up_flag,
  creation_time,
  t.storage_last_modified_time,
  t.total_rows,
  t.total_partitions,
  deleted,
  case
    when t.total_partitions > 0 then 1
    else 0
  end as is_partitioned_flag, 
  total_logical_bytes,
  total_physical_bytes,
  (total_logical_bytes/(1024 * 1024 * 1024)) as total_logical_gigabytes,
  (total_physical_bytes/(1024 * 1024 * 1024)) as total_physical_gigabytes,
  (total_logical_bytes/(1024 * 1024 * 1024 * 1024)) as total_logical_terabytes,
  (total_physical_bytes/(1024 * 1024 * 1024 * 1024)) as total_physical_terabytes,
  table_type

from <project_name>.`region-EU`.INFORMATION_SCHEMA.TABLE_STORAGE as t
where not regexp_contains(table_schema, r'^_')
and deleted = false

union all

select
  current_date as cal_date,
  concat(table_catalog, '.',table_schema,'.',t.table_name) as full_name,
  table_catalog as project_name,
  table_schema as dataset_name,
  t.table_name,
  case
    when table_schema = 'daily_table_back_up' then 1
    else 0
  end as is_daily_back_up_flag,
  creation_time,
  t.storage_last_modified_time,
  t.total_rows,
  t.total_partitions,
  deleted,
  case
    when t.total_partitions > 0 then 1
    else 0
  end as is_partitioned_flag, 
  total_logical_bytes,
  total_physical_bytes,
  (total_logical_bytes/(1024 * 1024 * 1024)) as total_logical_gigabytes,
  (total_physical_bytes/(1024 * 1024 * 1024)) as total_physical_gigabytes,
  (total_logical_bytes/(1024 * 1024 * 1024 * 1024)) as total_logical_terabytes,
  (total_physical_bytes/(1024 * 1024 * 1024 * 1024)) as total_physical_terabytes,
  table_type

from <project_name>.`region-EU`.INFORMATION_SCHEMA.TABLE_STORAGE as t
where not regexp_contains(table_schema, r'^_')
and deleted = false

  union all

select
  current_date as cal_date,
  concat(table_catalog, '.',table_schema,'.',t.table_name) as full_name,
  table_catalog as project_name,
  table_schema as dataset_name,
  t.table_name,
  case
    when table_schema = 'daily_table_back_up' then 1
    else 0
  end as is_daily_back_up_flag,
  creation_time,
  t.storage_last_modified_time,
  t.total_rows,
  t.total_partitions,
  deleted,
  case
    when t.total_partitions > 0 then 1
    else 0
  end as is_partitioned_flag, 
  total_logical_bytes,
  total_physical_bytes,
  (total_logical_bytes/(1024 * 1024 * 1024)) as total_logical_gigabytes,
  (total_physical_bytes/(1024 * 1024 * 1024)) as total_physical_gigabytes,
  (total_logical_bytes/(1024 * 1024 * 1024 * 1024)) as total_logical_terabytes,
  (total_physical_bytes/(1024 * 1024 * 1024 * 1024)) as total_physical_terabytes,
  table_type

from <project_name>.`region-EU`.INFORMATION_SCHEMA.TABLE_STORAGE as t
where not regexp_contains(table_schema, r'^_')
and deleted = false

  union all

select
  current_date as cal_date,
  concat(table_catalog, '.',table_schema,'.',t.table_name) as full_name,
  table_catalog as project_name,
  table_schema as dataset_name,
  t.table_name,
  case
    when table_schema = 'daily_table_back_up' then 1
    else 0
  end as is_daily_back_up_flag,
  creation_time,
  t.storage_last_modified_time,
  t.total_rows,
  t.total_partitions,
  deleted,
  case
    when t.total_partitions > 0 then 1
    else 0
  end as is_partitioned_flag, 
  total_logical_bytes,
  total_physical_bytes,
  (total_logical_bytes/(1024 * 1024 * 1024)) as total_logical_gigabytes,
  (total_physical_bytes/(1024 * 1024 * 1024)) as total_physical_gigabytes,
  (total_logical_bytes/(1024 * 1024 * 1024 * 1024)) as total_logical_terabytes,
  (total_physical_bytes/(1024 * 1024 * 1024 * 1024)) as total_physical_terabytes,
  table_type

from <project_name>.`region-EU`.INFORMATION_SCHEMA.TABLE_STORAGE as t
where not regexp_contains(table_schema, r'^_')
and deleted = false

  union all

select
  current_date as cal_date,
  concat(table_catalog, '.',table_schema,'.',t.table_name) as full_name,
  table_catalog as project_name,
  table_schema as dataset_name,
  t.table_name,
  case
    when table_schema = 'daily_table_back_up' then 1
    else 0
  end as is_daily_back_up_flag,
  creation_time,
  t.storage_last_modified_time,
  t.total_rows,
  t.total_partitions,
  deleted,
  case
    when t.total_partitions > 0 then 1
    else 0
  end as is_partitioned_flag, 
  total_logical_bytes,
  total_physical_bytes,
  (total_logical_bytes/(1024 * 1024 * 1024)) as total_logical_gigabytes,
  (total_physical_bytes/(1024 * 1024 * 1024)) as total_physical_gigabytes,
  (total_logical_bytes/(1024 * 1024 * 1024 * 1024)) as total_logical_terabytes,
  (total_physical_bytes/(1024 * 1024 * 1024 * 1024)) as total_physical_terabytes,
  table_type

from <project_name>.`region-EU`.INFORMATION_SCHEMA.TABLE_STORAGE as t
where not regexp_contains(table_schema, r'^_')
and deleted = false
)


select
  ls.cal_date,
  extract(DAYOFWEEK from ls.cal_date) as day_of_week_number,
  format_date('%A', date(ls.cal_date)) as day_of_week,
  hs.cal_date as previous_day_cal_date,
  ls.full_name,
  ls.project_name,
  ls.dataset_name,
  ls.table_name,
  ls.creation_time,
  ls.storage_last_modified_time,
  ls.total_rows,
  hs.total_rows_previous_day,
  ls.total_rows - hs.total_rows_previous_day as total_row_previous_day_difference,
  hs.mean_total_rows_last_7_days,
  ieee_divide (ls.total_rows, hs.mean_total_rows_last_7_days) as total_rows_mean_variance,
  ls.is_partitioned_flag,
  pc.partitioned_on,
  ls.total_partitions,
  case 
    when pc.is_clustered is null then 0
    else is_clustered
  end as is_clustered_flag,
  ls.is_daily_back_up_flag,
  ls.total_logical_bytes, 
  hs.total_logical_bytes_previous_day,
  ls.total_logical_bytes - hs.total_logical_bytes_previous_day as total_logical_bytes_day_difference,
  hs.mean_total_logical_bytes_last_7_days,
  ieee_divide (ls.total_logical_bytes, hs.mean_total_logical_bytes_last_7_days) as total_logical_bytes_mean_variance,
  ls.total_logical_gigabytes,
  hs.total_logical_gigabytes_previous_day,
  ls.total_logical_gigabytes - hs.total_logical_gigabytes_previous_day as total_logical_gigabytes_day_difference,
  hs.mean_total_logical_gigabytes_last_7_days,
  ieee_divide (ls.total_logical_gigabytes, hs.mean_total_logical_gigabytes_last_7_days) as total_logical_gigabytes_mean_variance,
  ls.total_logical_terabytes,
  hs.total_logical_terabytes_previous_day,
  ls.total_logical_terabytes - hs.total_logical_terabytes_previous_day as total_logical_terabytes_day_difference,
  hs.mean_total_logical_terabytes_last_7_days,
  ieee_divide (ls.total_logical_terabytes, hs.mean_total_logical_terabytes_last_7_days) as total_logical_terabytes_mean_variance,
  ls.total_physical_bytes, 
  hs.total_physical_bytes_previous_day,
  ls.total_physical_bytes - hs.total_physical_bytes_previous_day as total_physical_bytes_day_difference,
  hs.mean_total_physical_bytes_last_7_days,
  ieee_divide (ls.total_physical_bytes, hs.mean_total_physical_bytes_last_7_days) as total_physical_bytes_mean_variance,
  ls.total_physical_gigabytes,
  hs.total_physical_gigabytes_previous_day,
  ls.total_physical_gigabytes - hs.total_physical_gigabytes_previous_day as total_physical_gigabytes_day_difference,
  hs.mean_total_physical_gigabytes_last_7_days,
  ieee_divide (ls.total_physical_gigabytes, hs.mean_total_physical_gigabytes_last_7_days) as total_physical_gigabytes_mean_variance,
  ls.total_physical_terabytes,
  hs.total_physical_terabytes_previous_day,
  ls.total_physical_terabytes - hs.total_physical_terabytes_previous_day as total_physical_terabytes_day_difference,
  hs.mean_total_physical_terabytes_last_7_days,
  ieee_divide (ls.total_physical_terabytes, hs.mean_total_physical_terabytes_last_7_days) as total_physical_terabytes_mean_variance,
  ls.table_type,

from live_schema as ls
left join part_clust as pc on ls.table_name = pc.table_name and ls.dataset_name = pc.table_schema and ls.project_name = pc.table_catalog
left join historic_schema as hs on ls.cal_date = date_add(hs.cal_date, interval 1 day) and ls.table_name = hs.table_name_previous_day and ls.dataset_name = hs.dataset_name_previous_day and ls.project_name = hs.project_name_previous_day

order by project_name, dataset_name, table_name asc)
;

insert into `<schema_history_table_id>`

select
  cal_date,
  day_of_week_number,
  day_of_week,
  previous_day_cal_date,
  full_name,
  project_name,
  dataset_name,
  table_name,
  creation_time,
  storage_last_modified_time,
  total_rows,
  total_rows_previous_day,
  total_row_previous_day_difference,
  mean_total_rows_last_7_days,
  total_rows_mean_variance,
  is_partitioned_flag,
  partitioned_on,
  total_partitions,
  is_clustered_flag,
  is_daily_back_up_flag,
  total_logical_bytes,
  total_logical_bytes_previous_day,
  total_logical_bytes_day_difference,
  mean_total_logical_bytes_last_7_days,
  total_logical_bytes_mean_variance,
  total_logical_gigabytes,
  total_logical_gigabytes_previous_day,
  total_logical_gigabytes_day_difference,
  mean_total_logical_gigabytes_last_7_days,
  total_logical_gigabytes_mean_variance,
  total_logical_terabytes,
  total_logical_terabytes_previous_day,
  total_logical_terabytes_day_difference,
  mean_total_logical_terabytes_last_7_days,
  total_logical_terabytes_mean_variance,
  total_physical_bytes,
  total_physical_bytes_previous_day,
  total_physical_bytes_day_difference,
  mean_total_physical_bytes_last_7_days,
  total_physical_bytes_mean_variance,
  total_physical_gigabytes,
  total_physical_gigabytes_previous_day,
  total_physical_gigabytes_day_difference,
  mean_total_physical_gigabytes_last_7_days,
  total_physical_gigabytes_mean_variance,
  total_physical_terabytes,
  total_physical_terabytes_previous_day,
  total_physical_terabytes_day_difference,
  mean_total_physical_terabytes_last_7_days,
  total_physical_terabytes_mean_variance,
  table_type

from mq
;
end;