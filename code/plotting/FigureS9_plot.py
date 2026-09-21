import argparse

import matplotlib
matplotlib.use("Agg")
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from matplotlib.lines import Line2D

FONT_FAMILY = "DejaVu Serif"
FIG_WIDTH = 9.5
FIG_HEIGHT = 10.2
DPI = 400

MARKER_SIZE = 7.0
MARKER_EDGE_WIDTH = 1.1
ERROR_LINE_WIDTH = 0.9
CAP_SIZE = 2.0
AXIS_LINE_WIDTH = 0.8
TICK_WIDTH = 0.8

TITLE_FONT_SIZE = 15
LABEL_FONT_SIZE = 14
TICK_FONT_SIZE = 12
LEGEND_FONT_SIZE = 15
PANEL_TITLE_X = 0.02
PANEL_TITLE_Y = 0.96

HRRD_COLOR = "black"
STORM_COLOR = "gray"

HRRD_MARKER = "o"
STORM_MARKER = "s"

HRRD_OFFSET = -0.12
STORM_OFFSET = 0.12

YMIN = -200
YMAX = 300
YTICK_STEP = 100

REGIONS = ["China", "NE", "NC", "NW", "EC", "CC", "SC"]
SCENARIOS = ["SSP1-2.6", "SSP2-4.5", "SSP5-8.5"]
POP_TYPES = ["Total", "Urban"]
PANEL_LABELS = ["a", "b", "c", "d", "e", "f"]

STYLE = {
    "HRRD": {
        "color": HRRD_COLOR,
        "marker": HRRD_MARKER,
        "label": "HRRD",
        "offset": HRRD_OFFSET,
    },
    "Storm-only": {
        "color": STORM_COLOR,
        "marker": STORM_MARKER,
        "label": "Storm-only",
        "offset": STORM_OFFSET,
    },
}

plt.rcParams["font.family"] = FONT_FAMILY
plt.rcParams["axes.linewidth"] = AXIS_LINE_WIDTH
plt.rcParams["xtick.major.width"] = TICK_WIDTH
plt.rcParams["ytick.major.width"] = TICK_WIDTH

def plot_method(ax, d, method):
    st = STYLE[method]
    x = np.arange(len(REGIONS), dtype=np.float64) + st["offset"]
    y = d["point_percent"].to_numpy(dtype=float)
    lo = d["lower95_percent"].to_numpy(dtype=float)
    hi = d["upper95_percent"].to_numpy(dtype=float)
    yerr = np.vstack([y - lo, hi - y])

    ax.errorbar(
        x,
        y,
        yerr=yerr,
        fmt=st["marker"],
        linestyle="none",
        color=st["color"],
        ecolor=st["color"],
        elinewidth=ERROR_LINE_WIDTH,
        capsize=CAP_SIZE,
        markersize=MARKER_SIZE,
        markerfacecolor=st["color"],
        markeredgecolor=st["color"],
        markeredgewidth=MARKER_EDGE_WIDTH,
        zorder=3,
    )

def panel(ax, df, scenario, pop_type):
    sub = df[
        (df["population_type"] == pop_type)
        & (df["scenario"] == scenario)
    ].copy()

    for method in ["HRRD", "Storm-only"]:
        d = sub[sub["analysis"] == method].set_index("region").loc[REGIONS]
        plot_method(ax, d, method)

    ax.axhline(0.0, linewidth=AXIS_LINE_WIDTH, color="black")
    ax.set_xticks(np.arange(len(REGIONS), dtype=np.float64))
    ax.set_xticklabels(REGIONS, fontsize=TICK_FONT_SIZE)
    ax.set_ylim(YMIN, YMAX)
    ax.set_yticks(np.arange(YMIN, YMAX + YTICK_STEP, YTICK_STEP))
    ax.tick_params(
    direction="out",
    labelsize=TICK_FONT_SIZE,
    labelbottom=True,
    labelleft=True
    )
    ax.margins(x=0.05)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", default="FigureS9_storm_only_source_data.csv")
    parser.add_argument("--output", default="FigureS9.eps")
    parser.add_argument("--png", default="FigureS9.png")
    args = parser.parse_args()

    df = pd.read_csv(args.input)
    df["analysis"] = df["analysis"].replace({"Main HRRD": "HRRD"})

    fig, axes = plt.subplots(3, 2, figsize=(FIG_WIDTH, FIG_HEIGHT), sharex=True, sharey=True)

    panel_idx = 0
    for i, scenario in enumerate(SCENARIOS):
        for j, pop_type in enumerate(POP_TYPES):
            ax = axes[i, j]
            panel(ax, df, scenario, pop_type)

            panel_title = f"{PANEL_LABELS[panel_idx]}. {scenario}_{pop_type}"
            ax.text(
                PANEL_TITLE_X,
                PANEL_TITLE_Y,
                panel_title,
                transform=ax.transAxes,
                ha="left",
                va="top",
                fontsize=TITLE_FONT_SIZE,
            )
            panel_idx += 1

            if j == 0:
                ax.set_ylabel("")
            else:
                ax.set_ylabel("")
            if i < 2:
                ax.set_xlabel("")
            else:
                ax.set_xlabel("Region", fontsize=LABEL_FONT_SIZE)

    handles = [
        Line2D(
            [0], [0],
            color=STYLE["HRRD"]["color"],
            marker=STYLE["HRRD"]["marker"],
            linestyle="none",
            markersize=MARKER_SIZE,
            markerfacecolor=STYLE["HRRD"]["color"],
            markeredgecolor=STYLE["HRRD"]["color"],
            label="HRRD",
        ),
        Line2D(
            [0], [0],
            color=STYLE["Storm-only"]["color"],
            marker=STYLE["Storm-only"]["marker"],
            linestyle="none",
            markersize=MARKER_SIZE,
            markerfacecolor=STYLE["Storm-only"]["color"],
            markeredgecolor=STYLE["Storm-only"]["color"],
            label="Storm-only",
        ),
    ]

    fig.legend(
        handles=handles,
        loc="lower center",
        ncol=2,
        frameon=False,
        bbox_to_anchor=(0.5, 0.01),
        fontsize=LEGEND_FONT_SIZE,
    )

    fig.supylabel("Change in attributable deaths (%)", fontsize=LABEL_FONT_SIZE)
    fig.tight_layout(rect=(0.035, 0.05, 1, 1))
    fig.savefig(args.output, bbox_inches="tight")
    fig.savefig(args.png, dpi=DPI, bbox_inches="tight")

    print(args.output)
    print(args.png)

if __name__ == "__main__":
    main()
