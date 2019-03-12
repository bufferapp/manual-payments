# load packages
library(dplyr)
library(buffer)
library(digest)
library(googlesheets)
library(redshiftTools)


# function to convert strings to dates
convert_dates <- function(dates) {

  # convert to date type objects
  as.Date(dates, format = '%d-%b-%Y')

}


# function to read data from google sheets
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
  colnames(df) <- safe_names(colnames(df))
  
  # convert dates and rename columns
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

  
  # convert the dollar amount to numbers
  df$invoice_amount <- as.numeric(gsub('[$,]', '', df$invoice_amount))
  df$discount_amount <- as.numeric(gsub('[$,]', '', df$discount_amount))
  df$total_amount_paid <- as.numeric(gsub('[$,]', '', df$total_amount_paid))

  # update the plan id and set calculated_at time
  df <- df %>%
    mutate(plan_id = gsub(",", "", plan_id),
           calculated_at = Sys.time(),
           id = paste0(customer_id, invoice_id, plan_id, calculated_at))
  
  # hash the id
  df$id <- sapply(df$id, digest, algo = "md5")

  df

}

# function to gather and clean data from spreadsheet
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
  buffer::write_to_redshift(df = df, 
                            table_name = "manual_mrr_amounts", 
                            bucket_name = "manual-payment-invoices", 
                            option = "upsert",
                            keys = "id")

}

main()
