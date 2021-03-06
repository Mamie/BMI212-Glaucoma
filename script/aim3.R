# BMI 212 Glucoma 
# Masood Malekghassemi (merging cohortDrug.csv and propensity score analysis)
# Sunil Pai (model design and selection of optimizer)
# specific aim 3: effect of diabetic medication on NDD for diabetes patients

library(lme4)
library(dplyr)

data.cohortDrug <- read.csv('data/cohortDrug.csv', stringsAsFactors=F) %>%
  mutate(AGE=AGE*365+date)
data.pscores <- read.csv('data/aim3ID.csv', stringsAsFactors=F)

data.model <- data.cohortDrug %>%
  merge(data.pscores, by='ID')
data.model$AGE <- as.numeric(scale(data.model$AGE))
data.model$BMI <- as.numeric(scale(data.model$BMI))
data.model$F44BIGUANIDES_MAXY <- as.numeric(scale(data.model$F44BIGUANIDES_MAXY))
data.model$F44INSULIN_MAXY <- as.numeric(scale(data.model$F44INSULIN_MAXY))
data.model$F44SULFONYLUREA_MAXY <- as.numeric(scale(data.model$F44SULFONYLUREA_MAXY))
data.model$NDD <- apply(cbind(data.model$ALZHEIM, data.model$PARKINS, data.model$ALS, data.model$MS), 
                        1, function(x) x[1] | x[2] | x[3] | x[4])

formula <- ALZHEIM ~ AGE + F44BIGUANIDES_MAXY*AGE + F44INSULIN_MAXY*AGE + F44SULFONYLUREA_MAXY*AGE + F44BIGUANIDES_MAXY + F44INSULIN_MAXY + F44SULFONYLUREA_MAXY + (1 | ID)

model.aim3 <- glmer(formula=formula,
                    data=data.model, na.action=na.omit,
                    family=binomial(link = "logit"), verbose=1,
                    weights=data.model$weight,
                    control = glmerControl(optimizer ='optimx', optCtrl=list(method='nlminb')))
summary(model.aim3)