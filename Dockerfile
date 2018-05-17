FROM rocker/tidyverse:3.5

RUN install2.r --error \
    -r 'http://cran.rstudio.com' \
    httr \
    aws.s3 \
    devtools \
    googlesheets \
    dplyr \
    && rm -rf /tmp/downloaded_packages/ /tmp/*.rds

RUN installGithub.r \
    RcppCore/Rcpp \
    r-dbi/DBI \
    r-dbi/RPostgres \
    sicarul/redshiftTools \
    && rm -rf /tmp/downloaded_packages/ /tmp/*.rds

# Install Github packages
RUN R -e "devtools::install_github(c('jwinternheimer/buffer', 'sicarul/redshiftTools'), dependencies = T)"


COPY manual_payments.R /scripts/
WORKDIR /scripts

CMD ["Rscript", "manual_payments.R"]
