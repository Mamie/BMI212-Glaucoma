#!/usr/bin/env python

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import matplotlib

matplotlib.rc('font', family='serif', serif=['Computer Modern'])
matplotlib.rc('text', usetex=True)

def doplot(saveto, GLMM_OUT, SPECIAL=["diab"], DIMS=(10, 1)):
  lines = GLMM_OUT.split('\n')
  labels = []
  estimates = []
  stdevs = []
  for line in lines:
    line = line.split()
    if len(line) == 0:
      continue
    labels.append(line[0])
    estimates.append(float(line[1]))
    stdevs.append(abs(float(line[2])))
  df = pd.DataFrame({'label': labels, 'est': estimates, 'stdev': stdevs,}).set_index('label')
  
  # lower bound
  df['lb'] = df['est'] - df['stdev']
  df['ub'] = df['est'] + df['stdev']
  df['lb_95'] = df['est'] - df['stdev']*1.96
  df['ub_95'] = df['est'] + df['stdev']*1.96
  df['lb_90'] = df['est'] - df['stdev']*1.645
  df['ub_90'] = df['est'] + df['stdev']*1.645
  
  plot_df = df.sort_values('est', ascending=True)
  fig = plt.figure(figsize=DIMS)
  ax = fig.add_axes([0, 0, 1, 1])
  fig.add_axes(ax)
  
  y = 0
  for index, row in plot_df.iterrows():
    bstyle = {
      'LineStyle': '-',
      'Color': [0.2, 0.2, 0.2],
      'LineWidth': 2,
    }
    estyle = {
      'Marker': 'o',
      'Color': [0.2, 0.2, 0.2],
      'MarkerEdgeColor': [0.2, 0.2, 0.2],
      'MarkerEdgeWidth': 2,
      'MarkerSize': 4,
    }
    style_90 = {
      'Marker': '+',
      'Color': [0.2, 0.2, 0.2],
      'MarkerEdgeColor': [0.2, 0.2, 0.2],
      'MarkerEdgeWidth': 2,
      'MarkerSize': 4,
      'LineStyle': '',
    }
    if index in SPECIAL:
      bstyle['LineWidth'] *= 2
      bstyle['Color'] = 'k'
      estyle['MarkerSize'] *= 3
      estyle['Color'] = 'k'
      estyle['MarkerEdgeColor'] = 'k'
      style_90['MarkerSize'] *= 3
      style_90['MarkerEdgeColor'] = 'k'
    ax.plot([row['lb_95'], row['ub_95']], [y, y], **bstyle)
    ax.plot([row['est']], [y], **estyle)
    ax.plot([row['lb_90'], row['ub_90']], [y, y], **style_90)
    y += 1
  ax.axvline(0, color='k')
  plt.yticks(range(plot_df.shape[0]))
  ax.set_ylim(-0.5, y - 0.5)
  ax.set_yticklabels(plot_df.index.values)
  plt.xlabel('coefficient')
  plt.savefig(saveto, bbox_inches='tight')

# Just copy-paste the output of the GLMM's merModel coeff matrix here to make plots 'n stuff.
doplot('aim1.png', """
age				2.49	0.22	11.27	<2E-16
diab			1.1		0.51	2.14	0.03
BMI				0.27	0.18	1.49	1.40E-01
age:diab	-0.64	0.28	-2.3	2.00E-02
""")
doplot('aim2_alz.png', """
age				5.43	0.62		8.74	<2E-16
diab			2.95	1.59		1.86	0.06
BMI				0.42	0.35		1.19	2.30E-01
age:diab	-1.21	0.7079	-1.71	9.00E-02
""")
doplot('aim2_parkins', """
age				1.49	0.86	1.75	0.08
diab			-0.62	0.98	-0.62	0.53
BMI				0.33	0.31	1.07	2.90E-01
age:diab	0.44	0.48	0.91	3.60E-01
""")
doplot('aim2_als', """
age				1.49	0.86	1.75	0.08
diab			1.13	1.69	0.67	0.51
BMI				-0.36	0.74	-0.48	6.30E-01
age:diab	-0.44	1.02	-0.43	6.70E-01
""")
doplot('aim2_ms', """
age				-0.44	0.38	-1.16	0.25
diab			-0.02	0.8		-0.02	0.99	
BMI				-0.02	0.35	-0.05	9.60E-01
age:diab	-0.46	0.51	-0.9	3.70E-01
""")
doplot('aim3', """
age                5.0360     0.4775  10.545  < 2e-16 ***
biguanides        -5.5236     1.5391  -3.589 0.000332 ***
insulin            0.4274     0.5391   0.793 0.427864    
sulfonylureas     -3.6793     1.3856  -2.655 0.007920 ** 
age:biguanides     2.5559     0.6389   4.001 6.32E-05 ***
age:insulin       -0.2110     0.2565  -0.822 0.410810    
age:sulfonylureas  1.6625     0.5762   2.885 0.003908
""", SPECIAL=['biguanides', 'sulfonylureas'])
