
args = commandArgs(trailingOnly=TRUE)
# test if there is at least one argument: if not, return an error                              
if (length(args)==0) {
  stop("Please provide the starting and ending PIVUS samples representing the range for this to be run on.", call.=FALSE)
}
startSample=args[1]
endSample=args[2]
sample=startSample

#totalviralcount <- read.csv(paste("/users/j29tien/ROP/results/",sample,"_ROP/",sample,"_Aligned--counts.csv", sep=""))
#ROPmapped_readcount <- rowSums(totalviralcount)
#totalviralcount <- totalviralcount[c(1)]

#will be making this a proportion of all the reads ROP was able to map
#pviral <- totalviralcount/ROPmapped_readcount

#totalviralcount <- cbind(sample,totalviralcount, ROPmapped_readcount, pviral)


totalviralcount <- data.frame(Sample=character(), Viral_Read_Count=character(), Paired_Difference=character())
counter = as.integer(1)

repeat {  # loop includes endSample                               
  print(sample)
  filename = paste("/users/j29tien/needle/results/",sample,".needle/",sample,"_Aligned--07c_viral_output.virus.megahit.contigs.SV.csv", sep="")  

  if(file.exists(filename)) {
    next_entry = read.csv(filename)
    num_reads = c(nrow(next_entry))

    #ROPmapped_readcount <- rowSums(next_entry)
    #next_entry <- next_entry[c(1)]
    #pviral <- next_entry/ROPmapped_readcount
    next_entry <- cbind(sample, num_reads) # (, ROPmapped_readcount, pviral)
    if(as.numeric(substring(sample,6)) %% 2 == 0) {
      next_entry <- cbind(next_entry, c(num_reads - as.numeric(as.character(totalviralcount$num_reads[[counter - 1]]))))
    } else {
      next_entry <- cbind(next_entry, c(""))
    }
    totalviralcount <- rbind(totalviralcount,next_entry)
    
    counter = counter+1

    if(sample == endSample) {
      break
    }
  }
  sample=substring(sample, 6)
  sample=as.numeric(sample)
  sample=sample+1
  sample=sprintf("PIVUS%03d", sample)
  
}

#colnames(totalviralcount) <- c("Sample","Viral Read Count", "ROP Mapped Read Count", "Proportion")
# will we need to calculate proportions (of total number of mapped reads)?

print(totalviralcount)
write.csv(totalviralcount, file="/users/j29tien/needle/results/VIRAL/sample-counts.csv")


 # age_seventy <- subset(totalviralcount, as.numeric(substring(totalviralcount$Sample,6)) %% 2 == 1 & totalviralcount$Sample != "PIVUS039",select=c("Sample", "Viral Read Count"))
 # age_eighty <- subset(totalviralcount, as.numeric(substring(totalviralcount$Sample,6)) %% 2 == 0,select=c("Sample", "Viral Read Count"))
 # seventy_eighty_count <- cbind(age_seventy[c("Viral Read Count")], age_eighty[c("Viral Read Count")])
 # #p_seventy_eighty <- cbind(age_seventy[c("Proportion")], age_eighty[c("Proportion")])
 # colnames(seventy_eighty_count) <- c("Age 70", "Age 80")
 # #colnames(p_seventy_eighty) <- c("Age 70", "Age 80")
 # write.csv(seventy_eighty_count, file="/users/j29tien/needle/results/VIRAL/viral-count-by-age.csv")
 # #write.csv(p_seventy_eighty, file="/users/j29tien/ROP/results/VIRAL/viral-proportion-by-age.csv")


