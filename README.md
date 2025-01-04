# BigQueryStorage
SQL script that reads your schemas at Project level and inserts an eod 'snapshot' into a table suitable for reporting

Script is currently set for union-ing multiple projects together. 
Relpace the appropriate placeholders with your own project names and ensure you have the correct permissions in BigQuery to access the schemas at the required levels.
