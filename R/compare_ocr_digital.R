# Initial setup of packages and cores
source("structure_text.R")
gc();cat("\014")
library(gsubfn);library(parallel);library(ggplot2);library(dplyr)
theme_set(theme_bw())

ncores <- detectCores()-2

ocr <- read.csv("/media/martin/Data/taler_ocr_00_01.csv", stringsAsFactors = FALSE)
ocr <- ocr[which(ocr$role == "Representant"), ]
ocr <- ocr[-which(grepl("Stortingspresident", ocr$raw_name)), ]

rownames(ocr) <- 1:nrow(ocr)


digital <- read.csv("/media/martin/Data/Dropbox/PhD/Storting/gitDebates/taler/id_taler_meta.csv", stringsAsFactors = FALSE)
digital <- digital[which(digital$session == "2000-2001" & digital$title == "Representant"), ]

digital$transcript2 <- gsub("^s|\\.sgm", "", digital$transcript)
digital$transcript2 <- ifelse(grepl("k$", digital$transcript2), gsub("k", "b", digital$transcript2), paste0(digital$transcript2, "a"))
digital <- digital[-which((digital$rep_name == "Bjørn Tore Godal" | digital$rep_name == "Karl Eirik Schjøtt-Pedersen") 
                         & digital$title == "Representant"),]

digital <- digital[-which(grepl("^frafalt ordet\\.$", digital$text)), ]

digital <- arrange(digital, transcript2, order)

ocr$digital <- NA
ocr$digital <- digital$text[1:nrow(ocr)]
ocr$digitalname <- NA
ocr$digitalname <- digital$rep_name[1:nrow(ocr)]


ocr_check <- ocr[, c("raw_name", "name", "digitalname", "speech", "digital")]

# Was used to control alignment between the sourcec
# fail <- TRUE
# for(i in 1:nrow(ocr_check)){
#   fail[i] <- agrepl(ocr_check$name[i], ocr_check$digitalname[i], max.distance = 3)
# }
# ocr_check$fail <- fail
ocr_text <- ocr_check[, c("speech", "name")]
colnames(ocr_text) <- c("text", "name")
digital_text <- ocr_check[, c("digital", "digitalname")]
colnames(digital_text) <- c("text", "name")

write.csv(ocr_text, "./ocr_check_files/ocr_text.csv", row.names = FALSE)
write.csv(digital_text, "./ocr_check_files/digital_text.csv", row.names = FALSE)

system("python ../python/ocr_eval.py --gold ./ocr_check_files/digital_text.csv --ocr ./ocr_check_files/ocr_text.csv")


