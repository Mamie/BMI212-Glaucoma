# BMI 212 Glucoma 
# Mamie Wang
# Masood Malekghassemi (weight definition)
# specific aim 3: effect of diabetic medication on NDD for diabetes patients
library(dplyr)
library(ggplot2)
library(MatchIt)
data <- read.csv('data/cohortDrug.csv', stringsAsFactors=F)
data.diabetes <- data %>%
  filter(DIAB==1 | F134DIAB==1) %>%
  mutate(treated=(F44INSULIN+F44SULFONYLUREA+F44DPHENYLDERIV+F44BIGUANIDES+F44OTHERDIAB+F44THIAZO>1)) %>%
  select(ID, AGE, RACE, BMI, treated) %>%
  group_by(ID, AGE, RACE, BMI) %>%
  summarize(treated=max(treated)) %>%
  na.omit()
sum(data.diabetes$treated==1) # 1133
ps.fit <- glm(treated ~ BMI * AGE + as.factor(RACE) * BMI,
              data=data.diabetes, family=binomial(link='logit'))
pscores <- predict(ps.fit, type='response')
ps_df <- data.frame(ID=data.diabetes$ID,
                    pscores=pscores,
                    treated=data.diabetes$treated)
ps_df <- ps_df %>%
  mutate(weight=ifelse(treated==1, 1/pscores, 1/(1-pscores)))
write.table(ps_df, file='aim3ID.csv', sep=',', row.names=F, col.names=T, quote=F)
