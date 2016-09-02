# Initial setup of packages and cores
rm(list = ls());gc();cat("\014")
library(gsubfn);library(parallel);library(ggplot2);library(dplyr);library(stringr)
theme_set(theme_bw())

ncores <- detectCores()-2

# Listing files and removing the first pages of listing representatives
files <- list.files("../storting/s2001/", pattern = ".txt", full.names = TRUE, recursive = TRUE)

# Reading text files
texts <- mclapply(files, function(x) readLines(x, encoding = "utf8"), mc.cores = ncores)

# Giving each list element the name of the page
names(texts) <- sapply(strsplit(files, "\\/text\\/"), "[[", 2)

# Removing empty lines
# texts <- mclapply(texts, function(x) x[-1])
# texts <- mclapply(texts, function(x) x[which(x != "")], mc.cores = ncores)

# Trimming whitespace in start and end of each line
# texts <- mclapply(texts, function(x) stringr::str_trim(x, "both"), mc.cores = ncores)

# Removes "post 1." -- can't recall why I did this
# texts <- mclapply(texts, function(x) gsub("post [0-9]{1,2}", "\\.", x), mc.cores = ncores)

# Replacing long hyphens with short dashes
texts <- mclapply(texts, function(x) gsub("\\—|\\-", "-", x), mc.cores = ncores)

# Placing a tag on the first line of each page
firstline <- mclapply(texts, function(x) x[1], mc.cores = ncores)
firstline <- mclapply(firstline, function(x) paste0("XXXfirstlineTagXXX", x))
for(i in 1:length(texts)){
  texts[[i]][1] <- firstline [[i]][1]
}

# Placing a filler text in whenever the line ends with "-"
texts <- mclapply(texts, function(x) gsub("\\-$", "\\[filler\\]", x), mc.cores = ncores)

# Collapsing all lines on the page, and replace the filler with no space, so that the broken words are put together
texts <- mclapply(texts, function(x) gsub("\\[filler\\]\\s", "", paste(x, collapse = " ")), mc.cores = ncores)
# texts <- mclapply(texts, function(x) gsub("[0-9]+$", "", x), mc.cores = ncores)
# This has something to do with single letter words that are not "i" or "å"
# texts <- mclapply(texts, function(y) gsubfn::gsubfn("\\s[a-z]\\s|\\s[0-9]\\s", 
#                                                     function(x) ifelse(x == " i " | x == " å ", x, 
#                                                                        stringr::str_trim(x)), y), mc.cores = ncores)


# Finding amount of noise on each page
# noise <- mclapply(texts, function(x) strsplit(x, "\\p{L}", perl = TRUE), mc.cores = ncores)
# noise <- lapply(noise, function(x) sum(nchar(x)))
# noise <- unlist(noise)
# noise[(which(noise > 16940))]
# plot(density(noise))
# 
# chars <- mclapply(texts, function(x) strsplit(x, "\\P{L}", perl = TRUE), mc.cores = ncores)
# 
# noise <- mclapply(noise, function(x) nchar(paste0(x, collapse = "")))
# chars <- mclapply(chars, function(x) nchar(paste0(x, collapse = "")))
# 
# summary(unlist(noise))
# prep[(which(prep > 5500 ))]

#############################
#######Pre data frame########
#############################

# Collapsing the whole text into one block
texts_collapse <- do.call("paste", c(texts, collapse = " "))

# Temporary fixes
source("./tmp_fix.R")

# Sloppy typewriting (not OCR's fault =))
# texts_collapse <- gsub("Karl Eirik Schjøtt-Pedersen: Ja, det er", "Statsråd Karl Eirik Schjøtt-Pedersen: Ja, det er", texts_collapse)
# texts_collapse <- gsub("Bjørn Tore Godal\\: Nei, jeg ser", "Statsråd Bjørn Tore Godal: Nei, jeg ser", texts_collapse)

# Patterns for speaker and vote recognition
speakerPattern <- "(([A-ZÆØÅ][a-zæøå]+(\\s|\\-)|[A-ZÆØÅ]\\.\\s)*([A-ZÆØÅ][a-zæøå]+|[A-ZÆØÅ][a-zæøå]+((\\s)*\\(([^\\)]){1,60}\\))+):)"
voteringPattern <- "V\\s{0,1}[a-z0-9]\\s{0,1}[a-z]\\s{0,1}[a-z]\\s{0,1}[a-z]\\s{0,1}[a-z]\\s{0,1}[a-z]\\s{0,1}[a-z]\\s{0,1}:"
kingsspeechPattern <- "Hans Majestet Kongens tale til det [0-9]+\\. Storting ved dets åpning:"
allPatterns <- paste0("(", paste(speakerPattern, voteringPattern, kingsspeechPattern, sep = "|"), ")")

# Extrating speaker and votes
name <- unlist(stringr::str_extract_all(texts_collapse, allPatterns))

# Fixing the president string with approximation grep
name <- ifelse(agrepl("Presidenten:", name, max.distance = 3)==TRUE, "Presidenten:", name)

# Filling first row with "intro"
name <- c("Session introduction:", name)

# Replacing some party names that are misread by the OCR
name <- gsub("\\(Il\\)|\\(ll\\)|\\(11\\)|\\(I-I\\)|\\(1-1\\)|\\(II\\)|\\(I1\\)|\\(B\\)", "(H)", name)
name <- gsub("\\((Kr-F)\\)", "(KrF)", name)
name <- gsub("\\(F rp\\)", "(Frp)", name)

# Extrating the actual speech
speech <- unlist(strsplit(texts_collapse, allPatterns))

#############################
#####Making data frame#######
#############################
# Making data frame of the name and speech
prep <- data.frame(raw_name = name, 
                   speech, stringsAsFactors = FALSE)


# Extracting party name from raw name
prep$party <- as.character(stringr::str_extract_all(prep$raw_name, "\\(([A-Za-z|a-zæøå\\sa-zæøå]*)\\)\\:$", simplify = TRUE))
prep$party <- gsub("\\(|\\)|\\:", "", prep$party)
prep$party <- ifelse(prep$party == "NULL", NA, prep$party)

######## Assigning parliamentary role by name, party affiliation, and so on ####
prep$role <- ifelse(grepl("Presidenten", prep$raw_name)==TRUE, "Presidenten",
                    ifelse(grepl("\\(([A-Za-z]{,5})\\)", prep$raw_name)==TRUE, "Representant",
                           ifelse(grepl("salen|leder|leiar|saken|saka", prep$party)==TRUE, "Representant",
                                  ifelse(grepl(voteringPattern, prep$raw_name)==TRUE, "Votering",
                                         ifelse(grepl("Statsråd\\s", prep$raw_name)==TRUE, "Statsråd",
                                                ifelse(agrepl("Utenriksminister", prep$raw_name, max.distance = 3)==TRUE, "Utenriksminister",
                                                       ifelse(grepl("Statsminister", prep$raw_name)==TRUE, "Statsminister", 
                                                              ifelse(grepl("Stortingspresident", prep$raw_name)==TRUE, "Stortingspresident",
                                                                     ifelse(grepl("Session introduction", prep$raw_name)==TRUE, "Intro",
                                                                            ifelse(grepl("Hans Majestet Kongens", prep$raw_name)==TRUE, "King's speech", NA))))))))))
################### #####

# Cleaning up the raw name
prep$name <- ifelse(is.na(prep$party)==FALSE, gsub("\\:|\\((.*?)\\)", "", prep$raw_name), NA)
prep$name <- ifelse(grepl("Statsråd", prep$raw_name)==TRUE, gsub("Statsråd\\s|\\:", "", prep$raw_name),
                    ifelse(grepl("Statsminister", prep$raw_name)==TRUE, gsub("Statsminister\\s|\\:", "", prep$raw_name),
                           ifelse(grepl("Stortingspresident", prep$raw_name)==TRUE, gsub("Stortingspresident\\s|\\:", "", prep$raw_name), prep$name)))
prep$name <- str_trim(prep$name)

# Pasting all non-role splits with the previous split (this could be a bit crude)
prep$speech2 <- NULL
for(i in (nrow(prep)-1):1){
  prep$speech[i] <- ifelse(is.na(prep$role[i+1])==TRUE, paste0(prep$speech[i], prep$raw_name[i+1], prep$speech[i+1]), prep$speech[i])
}

# Removing lines that were pasted above
prep <- prep[which(is.na(prep$role)==FALSE), ]


#############################

#############################
######Extracting dates#######
#############################
# Making string of month names and abbrevations for matching
month_names <- c("januar", "februar", "mars", "april", "mai", "juni", "juli", "august", "september", "oktober", "november", "desember",
                 "jan\\.", "feb\\.", "mars", "april", "mai", "juni", "juli", "august", "september", "okt\\.", "nov\\.", "des\\.")

# ****Temporary fix of problems******
prep$speech <- gsub("XXXfirstlineTagXXX1504", "", prep$speech)

# Making one grep line for each day of each month in a year
date_grep <- list()
for(i in 1:31){
  for(j in month_names){
    date_grep[[j]][i] <- paste0("XXXfirstlineTagXXX(\\s*)([0-9]*\\s)*", i, "(\\.*\\s)", j)
  }
}

# Removing interfering names and unlisting the greps
names(date_grep) <- NULL
date_grep <- unlist(date_grep)

# Extracting only date grep matches and filling it in to the data frame
date <- mclapply(1:length(date_grep), function(x) ifelse(grepl(date_grep[x], prep$speech)==TRUE, date_grep[x], NA), mc.cores = ncores)
prep$date <- NA
for(i in 1:length(date)){
  for(j in 1:nrow(prep)){
    if(is.na(date[[i]][j])==FALSE){
      prep$date[j] <- date[[i]][j]
    } else{
      next
    }
  }
}

# Prettying up the date string
prep$date <- gsub("^XXXfirstlineTagXXX\\(\\\\s\\*\\)\\(\\[0\\-9\\]\\*\\\\s\\)\\*", "", prep$date)
prep$date <- gsub("\\((.*?)\\)|\\\\", "", prep$date)

# Trailing dates on NA (also a bit crude)
prep$date <- zoo::na.locf(prep$date, na.rm = FALSE)
prep$date <- zoo::na.locf(prep$date, na.rm = FALSE, fromLast = TRUE)

# Fixing the format of the date
day <- gsub("[^0-9]", "", prep$date)
month <- gsub("[0-9]", "", prep$date)
prep$date <- paste0(day, ".", month)
source("month_to_num.R")
prep$date <- as.numeric(gsub("\\-", "", as.character(as.Date(prep$date2, "%d.%m.%Y"))))
prep$date2 <- NULL

# Here I correct dates if they are lower than the previous date (some are misread)
for(i in 2:nrow(prep)){
  prep$date[i] <- ifelse(prep$date[i] < prep$date[i-1], prep$date[i-1], prep$date[i])
}

# Fixing the date format
prep$date <- as.Date(as.character(prep$date), "%Y%m%d")

# Correcting numbering of rownames
rownames(prep) <- 1:nrow(prep)

#############################
##Removing first line noise##
#############################
# This is too slow ****fix it******
# prep$speech2 <- mclapply(1:length(firstline), function(x) gsub(firstline[x], "", prep$speech), mc.cores = ncores)
# firstlineBackup <- firstline
firstline <- mclapply(firstline, function(x) gsub("\\.", "\\\\.", x), mc.cores = ncores)
firstline <- mclapply(firstline, function(x) gsub("\\-", "\\\\-", x), mc.cores = ncores)
firstline <- mclapply(firstline, function(x) gsub("\\—", "\\\\—", x), mc.cores = ncores)
firstline <- mclapply(firstline, function(x) gsub("\\:", "\\\\:", x), mc.cores = ncores)
firstline <- mclapply(firstline, function(x) gsub("\\,", "\\\\,", x), mc.cores = ncores)
firstline <- unlist(unique(firstline))

firstlineBackup <- firstline


library(tcltk)
pb <- tkProgressBar(title = "progress bar", min = 1,
                    max = length(firstline), width = 300)

for(i in 1:length(firstline)){
  prep$speech <- gsub(firstline[i], "", prep$speech)
  setTkProgressBar(pb, i, label=paste("Removing first line --", round(i/(length(firstline))*100, 0), "% done"))
}
close(pb)
# library(foreach);library(doMC)
# registerDoMC(cores=ncores)
# hm <- foreach(i = 1:5) %dopar% gsub(firstline[i], "", prep$speech)
# hm <- hm[[1]]
rm(allPatterns, date, date_grep, day, files, firstline, i, j, kingsspeechPattern, pb,
   month, month_names, name, speakerPattern, voteringPattern, speech, texts, texts_collapse)

######################################################
write.csv(prep, file = "/media/martin/Data/taler_ocr_00_01.csv", row.names = FALSE)
######################################################


