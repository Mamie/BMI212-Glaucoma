# BMI 212 Glaucoma 
#  Mamie Wang
#  Masood Malekghassemi (parallelism edits)
# specific aim 2: association between different NDDs and diabetes

library(dplyr)
library(lme4)
library(foreach)
library(doParallel)


# Scaled data generated from aim1.R
data.all <- read.csv('NDDPSM.csv', stringsAsFactors=F)

responses <- c('ALZHEIM', 'PARKINS', 'ALS', 'MS')

# Full model
#formula_rhs <- 'AGE + diab + BMI + RACE + diab:AGE + (1 | ID)'
# Baseline model
formula_rhs <- 'AGE + diab + RACE + diab:AGE + (1 | ID)'

# Parallelism prelude
cores <- detectCores()
cluster <- makeCluster(cores[1] - 1)
registerDoParallel(cluster)

models.aim2 <- foreach(response=responses) %dopar% {
	library(lme4)
	formula = as.formula(paste(response, '~', formula_rhs))
	model <- glmer(formula=formula, data=data.all, na.action=na.omit, family=binomial(link="logit"), verbose=1)
	model
}
names(models.aim2) <- responses
for (model in models.aim2) {
	summary(model)
}
save(models.aim2, file='specificAim2.RData')

# Parallelism epilogue
stopCluster(cluster)

