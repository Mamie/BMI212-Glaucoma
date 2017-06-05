# BMI 212 Glucoma 
# Mamie Wang
# specific aim 3: effect of diabetic medication on NDD for diabetes patients

library(dplyr)
library(ggplot2)
library(MatchIt)

data <- read.csv('cohortDrug.csv', stringsAsFactors=F)
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
pscores <- predict(ps.fit, type='link')
ps_df <- data.frame(pscores=pscores,
                    treated=data.diabetes$treated)

labs <- paste(c("Treated", "Not treated"))
fig1 <- ps_df %>%
  mutate(treated = ifelse(treated==1, labs[1], labs[2])) %>%
  ggplot(aes(x = pscores, color=treated, fill=treated)) +
  geom_density(alpha=0.4) +
  xlab('propensity score') + theme_bw(base_size=20)
fig1

# Propensity score matching using nearest neighnor method
mod_match <- matchit(treated ~ BMI*AGE + as.factor(RACE)*BMI,
                     method = "nearest", data = data.diabetes)
print(summary(mod_match)) 

# restart if not able to convert to data frame
data.matched <- match.data(mod_match)
matched <- data.matched$ID
write.table(matched, file='aim3matchedID.csv', sep=',', row.names=F, col.names=T,
            quote=F)

