# Initial setup of packages and cores
# source("structure_text.R")
gc();cat("\014")
library(gsubfn);library(parallel);library(ggplot2);library(dplyr);library(stringr)

theme_set(theme_bw())

ncores <- detectCores()-2

ocr <- read.csv("/media/martin/Data/taler_ocr_00_01.csv", stringsAsFactors = FALSE)
ocr <- ocr[which(ocr$role == "Representant"), ]
ocr <- ocr[-which(grepl("Stortingspresident", ocr$raw_name)), ]
ocr$speech <- str_trim(ocr$speech)
rownames(ocr) <- 1:nrow(ocr)


digital <- read.csv("/media/martin/Data/Dropbox/PhD/Storting/gitDebates/taler/id_taler_meta.csv", stringsAsFactors = FALSE)
digital <- digital[which(digital$session == "2000-2001" & digital$title == "Representant"), ]

digital$transcript2 <- gsub("^s|\\.sgm", "", digital$transcript)
digital$transcript2 <- ifelse(grepl("k$", digital$transcript2), gsub("k", "b", digital$transcript2), paste0(digital$transcript2, "a"))
digital <- digital[-which((digital$rep_name == "Bjørn Tore Godal" | digital$rep_name == "Karl Eirik Schjøtt-Pedersen") 
                         & digital$title == "Representant"),]

digital <- digital[-which(grepl("^frafalt ordet\\.$", digital$text)), ]

digital <- arrange(digital, transcript2, order)

ocr$digital <- digital$text[1:nrow(ocr)]
ocr$digitalname <- digital$rep_name[1:nrow(ocr)]
ocr$digitalparty <- digital$party_id[1:nrow(ocr)]
ocr$digitaldate <- digital$date[1:nrow(ocr)]

ocr_check <- ocr[, c("digitalname", "digitalparty", "date", "digitaldate", "speech", "digital")]

# Was used to control alignment between the sourcec
# fail <- TRUE
# for(i in 1:nrow(ocr_check)){
#   fail[i] <- agrepl(ocr_check$name[i], ocr_check$digitalname[i], max.distance = 3)
# }
# ocr_check$fail <- fail


ocr_text <- ocr_check[, c("speech", "digitalname")]
colnames(ocr_text) <- c("text", "name")
digital_text <- ocr_check[, c("digital", "digitalname")]
colnames(digital_text) <- c("text", "name")

write.csv(ocr_text, "./ocr_check_files/ocr_text.csv", row.names = FALSE)
write.csv(digital_text, "./ocr_check_files/digital_text.csv", row.names = FALSE)

### To check similarity (levenstein distance) run in shell:
# python ../python/ocr_eval.py --gold ./ocr_check_files/digital_text.csv --ocr ./ocr_check_files/ocr_text.csv
system("python ../python/ocr_eval.py --gold ./ocr_check_files/digital_text.csv --ocr ./ocr_check_files/ocr_text.csv")

ocr_check$ld_scores <- t(read.csv("ld_scores.csv", header = FALSE, stringsAsFactors = FALSE))[, 1]
ocr_check$ld_scores <- as.numeric(as.character(ocr_check$ld_scores))
write.csv(ocr_check, "ocr_vs_digital.csv", row.names = FALSE)

# 
# 
# 
# hm1 <- unlist(strsplit(ocr_check$digital[6993], "\\s+"))
# hm1 <- hm1[-which(grepl("^–$", hm1))]
# hm2 <- unlist(strsplit(ocr_check$speech[6993], "\\s+"))
# hm2 <- hm2[-which(grepl("^[[:punct:]]+$", hm2))]
# hm <- cbind(c(hm1, rep(NA, (length(hm2)-length(hm1)))), hm2)
