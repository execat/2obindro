require("RPostgreSQL")
library(RTextTools)

setwd("~/_code/me/2obindro")
drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname = "robindro", user = "robindro")
table <- "tagoreweb"

# Early return if table does not exist
if (!(dbExistsTable(con, table))) {
  print("Table does not exist")
  return;
}

# data <- dbGetQuery(con, paste("SELECT * FROM tagoreweb"))

# Columns since the JSON column is huge
column_names <- c("name", "lyrics", "raag", "parjaay",
                  "taal", "written_on_bengali",
                  "written_on_gregorian", "music", "place")
columns <- paste(column_names, collapse=", ")
df_full <- dbGetQuery(con, paste("SELECT ", columns,  " FROM ", table))

# Factorize the class
df_full$parjaay <- factor(df_full$parjaay)

# Reduce to a 2 parjaa problem
categories <- c("প্রেম", "পূজা")
df <- subset(df_full, parjaay %in% categories)

# Shuffle
df <- df[sample(nrow(df)),]

# TODO: Stemming

print("Creating document matrix")
doc_matrix <- create_matrix(df$lyrics, language="english", removeNumbers=TRUE, removeSparseTerms=.998)
print("Creating container")
split = 0.8
total_rows = nrow(df)
split_num = round(total_rows * split)
container <- create_container(doc_matrix, as.numeric(factor(df$parjaay)),
                              trainSize=1:split_num, testSize=(split_num + 1):total_rows, virgin=FALSE)

print("Training models")
algos = c("SVM")
models <- train_models(container, algorithms=algos)
print("Generating results")
results <- classify_models(container, models)
print("Generating analytics")
analytics <- create_analytics(container, results)

summary(analytics)

timestamp <- as.numeric(Sys.time())
folder_name <- "results"
file_prefix <- paste(table, "_p1", timestamp, sep="")
write.csv(analytics@document_summary, paste(folder_name, "/", file_prefix, ".document.csv", sep=""))
write.csv(analytics@algorithm_summary, paste(folder_name, "/", file_prefix, ".algorithm.csv", sep=""))
write.csv(analytics@ensemble_summary,  paste(folder_name, "/", file_prefix, ".ensemble.csv", sep=""))
write.csv(analytics@label_summary, paste(folder_name, "/", file_prefix, ".label.csv", sep=""))