# BMI 212 Glaucoma 
# Mamie Wang
# specific aim 2: association between different NDDs and diabetes

library(dplyr)
library(lme4)
library(foreach)
library(doParallel)


data.all <- read.csv('NDDPSM2.csv', stringsAsFactors=F)

responses <- c('ALZHEIM', 'PARKINS', 'ALS', 'MS')

# Full model
formula_rhs <- 'AGE + diab + BMI + RACE + diab:AGE + (1 | ID)'
# Baseline model
#formula_rhs <- 'AGE + diab + RACE + diab:AGE + (1 | ID)'

# Parallelism prelude
cores <- detectCores()
cluster <- makeCluster(cores[1] - 1)
registerDoParallel(cluster)

model_results <- foreach(response=responses) %dopar% {
	library(lme4)
	formula = as.formula(paste(response, '~', formula_rhs))
	model <- glmer(formula=formula, data=data.all, na.action=na.omit, family=binomial(link="logit"), verbose=1)
	model
}
names(model_results) <- responses
for (model in model_results) {
	summary(model)
}
save(model_results, file='specificAim2.RData')

# Parallelism epilogue
stopCluster(cluster)

