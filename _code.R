require('RPostgreSQL')
require('e1071')

# Libraries needed by caret
library(klaR)
library(MASS)
# Caret for the Naive Bayes modelling
library(caret)
# Text mining
library(tm)
# Beautiful tables
library(pander)
# To simplify selections
library(dplyr)
library(doMC)
registerDoMC(cores=4)


setwd('~/_code/me/2obindro')
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
# column_names <- c("bengali_name", "lyrics", "parjaay", "taal", "raag",
#                  "written_on", "notes", "place", "collection", "book")
column_names <- c("name", "lyrics", "raag", "parjaay",
                "taal", "written_on_bengali",
                "written_on_gregorian", "music", "place")
columns <- paste(column_names, collapse=", ")
df <- dbGetQuery(con, paste("SELECT ", columns,  " FROM ", table))

# Reduce to a 2 parjaa problem
# df <- subset(df, parjaay %in% c("প্রেম", "পূজা"))

# Factorize the class
# TODO: Stemming
df$parjaay <- factor(df$parjaay)

# Plot frequencies of parjaas
# d <- factor(df$parjaay)
# barplot(table(d))

# Clean
stopwords <- read.csv("tagoreweb.in/stopwords.txt", header = FALSE)
stopwords <- apply(stopwords, 2, function(arg) { gsub('\\s+', '', arg) })
# TODO remove stopwards from lyrics_clean below

# Clean lyrics and generate lyrics_dtm
lyrics_clean <- Corpus(VectorSource(df$lyrics)) %>%
  tm_map(stripWhitespace) %>%
  tm_map(removePunctuation)
  # tm_map(removeWords, stopwords)
lyrics_dtm <- DocumentTermMatrix(lyrics_clean)

# Split by parjaay
split <- 0.8
trainIndex <- createDataPartition(df$parjaay, p=split, list=FALSE)

# Pull out corressponding lyrics
data_raw_train <- df[ trainIndex,]
data_raw_test <- df[-trainIndex,]
lyrics_clean_train <- lyrics_clean[ trainIndex]
lyrics_clean_test <- lyrics_clean[-trainIndex]
lyrics_dtm_train <- lyrics_dtm[ trainIndex, ]
lyrics_dtm_test <- lyrics_dtm[-trainIndex, ]

# Create representative tests from original into 
frqtab <- function(x, caption) {
  round(100*prop.table(table(x)), 1)
}

ft_orig <- frqtab(df$parjaay)
ft_train <- frqtab(data_raw_train$parjaay)
ft_test <- frqtab(data_raw_test$parjaay)

ft_df <- as.data.frame(cbind(ft_orig, ft_train, ft_test))
colnames(ft_df) <- c("Original", "Training set", "Test set")
pander(ft_df, style="rmarkdown",
       caption=paste0("Comparison of parjaay frequencies among datasets"))

# Vary this low frequency from lowFreq = 2 to other values
lyrics_dict <- findFreqTerms(lyrics_dtm_train, lowfreq = 2)
lyrics_train <- DocumentTermMatrix(lyrics_clean_train, list(dictionary=lyrics_dict))
lyrics_test <- DocumentTermMatrix(lyrics_clean_test, list(dictionary=lyrics_dict))

convert_counts <- function(x) {
  x <- ifelse(x > 0, 1, 0)
  x <- factor(x, levels = c(0, 1), labels = c("Absent", "Present"))
}

lyrics_train <- lyrics_train %>% apply(MARGIN=2, FUN=convert_counts)
lyrics_test <- lyrics_test %>% apply(MARGIN=2, FUN=convert_counts)

#
# Training
#

# Using 10-fold CV on the two prediction models
ctrl <- trainControl(method="cv", 10)
nb_model1 <- train(lyrics_train, data_raw_train$parjaay, method="nb",
                    trControl=ctrl)
nb_model1

nb_model2 <- train(lyrics_train, data_raw_train$parjaay, method="nb", 
                    tuneGrid=data.frame(.fL=1, .usekernel=FALSE),
                    trControl=ctrl)
nb_model2

#
# Predictions
#

nb_predict1 <- predict(nb_model1, data_test)
cm1 <- confusionMatrix(nb_predict1, data_raw_test$parjaay)
print(cm1)

nb_predict2 <- predict(nb_model2, data_test)
cm2 <- confusionMatrix(nb_predict2, data_raw_test$parjaay)
print(cm2)

