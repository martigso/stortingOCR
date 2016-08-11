rename_pdfs <- function(path, pattern){
  files <- list.files(path, pattern = pattern, full.names = TRUE)

  filenames <- sapply(strsplit(files, "\\/"), function(x) x[length(x)])
  fileorder <- gsub("[^0-9]", "", filenames)
  fileorder <- ifelse(nchar(fileorder)== 3, paste0("0", fileorder),
                      ifelse(nchar(fileorder) == 2, paste0("00", fileorder),
                             ifelse(nchar(fileorder) == 1, paste0("000", fileorder), fileorder)))

  for(i in 1:length(filenames)){
    filenames[i] <- gsub("[0-9]{1,4}", fileorder[i], filenames[i])
  }

  file.rename(files, paste0(path, "/", filenames))

}

rename_pdfs("./tmp/", pattern = ".pdf")
