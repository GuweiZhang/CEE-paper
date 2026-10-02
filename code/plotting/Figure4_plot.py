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
plt.rcParams['axes.linewidth'] = 2.0
plt.rcParams['xtick.major.width'] = 2.0
plt.rcParams['ytick.major.width'] = 2.0
plt.rcParams['font.size'] = 12
plt.rcParams['xtick.labelsize'] = 25
plt.rcParams['ytick.labelsize'] = 25

target_regions = ["china", "northeast", "north", "northwest", "east", "central", "sc"]
display_names = {
    "china": "China",
    "northeast": "NE",
    "north": "NC",
    "northwest": "NW",
    "east": "EC",
    "central": "CC",
    "sc": "SC",
}
scenarios = ["SSP1-2.6", "SSP2-4.5", "SSP5-8.5"]
pop_types = ["Total", "Urban"]

components = [
    ("abs_clim", "Climate"),
    ("abs_pop_size", "Population size"),
    ("abs_redistribution", "Redistribution"),
    ("abs_interaction", "Interaction"),
]

colors = {
    "Total": {
        "abs_clim": "#1874cd",
        "abs_pop_size": "#cd0000",
        "abs_redistribution": "#ee9a00",
        "abs_interaction": "#7f7f7f",
        "marker": "black",
    },
    "Urban": {
        "abs_clim": "#a4d3ee",
        "abs_pop_size": "pink",
        "abs_redistribution": "#fdd49e",
        "abs_interaction": "gainsboro",
        "marker": "dimgray",
    },
}

ds = xr.open_dataset("Figure4_plot_data.nc")

fig, axes = plt.subplots(nrows=2, ncols=4, figsize=(22, 11), sharey=True, sharex=False)
axes_flat = axes.flatten()

bar_height = 0.23
offset_total = 0.13
offset_urban = -0.13

for r_idx, region in enumerate(target_regions):
    ax = axes_flat[r_idx]

    for spine in ax.spines.values():
        spine.set_visible(True)
        spine.set_edgecolor('black')
        spine.set_linewidth(1.5)

    ax.plot([0, 0], [-0.5, 2.5], color='black', linewidth=1.5, zorder=4)
    ax.set_ylim(-0.5, 3.0)
    ax.set_yticks([0, 1, 2])
    ax.set_yticklabels(scenarios, fontweight='bold')

    ax.axhspan(2.5, 3.0, facecolor='#bfbfbf', edgecolor='black', linewidth=1.0, zorder=1)

    trans = transforms.blended_transform_factory(ax.transAxes, ax.transData)
    ax.text(0.03, 2.75, display_names[region], transform=trans,
            fontweight='bold', fontsize=30, va='center', ha='left', zorder=5)

    for s_idx, ssp in enumerate(scenarios):
        for pop_type in pop_types:
            vals = {}
            for var_name, _ in components:
                vals[var_name] = ds[var_name].sel(region=region, scenario=ssp, pop_type=pop_type).item()
            val_total = ds['abs_total'].sel(region=region, scenario=ssp, pop_type=pop_type).item()

            if np.isnan(val_total):
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

            ax.scatter(val_total, y_pos, color=c_dict['marker'], marker='D', s=100,
                       edgecolors='white', linewidths=0.6, zorder=4)

    ax.xaxis.set_major_formatter(ticker.FuncFormatter(lambda x, p: format(int(x), ',')))

ax_legend = axes[1, 3]
ax_legend.axis('off')

x_label_text = 'Change in Annual Deaths (persons)'

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
                  markersize=16, label='Net Change (Total)'),
    mlines.Line2D([], [], color='white', marker='D', markerfacecolor=colors['Urban']['marker'],
                  markersize=16, label='Net Change (Urban)')
]

ax_legend.legend(handles=legend_elements, loc='center', ncol=1, frameon=False, fontsize=20, borderpad=0)

fig.supxlabel(x_label_text, fontsize=20, fontweight='bold')
plt.tight_layout(w_pad=2.2, h_pad=2.0, rect=(0,0.04,1,1))
output_filename = "Figure4.png"
plt.savefig(output_filename, format='png', dpi=600, bbox_inches='tight', facecolor='white', transparent=False)
