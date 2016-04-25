#
# This file runs the classifier(s) on data containing 2 parjaays: namely 
# "প্রেম" and "পূজা" over the entire dataset from the tagoreweb dataset.
#

library(RPostgreSQL)
library(RTextTools)

# Include common utilities
source('./util.R')

setwd("~/_code/me/2obindro/stats")
table_name <- "tagoreweb"

# Get connection
con <- connect(table_name)
# Allowed column names
column_names <- c("name", "lyrics", "raag", "parjaay",
                  "taal", "written_on_bengali",
                  "written_on_gregorian", "music", "place")
# Get data frame
df_full <- select(con, table_name, column_names)

# Cleanup
# Factorize the class
df_full$parjaay <- factor(df_full$parjaay)
df <- df_full

# List of algorithms to apply
algos <- c("MAXENT","SVM","GLMNET","TREE", "BOOSTING", "BAGGING", "SLDA")
# Return analytics after running the algos on th data frame
analytics <- process(df, algos)
# Output all the results to screen and files
output(analytics, table_name, "p2")

# Disconnect safely
RPostgreSQL::dbDisconnect(con)