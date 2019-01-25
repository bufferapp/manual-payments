# load libraries
library(dplyr)
library(googlesheets)
library(buffer)
library(redshiftTools)

# function to convert dates
convert_dates <- function(dates) {

  # convert to date type objects
  as.Date(dates, format = '%d-%b-%Y')

}

# function to read data from Google Sheets
read_gs_data <- function() {

  # token <- gs_auth(cache = TRUE)
  # saveRDS(token, file = "./google/googlesheets_token.rds")

  # load oauth token
  gs_auth(token = "./google/googlesheets_token.rds")

  # read spreadsheet
  manual <- gs_title("Accounts Receivable - Checks, Invoices, Quotes")

  # read first sheet
  manual_payments <- manual %>%
    gs_read(ws = "Buffer Invoices")

  manual_payments
}

# function to clean data
clean_gs_data <- function(df) {
  

  # rename columns
  colnames(df) <- c('customer_name', 'user_id', 'reply_org_id', 'renewal_comm_email','invoice_id',
                    'reference_number', 'plan_id', 'interval', 'dollar_amount', 'discount_type', 
                    'discount_amount', 'total_paid','start_at', 'end_at', 'renewal_at', 'renewal_comm_at', 
                    'status', 'advocate', 'payment_received_at', 'amount_after_fees', 'follow_up', 
                    'buffer_user_id', 'payment_notes', 'customer_notes', 'po_number')


  # convert dates
  df <- df %>%
    mutate(start_at = convert_dates(start_at),
           end_at = convert_dates(end_at),
           renewal_at = convert_dates(renewal_at),
           renewal_comm_at = convert_dates(renewal_comm_at),
           payment_received_at = convert_dates(payment_received_at))

  # convert the amount to numeric
  df$dollar_amount <- as.numeric(gsub('[$,]', '', df$dollar_amount))
  df$discount_amount <- as.numeric(gsub('[$,]', '', df$discount_amount))
  df$total_paid <- as.numeric(gsub('[$,]', '', df$total_paid))

  # select only relevant columns and rows
  df <- df %>%
    filter(!is.na(customer_name)) %>% 
    select(customer_name:status, buffer_user_id) %>%
    select(-renewal_comm_email) %>% 
    mutate(dollar_amount = dollar_amount + discount_amount) %>% 
    select(-discount_type, -discount_amount, -total_paid) %>% 
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

# the function that does it all
main <- function() {

  # get data
  df <- get_manual_payments()

  # write data
  buffer::write_to_redshift(df, "manual_payment_invoices", "manual-payments", option = "replace")

}

main()
