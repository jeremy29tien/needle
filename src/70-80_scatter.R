library(ggplot2)

df <- read.csv("/users/j29tien/needle/results/VIRAL/Needle_Summary_20190627.csv", header=TRUE)
df <- df[-c(33), ] # remove row with PIVUS039, since no PIVUS040
rownames(df) <- NULL

test <- split(df, rep(c(1, 2), length.out = nrow(df)))


#age_spl <- do.call("cbind", split(df, rep(c("age_70", "age_80"), length.out = nrow(df))))

#ggplot(age_spl, aes(x=age_70.Hepatitis_C_virus_protease_, y=age_80.Hepatitis_C_virus_protease_)) + geom_point()

#hepE <-age_spl[,grep("Hepatitis_E_virus", ignore.case=TRUE, colnames(age_spl))] # ignores case, and checks if string is CONTAINED in column



age_70 <- test$"1"
age_80 <- test$"2"


## Hepatitis E Virus
hep70 <- age_70[,grep("Hepatitis_E_virus", ignore.case=TRUE, colnames(age_70))]
hep80 <- age_80[,grep("Hepatitis_E_virus", ignore.case=TRUE, colnames(age_80))]

hep70 <- cbind(hep70, rowSums(hep70))
hep80 <- cbind(hep80, rowSums(hep80))

hepE <- cbind(hep70$"rowSums(hep70)", hep80$"rowSums(hep80)")
rownames(hepE) <- NULL
hepE <- cbind(c(rep("Hepatitis_E_virus", 64)), hepE)
colnames(hepE) <- c("Virus", "Age_70", "Age_80")
hepE <- as.data.frame(hepE)

#ggplot(hepE, aes(x=Age_70, y=Age_80, shape=Virus, color=Virus)) + geom_point() + xlim(0,100) + ylim(0,100) # can adjust xlim and ylim


## Bovine viral diarrhea virus
bov70 <- age_70[,grep("Bovine_viral_diarrhea_virus", ignore.case=TRUE, colnames(age_70))]
bov80 <- age_80[,grep("Bovine_viral_diarrhea_virus", ignore.case=TRUE, colnames(age_80))]

bov70 <- cbind(bov70, rowSums(bov70))
bov80 <- cbind(bov80, rowSums(bov80))

bovD <- cbind(bov70$"rowSums(bov70)", bov80$"rowSums(bov80)")
rownames(bovD) <- NULL
bovD <- cbind(c(rep("Bovine_viral_diarrhea_virus", 64)), bovD)
colnames(bovD) <- c("Virus", "Age_70", "Age_80")
bovD <- as.data.frame(bovD)

#ggplot(bovD, aes_string(x="Age_70", y="Age_80")) + geom_point() + xlim(0,100) + ylim(0,100) # can adjust xlim and ylim

## Stealth_virus_1_clone_3B43_
stl70 <- age_70[,grep("Stealth_virus_1_clone_3B43_", ignore.case=TRUE, colnames(age_70))]
stl80 <- age_80[,grep("Stealth_virus_1_clone_3B43_", ignore.case=TRUE, colnames(age_80))]

stl70 <- cbind(stl70, rowSums(stl70))
stl80 <- cbind(stl80, rowSums(stl80))

stealth <- cbind(stl70$"rowSums(stl70)", stl80$"rowSums(stl80)")
rownames(stealth) <- NULL
stealth <- cbind(c(rep("Stealth_virus_1_clone_3B43_", 64)), stealth)
colnames(stealth) <- c("Virus", "Age_70", "Age_80")
stealth <- as.data.frame(stealth)


## Hepatitis_C_virus_ 
hepC70 <- age_70[,grep("Hepatitis_C_virus_", ignore.case=TRUE, colnames(age_70))]
hepC80 <- age_80[,grep("Hepatitis_C_virus_", ignore.case=TRUE, colnames(age_80))]

hepC70 <- cbind(hepC70, rowSums(hepC70))
hepC80 <- cbind(hepC80, rowSums(hepC80))

hepC <- cbind(hepC70$"rowSums(hepC70)", hepC80$"rowSums(hepC80)")
rownames(hepC) <- NULL
hepC <- cbind(c(rep("Hepatitis_C_virus_", 64)), hepC)
colnames(hepC) <- c("Virus", "Age_70", "Age_80")
hepC <- as.data.frame(hepC)

## Combine and graph
viruses <- rbind(hepE, bovD, stealth, hepC)

viruses$Age_70 <- as.numeric(as.character(viruses$Age_70))
viruses$Age_80 <- as.numeric(as.character(viruses$Age_80))
viruses$Virus <- as.factor(viruses$Virus)

# insert age_70$Sample and age_80$Sample as labels on the scatter 

ggplot(viruses, aes(x=Age_70, y=Age_80, shape=Virus, color=Virus)) + geom_point() + coord_cartesian(xlim =c(0, 100), ylim = c(0, 100)) + stat_function(fun = function(x) x) # deleted + xlim(0,100) + ylim(0,100), otherwise would receive Error: Discrete value supplied to continuous scale

ggsave("/users/j29tien/needle/results/VIRAL/virus_70-80_scatter.png")


