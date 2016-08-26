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

# Placing a tag on the first line of each page
firstline <- mclapply(texts, function(x) x[1], mc.cores = ncores)
firstline <- mclapply(firstline, function(x) paste0("[[firstline_tag]]", x))
for(i in 1:length(texts)){
  texts[[i]][1] <- firstline [[i]][1]
}

# Removing empty lines
# texts <- mclapply(texts, function(x) x[-1])
# texts <- mclapply(texts, function(x) x[which(x != "")], mc.cores = ncores)

# Trimming whitespace in start and end of each line
# texts <- mclapply(texts, function(x) stringr::str_trim(x, "both"), mc.cores = ncores)

# Removes "post 1." -- can't recall why I did this
# texts <- mclapply(texts, function(x) gsub("post [0-9]{1,2}", "\\.", x), mc.cores = ncores)

# Placing a filler text in whenever the line ends with "-"
texts <- mclapply(texts, function(x) gsub("\\—", "-", x), mc.cores = ncores)
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
# test[(which(test > 5500 ))]

#############################
#######Pre data frame########
#############################

# Collapsing the whole text into one block
texts_collapse <- do.call("paste", c(texts, collapse = " "))

# Temporary fixes
texts_collapse <- gsub("\\'", "", texts_collapse)
texts_collapse <- gsub("07\\)\\:", "(V):", texts_collapse)
texts_collapse <- gsub("\\(Krm\\:|\\(KrF\\s\\)", "(KrF):", texts_collapse)
texts_collapse <- gsub("\\(TD:|\\(T F\\)","(TF):", texts_collapse)
texts_collapse <- gsub("Odd Einar Dørum: Vi står faktisk", "Odd Einar Dørum (V): Vi står faktisk", texts_collapse)
texts_collapse <- gsub("GI\\):", "(H):", texts_collapse)
texts_collapse <- gsub("\\(SW:", "(SV):", texts_collapse)
texts_collapse <- gsub("W\\):|\\(W:", "(V):", texts_collapse)
texts_collapse <- gsub("Hans J. Røsj orde \\(Frp\\):", "Hans J. Røsjorde (Frp):", texts_collapse)
texts_collapse <- gsub("O\\(rF\\):", "(KrF):", texts_collapse)
texts_collapse <- gsub("Karin AndersentSV\\):", "Karin Andersent (SV):", texts_collapse)
texts_collapse <- gsub("Karin Kj ølmoen", "Karin Kjølmoen", texts_collapse)
texts_collapse <- gsub("Tore N ordtun", "Tore Nordtun", texts_collapse)
texts_collapse <- gsub("Ocomiteens", "(komiteens", texts_collapse)
texts_collapse <- gsub("F røiland", "Frøiland", texts_collapse)
texts_collapse <- gsub("Nesv ik", "Nesvik", texts_collapse)
texts_collapse <- gsub("Ev je", "Evje", texts_collapse)
texts_collapse <- gsub("Brø rby", "Brørby", texts_collapse)
texts_collapse <- gsub("Stråtv eit", "Stråtveit", texts_collapse)
texts_collapse <- gsub("Folk» ord", "Folkvord",texts_collapse)
texts_collapse <- gsub("\\(ordfører for saken\\)\\.", "(ordfører for saken):",texts_collapse)
texts_collapse <- gsub("Schj ett", "Schjøtt",texts_collapse)
texts_collapse <- gsub("J agland", "Jagland",texts_collapse)


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
test <- data.frame(raw_name = name, 
                   speech, stringsAsFactors = FALSE)


# Extracting party name from raw name
test$party <- as.character(stringr::str_extract_all(test$raw_name, "\\(([A-Za-z|a-zæøå\\sa-zæøå]*)\\)\\:$", simplify = TRUE))
test$party <- gsub("\\(|\\)|\\:", "", test$party)
test$party <- ifelse(test$party == "NULL", NA, test$party)

# Assigning parliamentary role by name, party affiliation, and so on
test$role <- ifelse(grepl("Presidenten", test$raw_name)==TRUE, "Presidenten",
                    ifelse(grepl("\\(([A-Za-z]{,5})\\)", test$raw_name)==TRUE, "Representant",
                           ifelse(grepl("salen|leder|leiar|saken|saka", test$party)==TRUE, "Representant",
                                  ifelse(grepl(voteringPattern, test$raw_name)==TRUE, "Votering",
                                         ifelse(grepl("Statsråd\\s", test$raw_name)==TRUE, "Statsråd",
                                                ifelse(grepl("Utenriksminister", test$raw_name)==TRUE, "Utenriksminister",
                                                       ifelse(grepl("Statsminister", test$raw_name)==TRUE, "Statsminister", 
                                                              ifelse(grepl("Stortingspresident", test$raw_name)==TRUE, "Stortingspresident",
                                                                     ifelse(grepl("Session introduction", test$raw_name)==TRUE, "Intro",
                                                                            ifelse(grepl("Hans Majestet Kongens", test$raw_name)==TRUE, "King's speech", NA))))))))))

# Cleaning up the raw name
test$name <- ifelse(is.na(test$party)==FALSE, gsub("\\:|\\((.*?)\\)", "", test$raw_name), NA)
test$name <- ifelse(grepl("Statsråd", test$raw_name)==TRUE, gsub("Statsråd\\s|\\:", "", test$raw_name),
                    ifelse(grepl("Statsminister", test$raw_name)==TRUE, gsub("Statsminister\\s|\\:", "", test$raw_name),
                           ifelse(grepl("Stortingspresident", test$raw_name)==TRUE, gsub("Stortingspresident\\s|\\:", "", test$raw_name), test$name)))
test$name <- str_trim(test$name)

# Pasting all non-role splits with the previous split (this could be a bit crude)
test$speech2 <- NULL
for(i in (nrow(test)-1):1){
  test$speech[i] <- ifelse(is.na(test$role[i+1])==TRUE, paste0(test$speech[i], test$raw_name[i+1], test$speech[i+1]), test$speech[i])
}

# Removing lines that were pasted above
test <- test[which(is.na(test$role)==FALSE), ]


#############################
######Extracting dates#######
#############################
# Making string of month names and abbrevations for matching
month_names <- c("januar", "februar", "mars", "april", "mai", "juni", "juli", "august", "september", "oktober", "november", "desember",
                 "jan\\.", "feb\\.", "mars", "april", "mai", "juni", "juli", "august", "september", "okt\\.", "nov\\.", "des\\.")

# ****Temporary fix of problems******
test$speech <- gsub("\\[\\[firstline_tag\\]\\]1504", "", test$speech)

# Making one grep line for each day of each month in a year
date_grep <- list()
for(i in 1:31){
  for(j in month_names){
    date_grep[[j]][i] <- paste0("\\[\\[firstline_tag\\]\\](\\s*)([0-9]*\\s)*", i, "(\\.*\\s)", j)
  }
}

# Removing interfering names and unlisting the greps
names(date_grep) <- NULL
date_grep <- unlist(date_grep)

# Extracting only date grep matches and filling it in to the data frame
date <- mclapply(1:length(date_grep), function(x) ifelse(grepl(date_grep[x], test$speech)==TRUE, date_grep[x], NA), mc.cores = ncores)
test$date <- NA
for(i in 1:length(date)){
  for(j in 1:nrow(test)){
    if(is.na(date[[i]][j])==FALSE){
      test$date[j] <- date[[i]][j]
    } else{
      next
    }
  }
}

# Prettying up the date string
test$date <- gsub("^\\\\\\[\\\\\\[firstline_tag\\\\\\]\\\\\\]\\(\\\\s\\*\\)\\(\\[0\\-9\\]\\*\\\\s\\)\\*", "", test$date)
test$date <- gsub("\\((.*?)\\)|\\\\", "", test$date)

# Trailing dates on NA (also a bit crude)
test$date <- zoo::na.locf(test$date, na.rm = FALSE)
test$date <- zoo::na.locf(test$date, na.rm = FALSE, fromLast = TRUE)

# Fixing the format of the date
day <- gsub("[^0-9]", "", test$date)
month <- gsub("[0-9]", "", test$date)
test$date <- paste0(day, ".", month)
source("month_to_num.R")
test$date <- as.numeric(gsub("\\-", "", as.character(as.Date(test$date2, "%d.%m.%Y"))))
test$date2 <- NULL

# Here I correct dates if they are lower than the previous date (some are misread)
for(i in 2:nrow(test)){
  test$date[i] <- ifelse(test$date[i] < test$date[i-1], test$date[i-1], test$date[i])
}

# Fixing the date format
test$date <- as.Date(as.character(test$date), "%Y%m%d")

# Correcting numbering of rownames
rownames(test) <- 1:nrow(test)

#############################
##Removing first line noise##
#############################
# This is too slow ****fix it******
# test$speech2 <- mclapply(1:length(firstline), function(x) gsub(firstline[x], "", test$speech), mc.cores = ncores)

######################################################
write.csv(test, file = "/media/martin/Data/taler_ocr_00_01.csv", row.names = FALSE)
######################################################


