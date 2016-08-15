rm(list = ls());gc();cat("\014")
library(gsubfn);library(parallel);library(ggplot2)
theme_set(theme_bw())

ncores <- detectCores()-2

# Listing files and removing the first pages of listing representatives
files <- list.files("../storting/s1945/s1945a/text/", pattern = ".txt", full.names = TRUE)
files <- files[9:length(files)]

# Reading text files
texts <- mclapply(files, function(x) readLines(x, encoding = "utf8"), mc.cores = ncores)

# Giving each list element the name of the page
names(texts) <- sapply(strsplit(files, "\\/\\/"), "[[", 2)



# Removing empty lines
texts <- mclapply(texts, function(x) x[-1])
texts <- mclapply(texts, function(x) x[which(x != "")], mc.cores = ncores)

# Trimming whitespace in start and end of each line
texts <- mclapply(texts, function(x) stringr::str_trim(x, "both"), mc.cores = ncores)

# Removes "post 1." -- can't recall why I did this
# texts <- mclapply(texts, function(x) gsub("post [0-9]{1,2}", "\\.", x), mc.cores = ncores)

# Placing a filler text in whenever the line ends with "-"
texts <- mclapply(texts, function(x) gsub("\\-$", "\\[filler\\]", x), mc.cores = ncores)
texts <- mclapply(texts, function(x) gsub("\\—$", "\\[filler\\]", x), mc.cores = ncores)

# Collapsing all lines on the page, and replace the filler with no space, so that the broken words are put together
texts <- mclapply(texts, function(x) gsub("\\[filler\\]\\s", "", paste(x, collapse = " ")), mc.cores = ncores)

texts <- mclapply(texts, function(x) gsub("[0-9]+$", "", x), mc.cores = ncores)
# This has something to do with single letter words that are not "i" or "å"
# texts <- mclapply(texts, function(y) gsubfn::gsubfn("\\s[a-z]\\s|\\s[0-9]\\s", 
#                                                     function(x) ifelse(x == " i " | x == " å ", x, 
#                                                                        stringr::str_trim(x)), y), mc.cores = ncores)

# Finding amount of noise on each page
noise <- mclapply(texts, function(x) strsplit(x, "\\p{L}", perl = TRUE), mc.cores = ncores)
noise <- lapply(noise, function(x) sum(nchar(x)))
noise <- unlist(noise)
noise[(which(noise > 16940))]
plot(density(noise))

chars <- mclapply(texts, function(x) strsplit(x, "\\P{L}", perl = TRUE), mc.cores = ncores)

noise <- mclapply(noise, function(x) nchar(paste0(x, collapse = "")))
chars <- mclapply(chars, function(x) nchar(paste0(x, collapse = "")))

summary(unlist(noise))
test[(which(test > 5500 ))]

regexPattern <- "[A-Z][a-z]*:|[A-Z][a-z]*\\s[A-Z][a-z]*:|[A-Z][a-z]*\\s\\([^\\)]+\\):|[A-Z][a-z]*\\s[A-Z][a-z]*\\s\\([^\\)]+\\):|Statsråd\\s[A-Z][a-z]*:"
speaker <- gsubfn::strapply(texts[[422]], regexPattern, simplify = TRUE)
speaker <- ifelse(agrepl("Presidenten:", speaker, max.distance = 3)==TRUE, "Presidenten:", speaker)
words <- strsplit(texts[[1]], "[A-Z][a-z]{1,100}:")

test <- lapply(101:105, function(x) unlist(strsplit(texts[[x]], regexPattern)))
test


