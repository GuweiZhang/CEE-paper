import argparse
from pathlib import Path

import numpy as np
import pandas as pd
from netCDF4 import Dataset

def nc_array(ds, name):
    a = ds.variables[name][:]
    if np.ma.isMaskedArray(a):
        a = a.filled(np.nan)
    return np.asarray(a, dtype=np.float64)

def text_values(ds, name):
    a = ds.variables[name][:]
    if np.ma.isMaskedArray(a):
        a = a.filled("")
    out = []
    for x in np.asarray(a):
        if isinstance(x, bytes):
            out.append(x.decode("utf-8"))
        else:
            out.append(str(x))
    return out

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", default="Figure4_plot_data.nc")
    parser.add_argument("--output", default="Supplementary_Table_factor_order_sensitivity.csv")
    parser.add_argument("--all-regions", action="store_true")
    args = parser.parse_args()

    with Dataset(args.input, "r") as ds:
        state = nc_array(ds, "state_point")
        states = text_values(ds, "state")
        scenarios = text_values(ds, "scenario")
        pop_types = text_values(ds, "pop_type")
        regions = text_values(ds, "region_display_name") if "region_display_name" in ds.variables else text_values(ds, "region")

    required = ["M00", "M10", "M01", "M11"]
    idx = {}
    for name in required:
        if name not in states:
            raise ValueError(f"{name} is missing from state coordinate")
        idx[name] = states.index(name)

    region_indices = list(range(len(regions))) if args.all_regions else [regions.index("China")]

    rows = []

    for ir in region_indices:
        for issp, scenario in enumerate(scenarios):
            for ip, pop_type in enumerate(pop_types):
                m00 = state[ir, issp, ip, idx["M00"]]
                m10 = state[ir, issp, ip, idx["M10"]]
                m01 = state[ir, issp, ip, idx["M01"]]
                m11 = state[ir, issp, ip, idx["M11"]]

                climate_first = m10 - m00
                population_second = m11 - m10
                population_first = m01 - m00
                climate_second = m11 - m01

                climate_symmetric = 0.5 * (climate_first + climate_second)
                population_symmetric = 0.5 * (population_first + population_second)
                total_change = m11 - m00
                closure = climate_symmetric + population_symmetric - total_change

                rows.append(
                    {
                        "region": regions[ir],
                        "scenario": scenario,
                        "population_type": pop_type,
                        "total_change_deaths_per_year": total_change,
                        "climate_if_climate_first": climate_first,
                        "population_if_population_second": population_second,
                        "population_if_population_first": population_first,
                        "climate_if_climate_second": climate_second,
                        "symmetric_climate": climate_symmetric,
                        "symmetric_population": population_symmetric,
                        "symmetric_closure_error": closure,
                    }
                )

    out = pd.DataFrame(rows)
    if np.nanmax(np.abs(out["symmetric_closure_error"])) > 1.0e-8:
        raise ValueError("Symmetric decomposition closure failed")

    Path(args.output).parent.mkdir(parents=True, exist_ok=True)
    out.to_csv(args.output, index=False)

    display = out[
        [
            "region",
            "scenario",
            "population_type",
            "total_change_deaths_per_year",
            "symmetric_climate",
            "symmetric_population",
        ]
    ].copy()

    display_path = str(Path(args.output).with_name(Path(args.output).stem + "_compact.csv"))
    display.to_csv(display_path, index=False)

    print(args.output)
    print(display_path)

if __name__ == "__main__":
    main()
