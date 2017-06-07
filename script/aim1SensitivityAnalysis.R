# sensitivity analysis on specific aim 1
# Mamie Wang
# Stratification on the propensity score and observe differences in the estimate


library(lme4)
library(dplyr)

load('aim1PSMfit.RData')
ps_df <- data.frame(ID=ps.fit$data$ID, ps=ps.fit$fitted.values)

data.all <- read.csv('NDDPSM.csv', stringsAsFactors = F)
data.model <- data.all %>%
  select(ID, AGE, diab, RACE, BMI, NDD) %>%
  left_join(ps_df) %>%
  na.omit() # 18425 vs 18428 in original data

quintiles <- quantile(ps_df$ps, probs=c(0.2, 0.4, 0.6, 0.8, 1))
assignStrata <- function(x) {
  for (i in seq(5)) {
    if (x < quintiles[i]) return(i)
  }
  NA
}

# stratification into five groups by propensity score
data.stratification <- data.model %>%
  select(ID, ps) %>%
  unique() %>%
  mutate(strata=unlist(sapply(ps, assignStrata)))

for (i in seq(5)) {
  ids <- data.stratification %>%
    filter(strata==i) %>%
    select(ID) %>%
    unlist()
  model.data <- data.all %>%
    filter(ID %in% ids)
  model <- glmer(formula = NDD ~ AGE + diab + RACE + BMI + diab:AGE + (1 | ID), 
                          data=model.data, na.action=na.omit,
                          family=binomial(link = "logit"), verbose=1)
  summary(model)
  save(model, file=paste0('aim1SA2', i, '.RData'))
}



