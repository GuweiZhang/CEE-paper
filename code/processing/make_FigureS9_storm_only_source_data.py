import argparse
from pathlib import Path

import numpy as np
import pandas as pd
from netCDF4 import Dataset

RR_STORM_MEAN = np.array([1.147, 1.211, 1.021, 1.021, 1.295, 1.254], dtype=np.float64)
RR_STORM_LOW = np.array([0.647, 0.770, 0.436, 0.746, 0.825, 0.590], dtype=np.float64)
RR_STORM_HIGH = np.array([2.034, 1.906, 2.389, 1.396, 2.034, 2.665], dtype=np.float64)
REGION_NAMES = ["China", "NE", "NC", "NW", "EC", "CC", "SC"]
SUBREGIONS = ["NE", "NC", "NW", "EC", "CC", "SC"]
SCENARIOS = ["SSP1-2.6", "SSP2-4.5", "SSP5-8.5"]
POP_NAMES = ["Total", "Urban"]
MODEL_NAMES = ["MPI", "CESM2", "IPSL"]

def safe_divide(a, b):
    a, b = np.broadcast_arrays(np.asarray(a, dtype=np.float64), np.asarray(b, dtype=np.float64))
    out = np.full(a.shape, np.nan, dtype=np.float64)
    valid = np.isfinite(a) & np.isfinite(b) & (np.abs(b) > 1.0e-15)
    out[valid] = a[valid] / b[valid]
    return out

def af_draws(n, seed):
    rng = np.random.default_rng(seed)
    se = (np.log(RR_STORM_HIGH) - np.log(RR_STORM_LOW)) / (2.0 * 1.96)
    rr = np.exp(rng.normal(np.log(RR_STORM_MEAN), se, size=(n, 6)))
    return (rr - 1.0) / rr

def load_basis(path, population_type, scenario):
    df = pd.read_csv(path)
    sub = df[
        (df["population_type"] == population_type)
        & (df["scenario"] == scenario)
    ].copy()

    expected = 2 * len(MODEL_NAMES) * len(SUBREGIONS)
    if len(sub) != expected:
        raise ValueError(f"Expected {expected} rows for {population_type} {scenario}, got {len(sub)}")

    arrays = {}
    for period in ["Historical", "Future"]:
        a = np.full((len(MODEL_NAMES), 6), np.nan, dtype=np.float64)
        p = sub[sub["period"] == period]
        for im, model in enumerate(MODEL_NAMES):
            for ir, region in enumerate(SUBREGIONS):
                hit = p[(p["model"] == model) & (p["region"] == region)]
                if len(hit) != 1:
                    raise ValueError(f"Missing or duplicated basis for {population_type} {scenario} {period} {model} {region}")
                a[im, ir] = float(hit.iloc[0]["storm_exposure_basis_deaths_per_year"])
        arrays[period] = a
    return arrays["Historical"], arrays["Future"]

def storm_only_relative_change(hist_basis, fut_basis, n_mc, seed):
    af_point = (RR_STORM_MEAN - 1.0) / RR_STORM_MEAN

    hist_reg = hist_basis * af_point[None, :]
    fut_reg = fut_basis * af_point[None, :]

    hist_point = np.empty(7, dtype=np.float64)
    fut_point = np.empty(7, dtype=np.float64)
    hist_point[1:] = np.mean(hist_reg, axis=0)
    fut_point[1:] = np.mean(fut_reg, axis=0)
    hist_point[0] = np.sum(hist_point[1:])
    fut_point[0] = np.sum(fut_point[1:])
    point = safe_divide(fut_point, hist_point) * 100.0 - 100.0

    draws = af_draws(n_mc, seed)
    hist_draw = draws[:, None, :] * hist_basis[None, :, :]
    fut_draw = draws[:, None, :] * fut_basis[None, :, :]

    hist7 = np.empty((n_mc, len(MODEL_NAMES), 7), dtype=np.float64)
    fut7 = np.empty((n_mc, len(MODEL_NAMES), 7), dtype=np.float64)
    hist7[:, :, 1:] = hist_draw
    fut7[:, :, 1:] = fut_draw
    hist7[:, :, 0] = np.sum(hist_draw, axis=2)
    fut7[:, :, 0] = np.sum(fut_draw, axis=2)

    ratio = safe_divide(fut7, hist7) * 100.0 - 100.0
    flat = ratio.reshape(-1, 7)
    low = np.nanquantile(flat, 0.025, axis=0)
    high = np.nanquantile(flat, 0.975, axis=0)

    return point, low, high

def read_main_analysis(path, variable_name):
    with Dataset(path, "r") as ds:
        a = ds.variables[variable_name][:]
        if np.ma.isMaskedArray(a):
            a = a.filled(np.nan)
        a = np.asarray(a, dtype=np.float64)
    if a.shape != (3, 3, 7):
        raise ValueError(f"Unexpected main-analysis shape {a.shape} in {path}")
    return a - 100.0

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--basis", default="FigureS9_storm_only_basis.csv")
    parser.add_argument("--figure2", default="Figure2_plot_data.nc")
    parser.add_argument("--figures8", default="FigureS8_plot_data.nc")
    parser.add_argument("--output", default="FigureS9_storm_only_source_data.csv")
    parser.add_argument("--n-mc", type=int, default=1000)
    parser.add_argument("--seed", type=int, default=20260811)
    args = parser.parse_args()

    main_total = read_main_analysis(args.figure2, "c_ratio0_plot")
    main_urban = read_main_analysis(args.figures8, "c_ratio0")

    rows = []

    for p, pop_name in enumerate(POP_NAMES):
        main_data = main_total if pop_name == "Total" else main_urban

        for issp, scenario in enumerate(SCENARIOS):
            for ir, region in enumerate(REGION_NAMES):
                rows.append(
                    {
                        "population_type": pop_name,
                        "scenario": scenario,
                        "region": region,
                        "analysis": "Main HRRD",
                        "point_percent": main_data[issp, 0, ir],
                        "lower95_percent": main_data[issp, 1, ir],
                        "upper95_percent": main_data[issp, 2, ir],
                    }
                )

            hist_basis, fut_basis = load_basis(args.basis, pop_name, scenario)
            point, low, high = storm_only_relative_change(hist_basis, fut_basis, args.n_mc, args.seed)

            for ir, region in enumerate(REGION_NAMES):
                rows.append(
                    {
                        "population_type": pop_name,
                        "scenario": scenario,
                        "region": region,
                        "analysis": "Storm-only",
                        "point_percent": point[ir],
                        "lower95_percent": low[ir],
                        "upper95_percent": high[ir],
                    }
                )

    out = pd.DataFrame(rows)
    out["interval_definition"] = "2.5th-97.5th percentiles across paired RR draws and three CWRF climate members"
    out["storm_only_definition"] = "storm rain >=50 mm d-1 in all six regions"

    Path(args.output).parent.mkdir(parents=True, exist_ok=True)
    out.to_csv(args.output, index=False)

    qc = out.copy()
    qc["contains_point"] = (
        (qc["point_percent"] >= qc["lower95_percent"])
        & (qc["point_percent"] <= qc["upper95_percent"])
    )
    qc_path = str(Path(args.output).with_name(Path(args.output).stem + "_QC.csv"))
    qc.to_csv(qc_path, index=False)

    print(args.output)
    print(qc_path)

if __name__ == "__main__":
    main()
