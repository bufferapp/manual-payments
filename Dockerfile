FROM rocker/tidyverse

RUN install2.r --error \
    -r 'http://cran.rstudio.com' \
    httr \
    aws.s3 \
    devtools \
  && installGithub.r \
    RcppCore/Rcpp \
    r-dbi/DBI \
    r-dbi/RPostgres \
    sicarul/redshiftTools \
  && rm -rf /tmp/downloaded_packages/ /tmp/*.rds

ADD manual_payments.R manual_payments.R
CMD ["Rscript", "manual_payments.R"]
