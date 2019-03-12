library(buffer)

# create redshift table for events
create_table <- function(connection) {
  
  print("Creating Redshift table")
  
  # connect to redshift
  con <- redshift_connect()
  
  # define create statement
  table_recipe <- "
    create table manual_mrr_amounts(
      customer_id varchar(256) encode lzo,
      buffer_user_id varchar(256) encode lzo,
      reply_org_id varchar(256) encode lzo,
      invoice_id varchar(256) encode lzo,
      plan_id varchar(256) encode lzo,
      billing_interval varchar(256) encode lzo,
      invoice_amount decimal(16,2) encode lzo,
      discount_type varchar(256) encode lzo,
      discount_amount decimal(16,2) encode lzo,
      total_amount_paid decimal(16,2) encode lzo,
      invoice_start_date timestamp encode lzo,
      invoice_end_date timestamp encode lzo,
      renewal_date timestamp encode lzo,
      status varchar(256) encode lzo,
      calculated_at timestamp encode lzo,
      id varchar(256) encode lzo,
      primary key(id)
    )
  "
  
  # run query
  query_db(table_recipe, con)
}

create_table()
