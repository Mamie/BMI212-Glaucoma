# BMI 212 Glucoma 
#  Mamie Wang

# Balance analysis before matching
# The results show imbalance in the three variables in the dataset
library(AER) 
library(gbm)
library(lme4)
library(MatchIt)

data.all <- read.csv('WHImerged.csv', header=T) %>%
  select(ID, diab, AGE, BMI, RACE, EDUC) %>%
  na.omit() %>%
  mutate(RACE=as.factor(RACE)) %>%
  mutate(EDUC=as.factor(EDUC)) %>%
  unique()
data.all$BMI <- scale(data.all$BMI)
data.all$AGE <- scale(data.all$AGE)

age.balance <- lm(AGE ~ diab, data=data.all)
summary(age.balance)

bmi.balance <- lm(BMI ~ diab, data=data.all)
summary(bmi.balance)

library(nnet)
race.balance <- multinom(RACE~diab, data=data.all, na.action=na.omit)
summary(race.balance)
coeftest(race.balance)

edc.balance <- multinom(EDUC~diab, data=data.all)
summary(edc.balance)
coeftest(edc.balance)


# logistic regression to estimate PS
ps <- glm(diab ~ BMI * AGE + RACE * BMI,
          data=data.all, family=binomial(link='logit'))
summary(ps)
data.all <- data.all %>%
  left_join(rbind(data.all$ID, gps))

# generalized boosted model
gps <- gbm(diab ~ BMI, data=data.all, distribution='bernoulli', n.trees=100, interaction.depth=4, train.fraction=0.8, shrinkage=0.0005)
summary(gps)


data.all$psvalue <- predict(ps, type='response')
data.all$gpsvalue <- predict(gps, type='response')

# weighted estimation using PS
data.all$weighted.ATE <- ifelse(data.all$diab==1, 1/data.all$psvalue, 1/(1-data.all$psvalue))
data.all$weighted.ATE2 <- ifelse(data.all$diab==1, 1/data.all$gpsvalue, 1/(1-data.all$gpsvalue))


data.all2 <- read.csv('WHImerged.csv', header=T) %>%
  mutate(AGE=AGE*365+date)
data.all2$AGE <-  as.numeric(scale(data.all2$AGE))
data.all2$BMI <- as.numeric(scale(data.all2$BMI))
data.all2$NDD <- apply(cbind(data.all2$ALZHEIM, data.all2$PARKINS, data.all2$ALS, data.all2$MS), 
                      1, function(x) x[1] | x[2] | x[3] | x[4])

data.all2 <- data.all2 %>%
  left_join(select(data.all, ID, weighted.ATE2) )

model.baseline <- glmer(formula = NDD ~ AGE + diab + RACE + BMI + diab:AGE + (1 | ID), 
                        data=data.all2, na.action=na.omit,
                        family=binomial(link = "logit"),
                        weights=weighted.ATE2,
                        verbose=1)


# Nearest neighbor matching
match_model <- matchit(diab ~ AGE + RACE + BMI + EDUC, data=data.frame(data.all), method="nearest")
plot(match_model)
match_data <- match.data(match_model)

