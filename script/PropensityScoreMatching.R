# Authors:
#  Mamie Wang
#  Masood Malekghassemi (minor bugfix)

library(dplyr)
library(ggplot2)
library(MatchIt)

# Propensity score matching for the diabetes and non-diabetes cohort
# on age at enrollment, race and bmi
data.all <- read.csv('WHImerged.csv', header=T, stringsAsFactors=F)
data.ps <- data.all %>%
  select(ID, AGE, RACE, BMI, diab, ALZHEIM, MS, PARKINS, ALS) %>%
  na.omit() %>%
  group_by(ID, RACE, BMI, diab) %>%
  summarize(AGE = min(AGE)) %>%
  unique()
# Normalize the construction of data.ps to avoid MatchIt/dplyr interaction bugs
# further down the line.
data.ps <- data.frame(data.ps)

# Visualization of the pre-matching propensity score distribution
ps.fit <- glm(diab ~ BMI * AGE + as.factor(RACE) * BMI,
                data=data.ps, family=binomial(link='logit'))
pscores <- predict(ps.fit, type='link')
ps_df <- data.frame(pscores=pscores,
                    diab=data.ps$diab)

save(ps.fit, file='aim1PSMfit.RData')

labs <- paste(c("Diabetic", "Nondiabetic"))
fig1 <- ps_df %>%
  mutate(diab = ifelse(diab==1, labs[1], labs[2])) %>%
  ggplot(aes(x = pscores, color=diab, fill=diab)) +
  geom_density(alpha=0.4) +
  xlab('propensity score') + theme_bw(base_size=20)
fig1

# Propensity score matching using nearest neighnor method
mod_match <- matchit(diab ~ BMI*AGE + as.factor(RACE)*BMI,
                     method = "nearest",
					 data = data.ps)
print(summary(mod_match)) 

# Sample sizes:
#  Control Treated
#All         78881    9212
#Matched      9212    9212
#Unmatched   69669       0
#Discarded       0       0

data.matched <- match.data(mod_match)
matched <- data.matched$ID
write.table(matched, file='PSMmatched.csv', sep=',', row.names=F, col.names=T,
            quote=F)



