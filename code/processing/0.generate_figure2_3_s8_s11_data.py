import os
import csv
import argparse
import numpy as np
from netCDF4 import Dataset

SCENARIOS = ["126", "245", "585"]
REGION_NAMES = ["CN", "NE", "NC", "NW", "EC", "CC", "SC"]
STATE_NAMES = [
    "Heilongjiang",
    "Jilin",
    "Liaoning",
    "Beijing Shi",
    "Tianjin Shi",
    "Hebei",
    "Shanxi",
    "Nei Mongol",
    "Ningxia Huizu",
    "Shaanxi",
    "Gansu",
    "Qinghai",
    "Xinjiang Uygur",
    "Shandong",
    "Jiangsu",
    "Shanghai Shi",
    "Zhejiang",
    "Anhui",
    "Jiangxi",
    "Fujian",
    "Henan",
    "Hubei",
    "Hunan",
    "Chongqing Shi",
    "Sichuan",
    "Yunnan",
    "Guizhou",
    "Xizang",
    "Guangxi",
    "Guandong",
    "Hainan",
    "Hong kong",
    "Taiwan",
]
RR_STORM_MEAN = np.array([1.147, 1.211, 1.021, 1.021, 1.295, 1.254], dtype=np.float64)
RR_STORM_LOW = np.array([0.647, 0.770, 0.436, 0.746, 0.825, 0.590], dtype=np.float64)
RR_STORM_HIGH = np.array([2.034, 1.906, 2.389, 1.396, 2.034, 2.665], dtype=np.float64)
RR_HEAVY_MEAN = np.array([np.nan, np.nan, np.nan, np.nan, 1.051, 1.151], dtype=np.float64)
RR_HEAVY_LOW = np.array([np.nan, np.nan, np.nan, np.nan, 0.834, 0.958], dtype=np.float64)
RR_HEAVY_HIGH = np.array([np.nan, np.nan, np.nan, np.nan, 1.324, 1.384], dtype=np.float64)

def af_point():
    storm = (RR_STORM_MEAN - 1.0) / RR_STORM_MEAN
    heavy = np.zeros(6, dtype=np.float64)
    active = np.isfinite(RR_HEAVY_MEAN)
    heavy[active] = (RR_HEAVY_MEAN[active] - 1.0) / RR_HEAVY_MEAN[active]
    return storm, heavy

def af_draws(n, seed):
    rng = np.random.default_rng(seed)
    storm_se = (np.log(RR_STORM_HIGH) - np.log(RR_STORM_LOW)) / (2.0 * 1.96)
    storm_rr = np.exp(rng.normal(np.log(RR_STORM_MEAN), storm_se, size=(n, 6)))
    storm = (storm_rr - 1.0) / storm_rr
    heavy = np.zeros((n, 6), dtype=np.float64)
    active = np.isfinite(RR_HEAVY_MEAN)
    heavy_se = (np.log(RR_HEAVY_HIGH[active]) - np.log(RR_HEAVY_LOW[active])) / (2.0 * 1.96)
    heavy_rr = np.exp(rng.normal(np.log(RR_HEAVY_MEAN[active]), heavy_se, size=(n, int(active.sum()))))
    heavy[:, active] = (heavy_rr - 1.0) / heavy_rr
    return storm, heavy

def nc_array(ds, name):
    a = ds.variables[name][:]
    if np.ma.isMaskedArray(a):
        a = a.filled(np.nan)
    return np.asarray(a, dtype=np.float64)

def safe_divide(a, b):
    a, b = np.broadcast_arrays(np.asarray(a, dtype=np.float64), np.asarray(b, dtype=np.float64))
    out = np.full(a.shape, np.nan, dtype=np.float64)
    valid = np.isfinite(a) & np.isfinite(b) & (np.abs(b) > 1.0e-15)
    out[valid] = a[valid] / b[valid]
    return out

def state33_from_province32(a):
    a = np.asarray(a, dtype=np.float64)
    out = np.full(a.shape[:-1] + (33,), np.nan, dtype=np.float64)
    out[..., :31] = a[..., :31]
    out[..., 31] = a[..., 29]
    out[..., 32] = a[..., 31]
    return out

def region_base_exposure(ds, pop_type):
    death = nc_array(ds, "region_deaths_point")[pop_type]
    storm_af, heavy_af = af_point()
    nmodel, nyear = death.shape[:2]
    bs = np.zeros((nmodel, nyear, 6), dtype=np.float64)
    bh = np.zeros((nmodel, nyear, 6), dtype=np.float64)
    for r in range(6):
        bs[:, :, r] = death[:, :, r + 1, 0] / storm_af[r]
        if abs(heavy_af[r]) > 0:
            bh[:, :, r] = death[:, :, r + 1, 1] / heavy_af[r]
    return bs, bh

def region_point_total(ds, pop_type):
    return nc_array(ds, "region_deaths_point")[pop_type, :, :, :, 2]

def province_point_total(ds, pop_type):
    return nc_array(ds, "province_deaths_point")[pop_type, :, :, :, 2]

def region_population(ds, pop_type):
    return nc_array(ds, "region_population")[pop_type]

def province_population(ds, pop_type):
    return nc_array(ds, "province_population")[pop_type]

def paired_period_draws(bs, bh, storm_draw, heavy_draw):
    nmc = storm_draw.shape[0]
    nmodel = bs.shape[0]
    out = np.zeros((nmc, nmodel, 7), dtype=np.float64)
    for r in range(6):
        mean_bs = np.mean(bs[:, :, r], axis=1)
        mean_bh = np.mean(bh[:, :, r], axis=1)
        out[:, :, r + 1] = storm_draw[:, r, None] * mean_bs[None, :] + heavy_draw[:, r, None] * mean_bh[None, :]
    out[:, :, 0] = np.sum(out[:, :, 1:], axis=2)
    return out

def paired_window_draws(bs, bh, year_slice, storm_draw, heavy_draw):
    nmc = storm_draw.shape[0]
    nmodel = bs.shape[0]
    out = np.zeros((nmc, nmodel, 7), dtype=np.float64)
    for r in range(6):
        mean_bs = np.mean(bs[:, year_slice, r], axis=1)
        mean_bh = np.mean(bh[:, year_slice, r], axis=1)
        out[:, :, r + 1] = storm_draw[:, r, None] * mean_bs[None, :] + heavy_draw[:, r, None] * mean_bh[None, :]
    out[:, :, 0] = np.sum(out[:, :, 1:], axis=2)
    return out

def relative_change_data(hist_ds, future_ds, pop_type, storm_draw, heavy_draw):
    hist_bs, hist_bh = region_base_exposure(hist_ds, pop_type)
    fut_bs, fut_bh = region_base_exposure(future_ds, pop_type)
    hist_point = np.mean(region_point_total(hist_ds, pop_type), axis=(0, 1))
    fut_point = np.mean(region_point_total(future_ds, pop_type), axis=(0, 1))
    hist_pop = np.mean(region_population(hist_ds, pop_type), axis=0)
    fut_pop = np.mean(region_population(future_ds, pop_type), axis=0)
    death_ratio_point = safe_divide(fut_point, hist_point) * 100.0
    hist_rate_point = safe_divide(hist_point, hist_pop)
    fut_rate_point = safe_divide(fut_point, fut_pop)
    rate_ratio_point = safe_divide(fut_rate_point, hist_rate_point) * 100.0
    hist_draw = paired_period_draws(hist_bs, hist_bh, storm_draw, heavy_draw)
    fut_draw = paired_period_draws(fut_bs, fut_bh, storm_draw, heavy_draw)
    death_ratio_draw = safe_divide(fut_draw, hist_draw) * 100.0
    hist_rate_draw = safe_divide(hist_draw, hist_pop[None, None, :])
    fut_rate_draw = safe_divide(fut_draw, fut_pop[None, None, :])
    rate_ratio_draw = safe_divide(fut_rate_draw, hist_rate_draw) * 100.0
    death_flat = death_ratio_draw.reshape(-1, 7)
    rate_flat = rate_ratio_draw.reshape(-1, 7)
    death_low = np.nanquantile(death_flat, 0.025, axis=0)
    death_high = np.nanquantile(death_flat, 0.975, axis=0)
    rate_low = np.nanquantile(rate_flat, 0.025, axis=0)
    rate_high = np.nanquantile(rate_flat, 0.975, axis=0)
    death_result = np.stack([death_ratio_point, death_low, death_high], axis=0)
    rate_result = np.stack([rate_ratio_point, rate_low, rate_high], axis=0)
    return death_result, rate_result

def map_data(future_ds, pop_type):
    deaths = province_point_total(future_ds, pop_type)
    pop = province_population(future_ds, pop_type)
    period_death = np.mean(deaths, axis=(0, 1))
    period_pop = np.mean(pop, axis=0)
    period_rate = safe_divide(period_death, period_pop) * 1.0e6
    return state33_from_province32(period_death), state33_from_province32(period_rate)

def trajectory_data(future_ds, pop_type, storm_draw, heavy_draw):
    bs, bh = region_base_exposure(future_ds, pop_type)
    point = region_point_total(future_ds, pop_type)
    pop = region_population(future_ds, pop_type)
    dh0 = np.full((7, 6), np.nan, dtype=np.float64)
    dh1 = np.full((7, 6), np.nan, dtype=np.float64)
    dh2 = np.full((7, 6), np.nan, dtype=np.float64)
    dr0 = np.full((7, 6), np.nan, dtype=np.float64)
    dr1 = np.full((7, 6), np.nan, dtype=np.float64)
    dr2 = np.full((7, 6), np.nan, dtype=np.float64)
    for block in range(6):
        sl = slice(block * 5, block * 5 + 5)
        point_death = np.mean(point[:, sl, :], axis=(0, 1))
        period_pop = np.mean(pop[sl, :], axis=0)
        point_rate = safe_divide(point_death, period_pop)
        draws = paired_window_draws(bs, bh, sl, storm_draw, heavy_draw)
        flat_death = draws.reshape(-1, 7)
        flat_rate = safe_divide(draws, period_pop[None, None, :]).reshape(-1, 7)
        dh0[:, block] = point_death / 1.0e3
        dh1[:, block] = np.nanquantile(flat_death, 0.025, axis=0) / 1.0e3
        dh2[:, block] = np.nanquantile(flat_death, 0.975, axis=0) / 1.0e3
        dr0[:, block] = point_rate * 1.0e6
        dr1[:, block] = np.nanquantile(flat_rate, 0.025, axis=0) * 1.0e6
        dr2[:, block] = np.nanquantile(flat_rate, 0.975, axis=0) * 1.0e6
    return dh0, dh1, dh2, dr0, dr1, dr2

def write_figure2_like(path, death_name, mortality_name, ratio0_name, ratio1_name, deaths, mortality, ratio0, ratio1, population_type):
    with Dataset(path, "w", format="NETCDF4") as ds:
        ds.createDimension("ssp", 3)
        ds.createDimension("state", 33)
        ds.createDimension("stat", 3)
        ds.createDimension("region", 7)
        vd = ds.createVariable(death_name, "f4", ("ssp", "state"), fill_value=np.float32(-9999.0))
        vm = ds.createVariable(mortality_name, "f4", ("ssp", "state"), fill_value=np.float32(-9999.0))
        vr0 = ds.createVariable(ratio0_name, "f4", ("ssp", "stat", "region"), fill_value=np.float32(-9999.0))
        vr1 = ds.createVariable(ratio1_name, "f4", ("ssp", "stat", "region"), fill_value=np.float32(-9999.0))
        vd[:] = np.ma.masked_invalid(deaths.astype(np.float32))
        vm[:] = np.ma.masked_invalid(mortality.astype(np.float32))
        vr0[:] = np.ma.masked_invalid(ratio0.astype(np.float32))
        vr1[:] = np.ma.masked_invalid(ratio1.astype(np.float32))
        vd.units = "deaths yr-1"
        vm.units = "deaths per 10^6 persons yr-1"
        vr0.units = "%"
        vr1.units = "%"
        ds.ssp_names = "SSP1-2.6,SSP2-4.5,SSP5-8.5"
        ds.stat_names = "point,lower95,upper95"
        ds.region_names = ",".join(REGION_NAMES)
        ds.state_names = "|".join(STATE_NAMES)
        ds.population_type = population_type
        ds.relative_change_reference = "historical reference conditions"
        ds.relative_change_storage = "100 equals no change; plotted labels subtract 100"

def write_figure3_like(path, arrays, population_type):
    with Dataset(path, "w", format="NETCDF4") as ds:
        ds.createDimension("region", 7)
        ds.createDimension("ssp", 3)
        ds.createDimension("period", 6)
        names = ["dh0", "dh1", "dh2", "dr0", "dr1", "dr2"]
        for name, data in zip(names, arrays):
            v = ds.createVariable(name, "f4", ("region", "ssp", "period"), fill_value=np.float32(-9999.0))
            v[:] = np.ma.masked_invalid(data.astype(np.float32))
        ds.variables["dh0"].units = "10^3 deaths yr-1"
        ds.variables["dh1"].units = "10^3 deaths yr-1"
        ds.variables["dh2"].units = "10^3 deaths yr-1"
        ds.variables["dr0"].units = "deaths per 10^6 persons yr-1"
        ds.variables["dr1"].units = "deaths per 10^6 persons yr-1"
        ds.variables["dr2"].units = "deaths per 10^6 persons yr-1"
        ds.ssp_names = "SSP1-2.6,SSP2-4.5,SSP5-8.5"
        ds.period_names = "2031-2035,2036-2040,2041-2045,2046-2050,2051-2055,2056-2060"
        ds.region_names = ",".join(REGION_NAMES)
        ds.stat_mapping = "0=point,1=lower95,2=upper95"
        ds.population_type = population_type

def write_figures9_comparison(path, urban_share, urban_rate_ratio):
    with Dataset(path, "w", format="NETCDF4") as ds:
        ds.createDimension("region", 7)
        ds.createDimension("ssp", 3)
        ds.createDimension("period", 6)
        v0 = ds.createVariable("urban_share", "f4", ("region", "ssp", "period"), fill_value=np.float32(-9999.0))
        v1 = ds.createVariable("urban_rate_ratio", "f4", ("region", "ssp", "period"), fill_value=np.float32(-9999.0))
        v0[:] = np.ma.masked_invalid(urban_share.astype(np.float32))
        v1[:] = np.ma.masked_invalid(urban_rate_ratio.astype(np.float32))
        v0.units = "%"
        v1.units = "%"
        v0.long_name = "urban share of attributable mortality"
        v1.long_name = "urban-to-total attributable mortality rate ratio"
        ds.ssp_names = "SSP1-2.6,SSP2-4.5,SSP5-8.5"
        ds.period_names = "2031-2035,2036-2040,2041-2045,2046-2050,2051-2055,2056-2060"
        ds.region_names = ",".join(REGION_NAMES)
        ds.urban_share_definition = "urban attributable deaths divided by total attributable deaths times 100"
        ds.urban_rate_ratio_definition = "urban attributable mortality rate divided by total attributable mortality rate times 100"
        ds.urban_rate_ratio_reference = "100 means equal attributable mortality rates"

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--mortality-dir", default="CWRF_mortality")
    parser.add_argument("--output-dir", default=".")
    parser.add_argument("--n-mc", type=int, default=1000)
    parser.add_argument("--seed", type=int, default=20260811)
    args = parser.parse_args()
    hist_path = os.path.join(args.mortality_dir, "CWRF_mortality_hist_1995-2014.nc")
    future_paths = {
        s: os.path.join(args.mortality_dir, f"CWRF_mortality_ssp{s}_2031-2060.nc")
        for s in SCENARIOS
    }
    for path in [hist_path] + list(future_paths.values()):
        if not os.path.exists(path):
            raise FileNotFoundError(path)
    os.makedirs(args.output_dir, exist_ok=True)
    storm_draw, heavy_draw = af_draws(args.n_mc, args.seed)
    with Dataset(hist_path, "r") as hist_ds:
        total_map_death = []
        total_map_rate = []
        urban_map_death = []
        urban_map_rate = []
        total_ratio_death = []
        total_ratio_rate = []
        urban_ratio_death = []
        urban_ratio_rate = []
        fig3_by_scenario = []
        figs9_by_scenario = []
        for scenario in SCENARIOS:
            with Dataset(future_paths[scenario], "r") as future_ds:
                d, r = map_data(future_ds, 0)
                total_map_death.append(d)
                total_map_rate.append(r)
                d, r = map_data(future_ds, 1)
                urban_map_death.append(d)
                urban_map_rate.append(r)
                rd, rr = relative_change_data(hist_ds, future_ds, 0, storm_draw, heavy_draw)
                total_ratio_death.append(rd)
                total_ratio_rate.append(rr)
                rd, rr = relative_change_data(hist_ds, future_ds, 1, storm_draw, heavy_draw)
                urban_ratio_death.append(rd)
                urban_ratio_rate.append(rr)
                fig3_by_scenario.append(trajectory_data(future_ds, 0, storm_draw, heavy_draw))
                figs9_by_scenario.append(trajectory_data(future_ds, 1, storm_draw, heavy_draw))
    total_map_death = np.stack(total_map_death, axis=0)
    total_map_rate = np.stack(total_map_rate, axis=0)
    urban_map_death = np.stack(urban_map_death, axis=0)
    urban_map_rate = np.stack(urban_map_rate, axis=0)
    total_ratio_death = np.stack(total_ratio_death, axis=0)
    total_ratio_rate = np.stack(total_ratio_rate, axis=0)
    urban_ratio_death = np.stack(urban_ratio_death, axis=0)
    urban_ratio_rate = np.stack(urban_ratio_rate, axis=0)
    fig3_arrays = []
    figs9_arrays = []
    for k in range(6):
        fig3_arrays.append(np.stack([x[k] for x in fig3_by_scenario], axis=1))
        figs9_arrays.append(np.stack([x[k] for x in figs9_by_scenario], axis=1))
    write_figure2_like(
        os.path.join(args.output_dir, "Figure2_plot_data.nc"),
        "death_plot",
        "mortality_plot",
        "c_ratio0_plot",
        "c_ratio1_plot",
        total_map_death,
        total_map_rate,
        total_ratio_death,
        total_ratio_rate,
        "total",
    )
    write_figure2_like(
        os.path.join(args.output_dir, "FigureS8_plot_data.nc"),
        "death",
        "mortality",
        "c_ratio0",
        "c_ratio1",
        urban_map_death,
        urban_map_rate,
        urban_ratio_death,
        urban_ratio_rate,
        "urban",
    )
    write_figure3_like(
        os.path.join(args.output_dir, "Figure3_plot_data.nc"),
        fig3_arrays,
        "total",
    )
    urban_share = safe_divide(figs9_arrays[0], fig3_arrays[0]) * 100.0
    urban_rate_ratio = safe_divide(figs9_arrays[3], fig3_arrays[3]) * 100.0
    write_figures9_comparison(
        os.path.join(args.output_dir, "FigureS11_plot_data.nc"),
        urban_share,
        urban_rate_ratio,
    )
    rows = []
    for name, data in [
        ("Figure2 death_plot", total_map_death),
        ("Figure2 mortality_plot", total_map_rate),
        ("Figure2 c_ratio0_plot", total_ratio_death),
        ("Figure2 c_ratio1_plot", total_ratio_rate),
        ("FigureS8 death", urban_map_death),
        ("FigureS8 mortality", urban_map_rate),
        ("FigureS8 c_ratio0", urban_ratio_death),
        ("FigureS8 c_ratio1", urban_ratio_rate),
    ]:
        rows.append([name, data.shape, float(np.nanmin(data)), float(np.nanmax(data))])
    for name, data in zip(["dh0","dh1","dh2","dr0","dr1","dr2"], fig3_arrays):
        rows.append([f"Figure3 {name}", data.shape, float(np.nanmin(data)), float(np.nanmax(data))])
    rows.append(["FigureS11 urban_share", urban_share.shape, float(np.nanmin(urban_share)), float(np.nanmax(urban_share))])
    rows.append(["FigureS11 urban_rate_ratio", urban_rate_ratio.shape, float(np.nanmin(urban_rate_ratio)), float(np.nanmax(urban_rate_ratio))])
    qc_path = os.path.join(args.output_dir, "figure_plot_data_qc.csv")
    with open(qc_path, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(["variable", "shape", "min", "max"])
        writer.writerows(rows)
    print(os.path.join(args.output_dir, "Figure2_plot_data.nc"))
    print(os.path.join(args.output_dir, "Figure3_plot_data.nc"))
    print(os.path.join(args.output_dir, "FigureS8_plot_data.nc"))
    print(os.path.join(args.output_dir, "FigureS11_plot_data.nc"))
    print(qc_path)

if __name__ == "__main__":
    main()
