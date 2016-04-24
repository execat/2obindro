#
# This file prepares analysis for the datasets
#

library(RPostgreSQL)
library(RTextTools)

# Include common utilities
source('./util.R')

setwd("~/_code/me/2obindro/stats")
table_1 <- "tagoreweb"
table_2 <- "geetabitan"

fetch_data <- function(con, table_name, column_names) {
  # Connect to the table
  con <- connect(table_name)
  
  # Get data frame
  df_full <- select(con, table_name, column_names)
  
  # Cleanup
  # Factorize the class
  df_full$parjaay <- factor(df_full$parjaay)
}

# For `tagoreweb`
column_names_tagoreweb <- c("name", "lyrics", "raag", "parjaay",
                  "taal", "written_on_bengali",
                  "written_on_gregorian", "music", "place")
data_1 <- fetch_data(con, table_1, column_names_tagoreweb)

# For `geetabitan`
column_names_geetabitan <- c("link", "bengali_name", "parjaay", "lyrics")
# Get data frame
data_2 <- fetch_data(con, table_2, column_names_geetabitan)