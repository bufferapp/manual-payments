# load libraries
library(dplyr)
library(googlesheets)
library(RPostgres)
library(DBI)
library(aws.s3)
library(redshiftTools)

# function to convert dates
convert_dates <- function(dates) {

  # convert to date type objects
  as.Date(dates, format = '%d-%b-%Y')

}

# function to read data from Google Sheets
read_gs_data <- function() {
  
  # token <- gs_auth(cache = FALSE)
  # saveRDS(token, file = "googlesheets_token.rds")

  # load oauth token
  gs_auth(token = "googlesheets_token.rds")

  # read spreadsheet
  manual <- gs_title("Accounts Receivable - Checks, Invoices, Quotes")

  # read first sheet
  manual_payments <- manual %>%
    gs_read(ws = 1)

  manual_payments
}

# function to clean data
clean_gs_data <- function(df) {

  # rename columns
  colnames(df) <- c('customer_name', 'user_id', 'reply_org_id','invoice_number', 'reference_number',
                                 'plan_id', 'interval', 'dollar_amount', 'start_at', 'end_at', 'renewal_at',
                                 'renewal_comm_at', 'status', 'advocate', 'payment_received_at',
                                 'follow_up', 'buffer_user_id', 'payment_notes', 'customer_notes',
                                 'po_number')


  # convert dates
  df <- df %>%
    mutate(start_at = convert_dates(start_at),
           end_at = convert_dates(end_at),
           renewal_at = convert_dates(renewal_at),
           renewal_comm_at = convert_dates(renewal_comm_at),
           payment_received_at = convert_dates(payment_received_at))

  # convert the amount to numeric
  df$dollar_amount <- as.numeric(gsub('[$,]', '', df$dollar_amount))

  # select only relevant columns
  df <- df %>%
    select(customer_name:status, buffer_user_id) %>%
    mutate(plan_id = gsub(",", "", plan_id))

  df

}

# function to gather data from Google Sheets
get_manual_payments <- function() {

  # read data from Google Sheets
  df <- read_gs_data()

  # clean data
  df <- clean_gs_data(df)

  # return cleaned data
  df
}

# function to write data to Redshift
write_to_rs <- function(df) {

  # connect to redshift
  con <- dbConnect(RPostgres::Postgres(),
                   host = Sys.getenv("REDSHIFT_ENDPOINT"),
                   port = Sys.getenv("REDSHIFT_DB_PORT"),
                   dbname = Sys.getenv("REDSHIFT_DB_NAME"),
                   user = Sys.getenv("REDSHIFT_USER"),
                   password = Sys.getenv("REDSHIFT_PASSWORD"))

  # upload data to manual-payments bucket and replace redshift table
  r <- rs_replace_table(df,
                        dbcon = con,
                        table_name = 'manual_payment_invoices',
                        bucket = "manual-payments",
                        region = "us-east-2",
                        split_files = 1)

}

# the function that does it all
main <- function() {

  # get data
  df <- get_manual_payments()

  # write data
  write_to_rs(df)

}

main()
