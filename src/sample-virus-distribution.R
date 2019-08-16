args = commandArgs(trailingOnly=TRUE)
# test if there is at least one argument: if not, return an error                              
if (length(args)==0) {
  stop("Please provide the starting and ending PIVUS samples representing the range for this to be run on.", call.=FALSE)
}
startSample=args[1]
endSample=args[2]
sample=startSample


sample_virus_table <- data.frame(Sample=character())
row_counter = 1

repeat {  # loop includes endSample                               
  print(sample)
  filename = paste("/users/j29tien/needle/results/",sample,".needle/",sample,"_Aligned--07c_viral_output.virus.megahit.contigs.SV.csv", sep="")

  if(file.exists(filename)) {
    next_entry = read.csv(filename)
    num_reads = c(nrow(next_entry))
    

    sample_virus_table <- rbind(sample_virus_table, 0)

    for (i in 1:num_reads){
	virus_name = next_entry$name[i]
	if(virus_name %in% colnames(sample_virus_table)) {
	  sample_virus_table[[row_counter, as.character(virus_name)]] <- sample_virus_table[[row_counter, as.character(virus_name)]] + 1
	} else {
	  sample_virus_table[row_counter, as.character(virus_name)] <- 1
	}
    }

    row_counter = row_counter+1

    if(sample == endSample) {
      break
    }
  }
  sample=substring(sample, 6)
  sample=as.numeric(sample)
  sample=sample+1
  sample=sprintf("PIVUS%03d", sample)

}


print(sample_virus_table)
write.csv(sample_virus_table, file="/users/j29tien/needle/results/VIRAL/sample-virus-table.csv")

