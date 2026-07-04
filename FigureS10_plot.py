import xarray as xr
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
import matplotlib.lines as mlines
import matplotlib.ticker as ticker
import matplotlib.transforms as transforms

plt.rcParams['font.family'] = 'serif'
plt.rcParams['font.serif'] = ['Times New Roman', 'Liberation Serif', 'DejaVu Serif', 'Times'] + plt.rcParams['font.serif']
plt.rcParams['axes.linewidth'] = 1.5
plt.rcParams['xtick.major.width'] = 1.5
plt.rcParams['ytick.major.width'] = 1.5
plt.rcParams['font.size'] = 18
plt.rcParams['xtick.labelsize'] = 22  
plt.rcParams['ytick.labelsize'] = 22  

ds = xr.open_dataset("FigureS10_plot_data.nc")
provinces_32 = ds['region'].values
scenarios = ds['scenario'].values
pop_types = ds['pop_type'].values

display_names = {p: p.capitalize() for p in provinces_32}
display_names["Guangdong"] = "Guangdong, Hong Kong, Macao"
display_names["Inner Mongolia"] = "Inner Mongolia"

colors = {
    'Total': {'Abs_Pop': '#cd0000', 'Abs_Clim': '#1874cd', 'Abs_Syn': '#7f7f7f', 'Marker': 'black'},
    'Urban': {'Abs_Pop': 'pink', 'Abs_Clim': '#a4d3ee', 'Abs_Syn': 'gainsboro', 'Marker': 'dimgray'}
}

fig, axes = plt.subplots(nrows=7, ncols=5, figsize=(25, 33), sharey=True, sharex=False)
axes_flat = axes.flatten()

bar_height = 0.25
offset_total = 0.15
offset_urban = -0.15

for idx, region in enumerate(provinces_32):
    ax = axes_flat[idx]
    
    for spine in ax.spines.values():
        spine.set_visible(True)
        spine.set_edgecolor('black')
        spine.set_linewidth(1.5)
        
    ax.plot([0, 0], [-0.5, 2.5], color='black', linewidth=1.5, zorder=4)
    ax.set_ylim(-0.5, 3.0)
    ax.set_yticks([0, 1, 2])
    
    if idx % 5 == 0:
        ax.set_yticklabels(scenarios, fontweight='bold')
    else:
        ax.tick_params(labelleft=False)
        
    ax.axhspan(2.5, 3.0, facecolor='#EAEAEA', edgecolor='black', linewidth=1.5, zorder=1)
    
    trans = transforms.blended_transform_factory(ax.transAxes, ax.transData)
    font_s = 20 if len(display_names[region]) > 14 else 26
    ax.text(0.03, 2.75, display_names[region], transform=trans, 
            fontweight='bold', fontsize=font_s, va='center', ha='left', zorder=5)
    
    for s_idx, ssp in enumerate(scenarios):
        for p_idx, pop_type in enumerate(pop_types):
            abs_clim = ds['abs_clim'].isel(region=idx, scenario=s_idx, pop_type=p_idx).item()
            abs_pop = ds['abs_pop'].isel(region=idx, scenario=s_idx, pop_type=p_idx).item()
            abs_syn = ds['abs_syn'].isel(region=idx, scenario=s_idx, pop_type=p_idx).item()
            abs_total = ds['abs_total'].isel(region=idx, scenario=s_idx, pop_type=p_idx).item()
            
            if np.isnan(abs_total):
                continue
                
            y_pos = s_idx + (offset_total if pop_type == 'Total' else offset_urban)
            c_dict = colors[pop_type]
            pos_offset, neg_offset = 0.0, 0.0
            
            for factor, val in [('Abs_Clim', abs_clim), ('Abs_Pop', abs_pop), ('Abs_Syn', abs_syn)]:
                if np.isnan(val): continue
                if val >= 0:
                    ax.barh(y_pos, val, left=pos_offset, color=c_dict[factor], height=bar_height, edgecolor='white', linewidth=0.3, zorder=3)
                    pos_offset += val
                else:
                    ax.barh(y_pos, val, left=neg_offset, color=c_dict[factor], height=bar_height, edgecolor='white', linewidth=0.3, zorder=3)
                    neg_offset += val
            
            ax.scatter(abs_total, y_pos, color=c_dict['Marker'], marker='D', s=100, edgecolors='white', linewidths=0.6, zorder=5)

    ax.xaxis.set_major_locator(ticker.MaxNLocator(nbins=4))
    xlim_min, xlim_max = ax.get_xlim()
    max_abs = max(abs(xlim_min), abs(xlim_max))
    
    if max_abs > 0:
        ax.set_xlim(-max_abs * 1.2, max_abs * 1.2)
        max_val = max_abs * 1.2  
        if max_val < 0.02:
            ax.xaxis.set_major_formatter(ticker.FuncFormatter(lambda x, p: f"{x:.3f}"))
        elif max_val < 0.01:
            ax.xaxis.set_major_formatter(ticker.FuncFormatter(lambda x, p: f"{x:.3f}"))
        elif max_val < 0.1:
            ax.xaxis.set_major_formatter(ticker.FuncFormatter(lambda x, p: f"{x:.2f}"))
        elif max_val < 1.0:
            ax.xaxis.set_major_formatter(ticker.FuncFormatter(lambda x, p: f"{x:.1f}"))
        else:
            ax.xaxis.set_major_formatter(ticker.FuncFormatter(lambda x, p: format(int(round(x)), ',')))
    
    ax.tick_params(axis='x', pad=5)
    
    if idx in [27, 28, 29, 30, 31]:
        ax.set_xlabel('Change in Annual Deaths', fontweight='bold', fontsize=20, labelpad=8)

axes_flat[32].axis('off')
axes_flat[33].axis('off')
axes_flat[34].axis('off')

legend_elements = [
    mpatches.Patch(color=colors['Total']['Abs_Pop'], label='Demographic (Total)'),
    mpatches.Patch(color=colors['Urban']['Abs_Pop'], label='Demographic (Urban)'),
    mpatches.Patch(color=colors['Total']['Abs_Clim'], label='Climate (Total)'),
    mpatches.Patch(color=colors['Urban']['Abs_Clim'], label='Climate (Urban)'),
    mpatches.Patch(color=colors['Total']['Abs_Syn'], label='Interaction  (Total)'),
    mpatches.Patch(color=colors['Urban']['Abs_Syn'], label='Interaction  (Urban)'),
    mlines.Line2D([], [], color='white', marker='D', markerfacecolor=colors['Total']['Marker'], markersize=14, label='Net Change (Total)'),
    mlines.Line2D([], [], color='white', marker='D', markerfacecolor=colors['Urban']['Marker'], markersize=14, label='Net Change (Urban)')
]

plt.tight_layout(w_pad=2.0, h_pad=1.5)

leg = axes_flat[33].legend(handles=legend_elements, loc='center', ncol=2, 
                           frameon=True, edgecolor='black', fontsize=22, borderpad=1.2)
leg.get_frame().set_linewidth(1.5)

output_filename = "FigureS10.png"
plt.savefig(output_filename, dpi=600, bbox_inches='tight')
