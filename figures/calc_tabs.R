# BMI 212 Glaucoma
#  Mamie Wang
#  Masood Malekghassemi

library(dplyr)


WHI.merged <- read.csv('WHImerged.csv', stringsAsFactors=F)

WHI.modelBaseline <- WHI.merged %>%
  select(ID, DIAB, F134DIAB, date, ALZHEIM, MS, PARKINS, ALS, label)

WHI.modelBaseline$NDD <- apply(WHI.modelBaseline[, seq(5, 8)], 1, function(x) sum(x, na.rm=T) > 0)
positive <- function(x) {
	  sum(x, na.rm=T)  > 0
}

WHI.modelBaselineGroupedById <- WHI.modelBaseline %>%
	group_by(ID)

summarydata.ndd <- WHI.modelBaselineGroupedById %>% 
	    dplyr::summarise(diab=max(c(DIAB, F134DIAB), na.rm=T), ndd=max(NDD, na.rm=T))
	table(summarydata[,c(2,3)])
summarydata.ad <- WHI.modelBaselineGroupedById %>% 
	  group_by(ID) %>%
	    dplyr::summarise(diab=max(c(DIAB, F134DIAB), na.rm=T), ad=max(ALZHEIM, na.rm=T))
	table(summarydata[,c(2,3)])
summarydata.pd <- WHI.modelBaselineGroupedById %>% 
	  group_by(ID) %>%
	    dplyr::summarise(diab=max(c(DIAB, F134DIAB), na.rm=T), pd=max(PARKINS, na.rm=T))
	table(summarydata[,c(2,3)])
summarydata.als <- WHI.modelBaselineGroupedById %>% 
	  group_by(ID) %>%
	    dplyr::summarise(diab=max(c(DIAB, F134DIAB), na.rm=T), als=max(ALS, na.rm=T))
	table(summarydata[,c(2,3)])
summarydata.ms <- WHI.modelBaselineGroupedById %>% 
	  group_by(ID) %>%
	    dplyr::summarise(diab=max(c(DIAB, F134DIAB), na.rm=T), ms=max(MS, na.rm=T))
	table(summarydata[,c(2,3)])

disptable <- function(s, col1, col2) {
	a <- s[,col1]
	b <- s[,col2]
	and <- sum(a & b)
	only_a <- sum(a & !b)
	only_b <- sum(!a & b)
	neither <- sum(!a & !b)
	print(paste0('', col1, ' & ', col2, ': ', and))
	print(paste0('', col1, ' & !', col2, ': ', only_a))
	print(paste0('!', col1, ' & ', col2, ': ', only_b))
	print(paste0('!', col1, ' & !', col2, ': ', neither))
}
disptable(summarydata.ndd, 'diab', 'ndd')
disptable(summarydata.ad, 'diab', 'ad')
disptable(summarydata.pd, 'diab', 'pd')
disptable(summarydata.als, 'diab', 'als')
disptable(summarydata.ms, 'diab', 'ms')
