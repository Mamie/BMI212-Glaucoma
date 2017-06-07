# BMI 212 Glaucoma 
#  Mamie Wang
#  Masood Malekghassemi (minor edits)
# Specific aim 1: association between different NDDs and diabetes

library(lme4)
library(dplyr)

matched <- read.csv('PSMmatched.csv', stringsAsFactors=F)
data.all <- read.csv('WHImerged.csv', stringsAsFactors=F)

# create the data matrix for specific aims 1 + 2
data.all <- data.all %>%
  mutate(AGE=AGE*365+date) %>%
  filter(ID %in% unlist(matched))
data.all$AGE <- as.numeric(scale(data.all$AGE))
data.all$BMI <- as.numeric(scale(data.all$BMI))
data.all$NDD <- apply(cbind(data.all$ALZHEIM, data.all$PARKINS, data.all$ALS, data.all$MS), 
                      1, function(x) x[1] | x[2] | x[3] | x[4])
write.table(data.all, file='NDDPSM.csv', sep=',', row.names=F, col.names=T, quote=F)

# Full model (does not converge)
#formula_rhs <- 'AGE + diab + BMI + RACE + diab:AGE + (1 | ID)'
# Baseline model
formula_rhs <- 'AGE + diab + RACE + BMI + diab:AGE + (1 | ID)'

formula <- as.formula(paste('NDD ~', formula_rhs))
model.aim1 <- glmer(formula=formula, 
                    data=data.all, na.action=na.omit,
                    family=binomial(link = "logit"), verbose=1)
summary(model.aim1)
save(model.aim1, file='specificAim1.RData')

