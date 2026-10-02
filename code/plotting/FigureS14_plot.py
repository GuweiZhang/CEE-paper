pass
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import pandas as pd
import numpy as np

d=pd.read_csv('FigureS14_RR.csv')
regions=['NE','NC','NW','EC','CC','SC']
fig,axes=plt.subplots(1,3,figsize=(12,3.6),sharey=True,layout='constrained')
for ax,category,label in zip(axes,['Storm rain','Heavy rain','Moderate rain'],'abc'):
    x=d[d.category==category].set_index('region').loc[regions]
    ax.bar(regions,x.RR,color='#858585',width=.55)
    ax.errorbar(np.arange(6),x.RR,yerr=np.vstack([x.RR-x.lower95,x.upper95-x.RR]),fmt='none',color='black',capsize=3,lw=1)
    ax.axhline(1,color='black',ls='--',lw=.8)
    ax.set_title(f'{label}. {category}',loc='left',fontsize=12)
    ax.set_ylim(0,2.9)
    ax.spines[['top','right']].set_visible(False)
axes[0].set_ylabel('Cumulative relative risk (lag 0–14)')
fig.savefig('FigureS14.png',dpi=300)
fig.savefig('FigureS14.pdf')
