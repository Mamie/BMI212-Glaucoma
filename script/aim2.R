# BMI 212 Glaucoma 
# Mamie Wang
# specific aim 2: association between different NDDs and diabetes

library(lme4)
library(dplyr)


data.all <- read.csv('NDDPSM2.csv', stringsAsFactors=F)


# full model
alz.full <- glmer(formula = ALZHEIM ~ AGE + diab + BMI + RACE + diab:AGE + (1 | ID), 
                  data=data.all, na.action=na.omit, 
                  family=binomial(link = "logit"), verbose=1)
summary(alz.full)


parkins.full <- glmer(formula = PARKINS ~ AGE + diab + BMI + RACE + diab:AGE + (1 | ID), 
                      data=data.all, na.action=na.omit, 
                      family=binomial(link = "logit"), verbose=1)
summary(parkins.full)

als.full <- glmer(formula = ALS ~ AGE + diab + BMI + RACE + diab:AGE + (1 | ID), 
                  data=data.all, na.action=na.omit, 
                  family=binomial(link = "logit"), verbose=1)
summary(als.full)

ms.full <- glmer(formula = MS ~ AGE + diab + BMI + RACE + diab:AGE + (1 | ID), 
                 data=data.all, na.action=na.omit, 
                 family=binomial(link = "logit"), verbose=1)
summary(ms.full)


save(alz.full, parkins.full, als.full, ms.full, file='specificAim2.RData')


# baseline models
#alz.baseline <- glmer(formula = ALZHEIM ~ AGE + diab + RACE + diab:AGE + (1 | ID), 
#                      data=data.all, na.action=na.omit,
#                      family=binomial(link = "logit"), verbose=1)
#summary(alz.baseline)


#parkins.baseline <- glmer(formula = PARKINS ~ AGE + diab + RACE + diab:AGE + (1 | ID), 
#                          data=data.all, na.action=na.omit,
#                          family=binomial(link = "logit"), verbose=1)
#summary(parkins.baseline)


#als.baseline <- glmer(formula = ALS ~ AGE + diab + RACE + diab:AGE + (1 | ID), 
#                      data=data.all, na.action=na.omit,
#                      family=binomial(link = "logit"), verbose=1)
#summary(als.baseline)


#ms.baseline <- glmer(formula = MS ~ AGE + diab + RACE + diab:AGE + (1 | ID), 
#                     data=data.all, na.action=na.omit,
#                     family=binomial(link = "logit"), verbose=1)
#summary(ms.baseline)

#save(alz.baseline, parkins.baseline, als.baseline, ms.baseline, file='specificAim2.RData')