require("RPostgreSQL")
library(RTextTools)

setwd("~/_code/me/2obindro/stats")
table <- "tagoreweb"

connect <- function(table) {
  drv <- dbDriver("PostgreSQL")
  con <- dbConnect(drv, dbname = "robindro", user = "robindro")

  # Early return if table does not exist
  if (!(dbExistsTable(con, table))) {
    stop("Table does not exist")
  }
  con
}

select <- function(con, column_names=c()) {
  columns <- paste(column_names, collapse=", ")
  if(columns == "") {
    columns = "*"
  }
  dbGetQuery(con, paste("SELECT", columns,  "FROM", table))
}

process <- function(df, algos, split = 0.8) {
  # Shuffle
  df <- df[sample(nrow(df)),]
  
  print("Creating document matrix")
  doc_matrix <- create_matrix(df$lyrics, language="english", removeNumbers=TRUE, removeSparseTerms=.998)
  
  print("Creating container")
  total_rows = nrow(df)
  split_num = round(total_rows * split)
  container <- create_container(doc_matrix, as.numeric(factor(df$parjaay)),
                                trainSize=1:split_num, testSize=(split_num + 1):total_rows, virgin=FALSE)

  print("Training models")
  models <- train_models(container, algorithms=algos)
  print("Generating results")
  results <- classify_models(container, models)
  print("Generating analytics")
  analytics <- create_analytics(container, results)
}

output <- function(analytics, table, folder_name = "results") {
  summary(analytics)
  timestamp <- as.numeric(Sys.time())  
  file_prefix <- paste(table, "p1", timestamp, sep=".")
  write.csv(analytics@document_summary, paste(folder_name, "/", file_prefix, ".document.csv", sep=""))
  write.csv(analytics@algorithm_summary, paste(folder_name, "/", file_prefix, ".algorithm.csv", sep=""))
  write.csv(analytics@ensemble_summary,  paste(folder_name, "/", file_prefix, ".ensemble.csv", sep=""))
  write.csv(analytics@label_summary, paste(folder_name, "/", file_prefix, ".label.csv", sep=""))
}

# Get connection
con <- connect(table)
# Allowed column names
column_names <- c("name", "lyrics", "raag", "parjaay",
                  "taal", "written_on_bengali",
                  "written_on_gregorian", "music", "place")
# Get data frame
df_full <- select(con, column_names)

# Cleanup
# Factorize the class
df_full$parjaay <- factor(df_full$parjaay)
# Reduce to a 2 parjaa problem
categories <- c("প্রেম", "পূজা")
df <- subset(df_full, parjaay %in% categories)

# List of algorithms to apply
algos <- c("MAXENT","SVM","GLMNET","TREE", "BOOSTING", "BAGGING", "SLDA")
# algos <- c("SVM")
analytics <- process(df, algos)
output(analytics, table)

# TODO: Stemming