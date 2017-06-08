# A longitudinal analysis of the association between neurodegenerative diseases and diabetes mellitus using generalized linear mixed-effect models

authors: Mamie Wang, Soltan Malekghassemi, Sunil Pai

contributions:
- All authors contributed equally to the completion of this project
- Mamie worked on cohort selection, data exploration/cleanup, propensity score matching, model search and building, documentation, figures, and paper writing.
- Soltan worked on background, model search and building, troubleshooting, figures, and paper writing.
- Sunil worked on background, data exploration/cleanup, medication data preprocessing, model search and building, and paper writing.

The `script/` folder contain all the R scripts for the analysis presented in the final report. The sequence of execution is:
```
cohortSelection.R
PropensityScoreMatching.R
balanceAnalysis.R
aim1.R
aim1SensitivityAnalysis.R
aim2.R
aim3Preprocess.py
aim3PSM.R
aim3.R
```
The `notebook/` folder contains jupyter notebooks for data exploration.

The `figures/` folder contains scripts to produce the figures in the final report. 

