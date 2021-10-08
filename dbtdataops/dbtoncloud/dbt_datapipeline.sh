#!/bin/bash

echo "Here are showing the information of values parsed from the secrets manager"
echo "SNOWSQL_ACCOUNT : ${SNOWSQL_ACCOUNT}"
echo "SNOWSQL_USER : ${SNOWSQL_USER}"
echo "DBT_PASSWORD : ${DBT_PASSWORD}"
echo "SNOWSQL_ROLE : ${SNOWSQL_ROLE}"
echo "SNOWSQL_DATABASE : ${SNOWSQL_DATABASE}"
echo "SNOWSQL_WAREHOUSE : ${SNOWSQL_WAREHOUSE}"

###
# DBT script which ideally would invoke run/snapshot or other commands.
# For this example, we are just executing the dbt lists command to 
# display the identified model
##

dbt list