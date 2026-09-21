import argparse
from pathlib import Path

import numpy as np
import pandas as pd
from netCDF4 import Dataset

RR_STORM_MEAN = np.array([1.147, 1.211, 1.021, 1.021, 1.295, 1.254], dtype=np.float64)
REGION_NAMES = ["NE", "NC", "NW", "EC", "CC", "SC"]
POP_NAMES = ["Total", "Urban"]
MODEL_NAMES = ["MPI", "CESM2", "IPSL"]
SCENARIOS = ["126", "245", "585"]
SCENARIO_NAMES = {"126": "SSP1-2.6", "245": "SSP2-4.5", "585": "SSP5-8.5"}

def nc_array(ds, name):
    a = ds.variables[name][:]
    if np.ma.isMaskedArray(a):
        a = a.filled(np.nan)
    return np.asarray(a, dtype=np.float64)

def storm_basis(ds, pop_index):
    death = nc_array(ds, "region_deaths_point")[pop_index]
    if death.ndim != 4:
        raise ValueError(f"region_deaths_point must be 5-D before selecting population type; got {death.shape}")
    if death.shape[-2] < 7 or death.shape[-1] < 1:
        raise ValueError(f"Unexpected region/category dimensions: {death.shape}")
    storm_death = death[:, :, 1:7, 0]
    af = (RR_STORM_MEAN - 1.0) / RR_STORM_MEAN
    out = np.empty_like(storm_death, dtype=np.float64)
    for r in range(6):
        if abs(af[r]) <= 1.0e-15:
            raise ValueError(f"Storm AF is zero for region {REGION_NAMES[r]}")
        out[:, :, r] = storm_death[:, :, r] / af[r]
    return np.mean(out, axis=1)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--mortality-dir", default="CWRF_mortality")
    parser.add_argument("--output", default="FigureS9_storm_only_basis.csv")
    args = parser.parse_args()

    root = Path(args.mortality_dir)
    hist_path = root / "CWRF_mortality_hist_1995-2014.nc"
    future_paths = {
        s: root / f"CWRF_mortality_ssp{s}_2031-2060.nc"
        for s in SCENARIOS
    }

    for path in [hist_path] + list(future_paths.values()):
        if not path.exists():
            raise FileNotFoundError(path)

    rows = []

    with Dataset(hist_path, "r") as hist_ds:
        hist_basis = {
            p: storm_basis(hist_ds, p)
            for p in range(2)
        }

    for scenario in SCENARIOS:
        with Dataset(future_paths[scenario], "r") as fut_ds:
            fut_basis = {
                p: storm_basis(fut_ds, p)
                for p in range(2)
            }

        for p, pop_name in enumerate(POP_NAMES):
            for im, model in enumerate(MODEL_NAMES):
                for ir, region in enumerate(REGION_NAMES):
                    rows.append(
                        {
                            "population_type": pop_name,
                            "scenario": SCENARIO_NAMES[scenario],
                            "period": "Historical",
                            "model": model,
                            "region": region,
                            "storm_exposure_basis_deaths_per_year": hist_basis[p][im, ir],
                        }
                    )
                    rows.append(
                        {
                            "population_type": pop_name,
                            "scenario": SCENARIO_NAMES[scenario],
                            "period": "Future",
                            "model": model,
                            "region": region,
                            "storm_exposure_basis_deaths_per_year": fut_basis[p][im, ir],
                        }
                    )

    out = pd.DataFrame(rows)
    if not np.all(np.isfinite(out["storm_exposure_basis_deaths_per_year"])):
        raise ValueError("Non-finite values found in public basis output")

    Path(args.output).parent.mkdir(parents=True, exist_ok=True)
    out.to_csv(args.output, index=False)

    qc = (
        out.groupby(["population_type", "scenario", "period"])["storm_exposure_basis_deaths_per_year"]
        .agg(["count", "min", "max", "mean"])
        .reset_index()
    )
    qc_path = str(Path(args.output).with_name(Path(args.output).stem + "_QC.csv"))
    qc.to_csv(qc_path, index=False)

    print(args.output)
    print(qc_path)
    print("This file contains regional, model-aggregated sufficient statistics only.")
    print("Review the applicable data-use agreement before public release.")

if __name__ == "__main__":
    main()
