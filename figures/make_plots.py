import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

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
  
  # Bounds for 95% CI
  df['lb'] = df['est'] - df['stdev'] * 1.96
  df['ub'] = df['est'] + df['stdev'] * 1.96

  df['abs_est'] = df['est']
  df['abs_lb'] = df['lb']
  df['abs_ub'] = df['ub']
  for index, row in df.iterrows():
    row['abs_est'] = abs(row['est'])
    if row['lb'] < 0 and row['ub'] > 0:
      row['abs_lb'] = 0
      row['abs_ub'] = max(-row['lb'], row['ub'])
    else:
      row['abs_lb'] = min(abs(row['lb']), abs(row['ub']))
      row['abs_ub'] = max(abs(row['lb']), abs(row['ub']))
  
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
    if index in SPECIAL:
      bstyle['LineWidth'] *= 2
      bstyle['Color'] = 'k'
      estyle['MarkerSize'] *= 3
      estyle['Color'] = 'k'
      estyle['MarkerEdgeColor'] = 'k'
    ax.plot([row['lb'], row['ub']], [y, y], **bstyle)
    ax.plot([row['est']], [y], **estyle)
    y += 1
  ax.axvline(0, color='k')
  plt.yticks(range(plot_df.shape[0]))
  ax.set_ylim(-0.5, y - 0.5)
  ax.set_yticklabels(plot_df.index.values)
  plt.xlabel('coefficient')
  plt.savefig(saveto, bbox_inches='tight')

# Just copy-paste the output of the GLMM's merModel coeff matrix here to make plots 'n stuff.

doplot('alzheim.png', """
diab          3.2880     1.5568   2.112   0.0347 *  
age           5.9184     0.5766  10.264   <2e-16 ***
BMI           0.4437     0.5095   0.871   0.3838    
diab:age     -1.4602     0.6825  -2.139   0.0324 *  
diab:BMI      0.2514     0.6825   0.368   0.7126 
""", ["diab"])
doplot('parkinson.png', """
age           2.6531     0.3455   7.679  1.6e-14 ***
diab         -0.3667     0.9927  -0.369    0.712    
race         -0.1168     0.2910  -0.401    0.688    
age:diab      0.2613     0.4817   0.542    0.588
""")
doplot('als.png', """
age           0.7319     0.6357   1.151    0.250    
diab          0.1198     1.2950   0.092    0.926    
BMI          -0.2941     0.6626  -0.444    0.657    
age:diab      0.2938     0.8519   0.345    0.730 
""")
doplot('ms.png', """
age          -0.6822     0.4228  -1.614    0.107    
diab          0.3618     0.8617   0.420    0.675    
age:diab     -0.1998     0.5440  -0.367    0.713
""")
doplot('ndds.png', """
age           2.2920     0.2109  10.865   <2e-16 ***
diab          0.8568     0.4985   1.719   0.0857 .  
age:diab     -0.5018     0.2726  -1.841   0.0656 .  
""")
doplot('aim3.png', """
age                   3.72087    0.58091   6.405  1.5e-10 ***
biguanides           -4.43157    3.16283  -1.401   0.1612    
sulfonylurea         -0.04499    2.28226  -0.020   0.9843    
age:biguanides        2.53527    1.44463   1.755   0.0793 .  
age:sulfonylurea      0.13612    1.06487   0.128   0.8983    
""", ['biguanides', 'age:biguanides'], (8, 2))
