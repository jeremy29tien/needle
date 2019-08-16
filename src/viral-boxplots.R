library(ggplot2)
library(ggrepel)
library(dplyr)

is_outlier <- function(x,coef=1.5) {
  return(x < quantile(x, 0.25,na.rm = T) - coef * IQR(x,na.rm = T) | x > quantile(x, 0.75,na.rm = T) + coef * IQR(x,na.rm = T))
}
###
#data=data.frame(Sample=paste0("PIVUS",1:130),Age=factor(rep(c("Age 70","Age 80"),65)), Y=rnorm(n = 130,mean = ,sd = 1))
#data$Y[5]=-4
###

##Total Viral Reads
in_file = "/users/j29tien/needle/results/VIRAL/sample-counts.csv"
data=read.csv(in_file)[,c(1,2,3)]
data<-data[!(data$sample =="PIVUS039"),] # doesn't have PIVUS040 (80 yr old) pair
data <- cbind(data, Age=factor(rep(c("Age 70","Age 80"),64)))
#data$Proportion <- log(data$Proportion)

pvalue=wilcox.test(x = data$num_reads[data$Age=="Age 70"], y = data$num_reads[data$Age=="Age 80"], paired = TRUE)$p.value

p=ggplot(data = data %>% group_by(Age)  %>% mutate(outlier=ifelse(is_outlier(num_reads), yes = as.character(sample),no = "")), mapping = aes(x = Age, y = num_reads, fill=Age)) + geom_boxplot() + geom_text_repel(mapping = aes(label=outlier), size=5) + scale_fill_manual(values = c("darkred", "darkblue")) + ylab("Viral Reads\n (counts)") + theme_bw() + theme(axis.title.x = element_blank(), axis.text.x = element_text(color="black", size = 17), axis.title.y = element_text(size=20),  axis.text.y = element_text(size=12), legend.position = "none") + annotate(geom = "text", x = 1.5, y = 4, label=paste0("p-value=",format(x = pvalue, digits = 2, scientific = T)), size=5)
print(p)

ggsave(filename = "/users/j29tien/needle/results/VIRAL/total-counts.pdf", plot = p, width = 7, height = 10)


## Make boxplot and run t-test for paired data (differences)
data=read.csv(in_file)[,c(4)]
data <- data[!is.na(data)]	#na.rm = TRUE already set in is_outlier


p=ggplot(data = data  %>% mutate(outlier=ifelse(is_outlier(data), yes = as.character(sample),no = "")), mapping = aes(x = "Age 80 - Age 70", y = data)) + geom_boxplot() + geom_text_repel(mapping = aes(label=outlier), size=5) + scale_fill_manual(values = c("darkred", "darkblue")) + ylab("Viral Reads\n (counts)") + theme_bw() + theme(axis.title.x = element_blank(), axis.text.x = element_text(color="black", size = 17), axis.title.y = element_text(size=20),  axis.text.y = element_text(size=12), legend.position = "none") + annotate(geom = "text", x = 1.5, y = 4, label=paste0("p-value=",format(x = pvalue, digits = 2, scientific = T)), size=5)
print(p)


