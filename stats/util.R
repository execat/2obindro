connect <- function(table) {
  drv <- dbDriver("PostgreSQL")
  con <- dbConnect(drv, dbname = "robindro", user = "robindro")
  
  # Early return if table does not exist
  if (!(dbExistsTable(con, table))) {
    stop("Table does not exist")
  }
  con
}

select <- function(con, table_name, column_names=c()) {
  columns <- paste(column_names, collapse=", ")
  if(columns == "") {
    columns = "*"
  }
  dbGetQuery(con, paste("SELECT", columns, "FROM", table_name))
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
  print("Generating output files")
  # Getting file name structure ready
  timestamp <- as.numeric(Sys.time())  
  file_prefix <- paste(table, "p1", timestamp, sep=".")
  
  # Write general analysis
  write.csv(summary(analytics), paste(folder_name, "/", file_prefix, ".csv", sep=""))
  
  # Write specific analysis
  write.csv(analytics@document_summary, paste(folder_name, "/", file_prefix, ".document.csv", sep=""))
  write.csv(analytics@algorithm_summary, paste(folder_name, "/", file_prefix, ".algorithm.csv", sep=""))
  write.csv(analytics@ensemble_summary,  paste(folder_name, "/", file_prefix, ".ensemble.csv", sep=""))
  write.csv(analytics@label_summary, paste(folder_name, "/", file_prefix, ".label.csv", sep=""))
}