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


  # rename columns
  colnames(df) <- safe_names(colnames(df))
  
  # convert dates
  df <- df %>%
    mutate(invoice_start_date = convert_dates(service_start_date),
           invoice_end_date = convert_dates(service_end_date),
           renewal_date = convert_dates(renewal_date),
           payment_received_date = convert_dates(payment_received_date)) %>% 
    rename(customer_id = customer_name,
           buffer_user_id = bufferid,
           reply_org_id = reply_orgid,
           invoice_id = invoice_,
           plan_id = plan_type,
           billing_interval = frequency,
           total_amount_paid = total_paid) %>% 
    dplyr::select(customer_id,
                  buffer_user_id,
                  reply_org_id,
                  invoice_id,
                  plan_id,
                  billing_interval,
                  invoice_amount,
                  discount_type,
                  discount_amount,
                  total_amount_paid,
                  invoice_start_date,
                  invoice_end_date,
                  renewal_date,
                  status)

  
  # convert the amount to numeric
  df$invoice_amount <- as.numeric(gsub('[$,]', '', df$invoice_amount))
  df$discount_amount <- as.numeric(gsub('[$,]', '', df$discount_amount))
  df$total_amount_paid <- as.numeric(gsub('[$,]', '', df$total_amount_paid))

  # update plan_id
  df <- df %>%
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
  buffer::write_to_redshift(df, "manual_payments", "manual-payment-invoices", option = "replace")

}

main()
