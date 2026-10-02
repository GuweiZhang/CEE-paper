import xarray as xr
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
import matplotlib.lines as mlines
import matplotlib.ticker as ticker
import matplotlib.transforms as transforms

plt.rcParams['font.family'] = 'serif'
plt.rcParams['font.serif'] = ['DejaVu Serif', 'Liberation Serif', 'DejaVu Serif', 'Times'] + plt.rcParams['font.serif']
plt.rcParams['axes.linewidth'] = 1.5
plt.rcParams['xtick.major.width'] = 1.5
plt.rcParams['ytick.major.width'] = 1.5
plt.rcParams['font.size'] = 18
plt.rcParams['xtick.labelsize'] = 22
plt.rcParams['ytick.labelsize'] = 22

ds = xr.open_dataset("FigureS10_plot_data.nc")
provinces_32 = ds['province'].values.astype(str)
scenarios = ds['scenario'].values.astype(str)
pop_types = ds['pop_type'].values.astype(str)

display_names = {p: p for p in provinces_32}
display_names["Guangdong, Hong Kong & Macao"] = "Guangdong, Hong Kong, Macao"
display_names["Inner Mongolia"] = "Inner Mongolia"

components = [
    ("abs_clim", "Climate"),
    ("abs_pop_size", "Population size"),
    ("abs_redistribution", "Redistribution"),
    ("abs_interaction", "Interaction"),
]

colors = {
    'Total': {
        'abs_clim': '#1874cd',
        'abs_pop_size': '#cd0000',
        'abs_redistribution': '#ee9a00',
        'abs_interaction': '#7f7f7f',
        'marker': 'black'
    },
    'Urban': {
        'abs_clim': '#a4d3ee',
        'abs_pop_size': 'pink',
        'abs_redistribution': '#fdd49e',
        'abs_interaction': 'gainsboro',
        'marker': 'dimgray'
    }
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
            vals = {}
            for var_name, _ in components:
                vals[var_name] = ds[var_name].isel(province=idx, scenario=s_idx, pop_type=p_idx).item()
            abs_total = ds['abs_total'].isel(province=idx, scenario=s_idx, pop_type=p_idx).item()

            if np.isnan(abs_total):
                continue

            y_pos = s_idx + (offset_total if pop_type == 'Total' else offset_urban)
            c_dict = colors[pop_type]
            pos_offset = 0.0
            neg_offset = 0.0

            for var_name, _ in components:
                val = vals[var_name]
                if np.isnan(val):
                    continue
                if val >= 0:
                    ax.barh(y_pos, val, left=pos_offset, color=c_dict[var_name], height=bar_height,
                            edgecolor='white', linewidth=0.3, zorder=3)
                    pos_offset += val
                else:
                    ax.barh(y_pos, val, left=neg_offset, color=c_dict[var_name], height=bar_height,
                            edgecolor='white', linewidth=0.3, zorder=3)
                    neg_offset += val

            ax.scatter(abs_total, y_pos, color=c_dict['marker'], marker='D', s=100,
                       edgecolors='white', linewidths=0.6, zorder=5)

    ax.xaxis.set_major_locator(ticker.MaxNLocator(nbins=4))
    xlim_min, xlim_max = ax.get_xlim()
    max_abs = max(abs(xlim_min), abs(xlim_max))

    if max_abs > 0:
        ax.set_xlim(-max_abs * 1.2, max_abs * 1.2)
        max_val = max_abs * 1.2
        if max_val < 0.02:
            ax.xaxis.set_major_formatter(ticker.FuncFormatter(lambda x, p: f"{x:.3f}"))
        elif max_val < 0.1:
            ax.xaxis.set_major_formatter(ticker.FuncFormatter(lambda x, p: f"{x:.2f}"))
        elif max_val < 1.0:
            ax.xaxis.set_major_formatter(ticker.FuncFormatter(lambda x, p: f"{x:.1f}"))
        else:
            ax.xaxis.set_major_formatter(ticker.FuncFormatter(lambda x, p: format(int(round(x)), ',')))

    ax.tick_params(axis='x', pad=5)

    if idx in [27, 28, 29, 30, 31]:
        ax.set_xlabel('')

axes_flat[32].axis('off')
axes_flat[33].axis('off')
axes_flat[34].axis('off')

legend_elements = [
    mpatches.Patch(color=colors['Total']['abs_pop_size'], label='Population size (Total)'),
    mpatches.Patch(color=colors['Urban']['abs_pop_size'], label='Population size (Urban)'),
    mpatches.Patch(color=colors['Total']['abs_redistribution'], label='Redistribution (Total)'),
    mpatches.Patch(color=colors['Urban']['abs_redistribution'], label='Redistribution (Urban)'),
    mpatches.Patch(color=colors['Total']['abs_clim'], label='Climate (Total)'),
    mpatches.Patch(color=colors['Urban']['abs_clim'], label='Climate (Urban)'),
    mpatches.Patch(color=colors['Total']['abs_interaction'], label='Interaction (Total)'),
    mpatches.Patch(color=colors['Urban']['abs_interaction'], label='Interaction (Urban)'),
    mlines.Line2D([], [], color='white', marker='D', markerfacecolor=colors['Total']['marker'],
                  markersize=14, label='Net Change (Total)'),
    mlines.Line2D([], [], color='white', marker='D', markerfacecolor=colors['Urban']['marker'],
                  markersize=14, label='Net Change (Urban)')
]

fig.supxlabel('Change in annual deaths (persons)', fontsize=24, fontweight='bold')
plt.tight_layout(w_pad=2.0, h_pad=1.5, rect=(0,0.02,1,1))

leg = axes_flat[33].legend(handles=legend_elements, loc='center', ncol=2,
                           frameon=True, edgecolor='black', fontsize=20, borderpad=1.2)
leg.get_frame().set_linewidth(1.5)

output_filename = "FigureS10.png"
plt.savefig(output_filename, dpi=600, bbox_inches='tight')
