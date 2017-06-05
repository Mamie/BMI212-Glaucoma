library(dplyr)
library(ggplot2)
library(tidyr)
library(data.table)

####################################################################
# Cohort building
# This program reads in the data files from WHI data set (in data/)
# and construct the study cohort using the following exclusion criteria
# 1. missing diabetes status
# 2. abnormal response pattern
# 3. missing OS followup data
# The output is a csv file containing the following variables for the
# cohort:
# ID, AGE, OSFLAG, RACE, F2DAYS (diabetes status date), DIABAGE (age
# of diabetes), DIABCOMA, DBDIETF2, INSULIN, INSULINW, DIABPILL, DIANW,
# F134DAYS, F134PARKINS, F134DIAB, HYPT, GLAUCOMA, EDUC, SMOKEVR, BMI,
# DEATHALL (death indicator), DEATHLLDY (date of death), date (NDD 
# response date), ALZHEIM (Alzheimer response), MS (Multiple Sclerosis
# response), PARKINS (Parkinson's Disease response), ALS (ALS response),
# label (a categorical variable of level 4 that indicates the combination
# of diabetes and NDD status)
####################################################################

# Helper function to read the WHI .dat file
readDatFile <- function(path) {
  if (file.exists(path)) {
    return(read.csv(path, stringsAsFactors=F, header=T, sep='\t'))
  } else {
    inside <- c()
  	outside <- path
    while (outside != "") {
	  inside <- c(basename(outside), inside)
      outside <- dirname(outside)
	  outside.zip <- paste0(outside, ".zip")
	  if (file.exists(outside.zip)) {
        return(read.csv(unz(outside.zip, filename=paste0(inside, collapse='')),
						stringsAsFactors=F, header=T, sep='\t'))
	  }
	}
  }
}
# construct OS followup year 1 and 2 from the response of followup year 3
decodeStatus <- function(x) {
  ifelse(x==0, 0, ifelse(x==1, 0, ifelse(x==2, 1, ifelse(x==3, 2, NA))))
}

# Load all necessary data files
WHI.medHistoryAddendum <- readDatFile('data/WHI/Medical History/f134_ctos_inv/f134_ctos_inv.dat')
WHI.NDDbaseline <- readDatFile('data/WHI/Medical History/f30_ctos_inv/f30_ctos_inv.dat')
WHI.os3 <- readDatFile('data/WHI/OS Followup/f143_av3_os_inv/f143_av3_os_inv.dat') # can be expanded to year 1 - 3
WHI.os4 <- readDatFile('data/WHI/OS Followup/f144_av4_os_inv/f144_av4_os_inv.dat')
WHI.os5 <- readDatFile('data/WHI/OS Followup/f145_av5_os_inv/f145_av5_os_inv.dat')
WHI.os6 <- readDatFile('data/WHI/OS Followup/f146_av6_os_inv/f146_av6_os_inv.dat')
WHI.os7 <- readDatFile('data/WHI/OS Followup/f147_av7_os_inv/f147_av7_os_inv.dat')
WHI.os8 <- readDatFile('data/WHI/OS Followup/f148_av8_os_inv/f148_av8_os_inv.dat')
WHI.diabetesBaseline <- readDatFile('data/WHI/Demographics/f2_ctos_inv/f2_ctos_inv.dat')
WHI.age <- readDatFile('data/WHI/Demographics/dem_ctos_inv/dem_ctos_inv.dat')
WHI.education <- readDatFile('data/WHI/Demographics/f20_ctos_inv/f20_ctos_inv.dat')
WHI.smoker <- readDatFile('data/WHI/Psychosocial/f34_ctos_inv/f34_ctos_inv.dat')
WHI.BMI <- readDatFile('data/WHI/Medical and Physical/f80_ctos_inv/f80_ctos_inv.dat')
WHI.death <- readDatFile('data/WHI/Outcomes/outc_death_all_discovered_inv/outc_death_all_discovered_inv.dat')


# Cohort selection and feature matrix construction

# BMI was taken at multiple time points (use an average of BMI)
WHI.BMI <- WHI.BMI %>%
  select(ID, BMI) %>%
  group_by(ID) %>%
  summarize(BMI=mean(BMI, na.rm=T))

# select OS cohort and remove patients with no diabetes baseline
WHI.merged <- WHI.age[, c("ID", "AGE", "OSFLAG")] %>%
  filter(OSFLAG==1) %>%
  left_join(WHI.diabetesBaseline[, c('ID', 'RACE', 'F2DAYS', 'DIAB', 'DIABAGE', 'DIABCOMA', 'DBDIETF2', 'INSULIN', 'INSULINW', 'DIABPILL', 'DIABNW')]) %>%
  filter(!is.na(DIAB))

# add the NDD baseline, education, smoker status and 
WHI.merged <- WHI.merged %>%
  left_join(WHI.medHistoryAddendum[, c('ID', 'F134DAYS', 'F134PARKINS', 'F134DIAB')]) %>%
  left_join(WHI.NDDbaseline[,c('ID', 'F30DAYS', 'HYPT', 'ALZHEIM', 'MS', 'PARKINS', 'ALS', 'GLAUCOMA')]) %>%
  left_join(WHI.education[,c("ID", "EDUC")]) %>%
  left_join(WHI.smoker[, c('ID', 'SMOKEVR')]) %>%
  left_join(WHI.BMI) %>%
  left_join(WHI.death[, c('ID', 'DEATHALL', 'DEATHALLDY')])

# construct the followup NDD response matrix
year0 <- WHI.merged[c(1, 17, seq(19, 22))]
colnames(year0) <- c('ID', 'date', 'ALZHEIM', 'MS', 'PARKINS', 'ALS')
year0$label <- 0
year2 <- cbind(WHI.os3[,c('ID', 'F143DAYS', 'ALZHEIM_3', 'MS_3', 'PARKINS_3', 'ALS_3')], 3) %>%
  mutate(date=F143DAYS - 365,
         ALZHEIM_2 = decodeStatus(ALZHEIM_3), 
         MS_2 = decodeStatus(MS_3),
         PARKINS_2 = decodeStatus(PARKINS_3),
         ALS_2 = decodeStatus(ALS_3)) %>%
  select(ID, date, ALZHEIM_2, MS_2, PARKINS_2, ALS_2) %>%
  mutate(label=2)
year1 <- year2 %>%
  mutate(date=date-365,
         ALZHEIM_1 = decodeStatus(ALZHEIM_2), 
         MS_1 = decodeStatus(MS_2),
         PARKINS_1 = decodeStatus(PARKINS_2),
         ALS_1 = decodeStatus(ALS_2)) %>%
  select(ID, date, ALZHEIM_1, MS_1, PARKINS_1, ALS_1) %>%
  mutate(label=1)
year2 <- year2 %>%
  mutate(ALZHEIM_2 = (ALZHEIM_2 > 0), 
         MS_2 = (MS_2 > 0),
         PARKINS_2 = (PARKINS_2 > 0),
         ALS_2 = (ALS_2 > 0))
year3 <- WHI.os3[,c('ID', 'F143DAYS', 'ALZHEIM_3', 'MS_3', 'PARKINS_3', 'ALS_3')] %>%
  mutate(label=3) %>%
  mutate(ALZHEIM_3 = (ALZHEIM_3 > 0), 
         MS_3 = (MS_3 > 0),
         PARKINS_3 = (PARKINS_3 > 0),
         ALS_3 = (ALS_3 > 0))
NDD <- year0 %>%
  list(year1) %>%
  rbindlist() %>%
  list(year2) %>%
  rbindlist() %>%
  list(year3) %>%
  rbindlist() %>%
  list(cbind(WHI.os4[,c('ID', 'F144DAYS', 'ALZHEIM_4', 'MS_4', 'PARKINS_4', 'ALS_4')], 4)) %>%
  rbindlist() %>%
  list(cbind(WHI.os5[,c('ID', 'F145DAYS', 'ALZHEIM_5', 'MS_5', 'PARKINS_5', 'ALS_5')], 5)) %>%
  rbindlist() %>%
  list(cbind(WHI.os6[,c('ID', 'F146DAYS', 'ALZHEIM_6', 'MS_6', 'PARKINS_6', 'ALS_6')], 6)) %>%
  rbindlist() %>%
  list(cbind(WHI.os7[,c('ID', 'F147DAYS', 'ALZHEIM_7', 'MS_7', 'PARKINS_7', 'ALS_7')], 7)) %>%
  rbindlist() %>%
  list(cbind(WHI.os8[,c('ID', 'F148DAYS', 'ALZHEIM_8', 'MS_8', 'PARKINS_8', 'ALS_8')], 8)) %>%
  rbindlist()


# find abnormal response where the patients have positive response for all NDDs
badIDs <- NDD %>%
  filter(ALZHEIM + MS + PARKINS + ALS > 3) %>%
  select(ID) %>%
  distinct()

# remove abnormal response pattern
WHI.merged <- WHI.merged[-c(17, seq(19, 22))] %>%
  filter(!(ID %in% unlist(badIDs))) %>%
  left_join(NDD) 

# remove any follow up years with no response
WHI.merged <- WHI.merged[!apply(WHI.merged[, seq(25, 28)], 1, function(x) sum(is.na(x))==4), ]
print(length(unique(WHI.merged$ID)))

# remove patients with no followup 
WHI.merged <- WHI.merged %>%
  group_by(ID) %>%
  filter(n() > 1)
print(length(unique(WHI.merged$ID))) # 88487 patients in the final cohort

# construct the variable that indicates the diabetes status of the patients
WHI.merged <- WHI.merged %>%
  mutate(diab=max(DIAB, F134DIAB, na.rm=T))

write.table(WHI.merged, file='WHImerged.csv', quote=F, row.names=F, col.names=T,
            sep=',')

