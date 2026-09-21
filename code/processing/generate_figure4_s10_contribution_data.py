import os
import csv
import argparse
import numpy as np
from netCDF4 import Dataset

MODELS = ["MPI", "CESM2", "IPSL"]
SCENARIOS = ["126", "245", "585"]
SCENARIO_NAMES = ["SSP1-2.6", "SSP2-4.5", "SSP5-8.5"]
SSP_INDEX = {"126": 1, "245": 2, "585": 5}
POP_TYPE_NAMES = ["Total", "Urban"]
REGION_KEYS = ["china", "northeast", "north", "northwest", "east", "central", "sc"]
REGION_NAMES = ["China", "NE", "NC", "NW", "EC", "CC", "SC"]
PROVINCE_NAMES = [
    "Heilongjiang",
    "Jilin",
    "Liaoning",
    "Beijing",
    "Tianjin",
    "Hebei",
    "Shanxi",
    "Inner Mongolia",
    "Ningxia",
    "Shaanxi",
    "Gansu",
    "Qinghai",
    "Xinjiang",
    "Shandong",
    "Jiangsu",
    "Shanghai",
    "Zhejiang",
    "Anhui",
    "Jiangxi",
    "Fujian",
    "Henan",
    "Hubei",
    "Hunan",
    "Chongqing",
    "Sichuan",
    "Yunnan",
    "Guizhou",
    "Tibet",
    "Guangxi",
    "Guangdong, Hong Kong & Macao",
    "Hainan",
    "Taiwan",
]
STATE_NAMES = ["M00", "M10", "M0size", "M01", "M1size", "M11"]
COMPONENT_NAMES = ["Climate", "Population size", "Redistribution", "Interaction", "Total"]
RR_STORM_MEAN = np.array([1.147, 1.211, 1.021, 1.021, 1.295, 1.254], dtype=np.float64)
RR_STORM_LOW = np.array([0.647, 0.770, 0.436, 0.746, 0.825, 0.590], dtype=np.float64)
RR_STORM_HIGH = np.array([2.034, 1.906, 2.389, 1.396, 2.034, 2.665], dtype=np.float64)
RR_HEAVY_MEAN = np.array([np.nan, np.nan, np.nan, np.nan, 1.051, 1.151], dtype=np.float64)
RR_HEAVY_LOW = np.array([np.nan, np.nan, np.nan, np.nan, 0.834, 0.958], dtype=np.float64)
RR_HEAVY_HIGH = np.array([np.nan, np.nan, np.nan, np.nan, 1.324, 1.384], dtype=np.float64)

def nc_array(ds, name, fill=np.nan, dtype=np.float64):
    a = ds.variables[name][:]
    if np.ma.isMaskedArray(a):
        a = a.filled(fill)
    return np.asarray(a, dtype=dtype)

def read_mask(path, preferred):
    with Dataset(path, "r") as ds:
        name = preferred if preferred in ds.variables else "region_mask"
        a = ds.variables[name][:]
        if np.ma.isMaskedArray(a):
            a = a.filled(0)
        return np.asarray(a, dtype=np.int16)

def read_death_rate(path):
    with Dataset(path, "r") as ds:
        if "death_rate_daily" in ds.variables:
            name = "death_rate_daily"
        elif "death_rate" in ds.variables:
            name = "death_rate"
        else:
            raise KeyError(f"No death-rate variable found in {path}")
        a = ds.variables[name][:]
        if np.ma.isMaskedArray(a):
            a = a.filled(np.nan)
        a = np.asarray(a, dtype=np.float64)
        if name == "death_rate":
            a = a / 365.0
        a[~np.isfinite(a)] = 0.0
        a[a < 0] = 0.0
        return a

def coordinate_values(ds, dim_name, length, fallback):
    if dim_name in ds.variables:
        values = np.asarray(ds.variables[dim_name][:])
        if values.ndim == 1 and values.size == length:
            return values
    return np.asarray(fallback)

def population_axes(ds):
    if "pop" not in ds.variables:
        raise KeyError("Population file must contain variable 'pop'")
    var = ds.variables["pop"]
    if var.ndim != 4:
        raise ValueError(f"Population variable must be 4-D, got {var.shape}")
    d0, d1 = var.dimensions[:2]
    ssp = coordinate_values(ds, d0, var.shape[0], np.arange(1, var.shape[0] + 1))
    years = coordinate_values(ds, d1, var.shape[1], np.arange(2010, 2010 + var.shape[1]))
    return var, np.asarray(ssp), np.asarray(years)

def read_population_field(var, i0, i1):
    a = var[i0, i1, :, :]
    if np.ma.isMaskedArray(a):
        a = a.filled(0.0)
    a = np.asarray(a, dtype=np.float64)
    a[~np.isfinite(a)] = 0.0
    a[a < 0] = 0.0
    return a

def historical_population(ds):
    var, ssp, years = population_axes(ds)
    fields = []
    for year in range(2010, 2015):
        idx = np.where(years == year)[0]
        if idx.size != 1:
            raise ValueError(f"Cannot find population year {year}")
        for i0 in range(var.shape[0]):
            fields.append(read_population_field(var, i0, int(idx[0])))
    return np.mean(np.stack(fields, axis=0), axis=0)

def historical_ssp_spread(ds):
    var, ssp, years = population_axes(ds)
    max_abs = 0.0
    max_rel = 0.0
    for year in range(2010, 2015):
        idx = np.where(years == year)[0]
        if idx.size != 1:
            continue
        fields = np.stack([read_population_field(var, i0, int(idx[0])) for i0 in range(var.shape[0])], axis=0)
        spread = np.max(fields, axis=0) - np.min(fields, axis=0)
        ref = np.mean(fields, axis=0)
        max_abs = max(max_abs, float(np.nanmax(np.abs(spread))))
        valid = np.abs(ref) > 0
        if np.any(valid):
            max_rel = max(max_rel, float(np.nanmax(np.abs(spread[valid] / ref[valid]))))
    return max_abs, max_rel

def future_population(ds, ssp_value, target_years):
    var, ssp, years = population_axes(ds)
    idx0 = np.where(ssp == ssp_value)[0]
    if idx0.size != 1:
        if 1 <= ssp_value <= var.shape[0]:
            idx0 = np.array([ssp_value - 1])
        else:
            raise ValueError(f"Cannot find SSP {ssp_value}")
    out = []
    for year in target_years:
        idx1 = np.where(years == year)[0]
        if idx1.size != 1:
            raise ValueError(f"Cannot find population year {year}")
        out.append(read_population_field(var, int(idx0[0]), int(idx1[0])))
    return np.stack(out, axis=0)

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

def province_region_codes():
    out = np.zeros(32, dtype=np.int16)
    out[0:3] = 1
    out[3:8] = 2
    out[8:13] = 3
    out[13:20] = 4
    out[20:23] = 5
    out[23:32] = 6
    return out

def aggregate_grid(a, mask, n):
    x = np.asarray(a, dtype=np.float64).ravel()
    m = np.asarray(mask, dtype=np.int64).ravel()
    valid = np.isfinite(x) & (m >= 1) & (m <= n)
    return np.bincount(m[valid], weights=x[valid], minlength=n + 1)[1:n + 1].astype(np.float64)

def rain_cache_path(cache_dir, model, scenario):
    return os.path.join(cache_dir, "rain_days", f"{model}_{scenario}_rain_days.nc")

def read_rain_cache(cache_dir, model, scenario, expected_years, grid_shape):
    path = rain_cache_path(cache_dir, model, scenario)
    if not os.path.exists(path):
        raise FileNotFoundError(
            f"{path} not found. Run calculate_cwrf_mortality_CWRFgrid_v3.py first so the rain-day cache exists."
        )
    with Dataset(path, "r") as ds:
        years = nc_array(ds, "year", dtype=np.int32)
        if not np.array_equal(years, np.asarray(expected_years, dtype=np.int32)):
            raise ValueError(f"Year mismatch in {path}: {years[0]}-{years[-1]}")
        storm = nc_array(ds, "storm_days")
        heavy = nc_array(ds, "heavy_days")
        if storm.shape[1:] != grid_shape or heavy.shape[1:] != grid_shape:
            raise ValueError(f"Grid mismatch in {path}: {storm.shape[1:]} vs {grid_shape}")
        return storm, heavy

def exposure_states(hist_storm, hist_heavy, fut_storm, fut_heavy, p0, p1, death_rate, region_mask, province_mask):
    if fut_storm.shape[0] != p1.shape[0]:
        raise ValueError("Future climate years and future population years do not match")
    p0_sum = float(np.sum(p0))
    if p0_sum <= 0:
        raise ValueError("Historical population is zero")
    scale = np.sum(p1, axis=(1, 2)) / p0_sum
    base0 = p0 * death_rate
    p1_mean = np.mean(p1, axis=0)
    scale_mean = float(np.mean(scale))
    hist_s = np.mean(hist_storm, axis=0)
    hist_h = np.mean(hist_heavy, axis=0)
    fut_s = np.mean(fut_storm, axis=0)
    fut_h = np.mean(fut_heavy, axis=0)
    weighted_fut_s = np.mean(fut_storm * scale[:, None, None], axis=0)
    weighted_fut_h = np.mean(fut_heavy * scale[:, None, None], axis=0)
    paired_p1_s = np.mean(fut_storm * p1, axis=0)
    paired_p1_h = np.mean(fut_heavy * p1, axis=0)
    fields_s = [
        base0 * hist_s,
        base0 * fut_s,
        base0 * scale_mean * hist_s,
        p1_mean * death_rate * hist_s,
        base0 * weighted_fut_s,
        death_rate * paired_p1_s,
    ]
    fields_h = [
        base0 * hist_h,
        base0 * fut_h,
        base0 * scale_mean * hist_h,
        p1_mean * death_rate * hist_h,
        base0 * weighted_fut_h,
        death_rate * paired_p1_h,
    ]
    reg = np.zeros((6, 2, 6), dtype=np.float64)
    prv = np.zeros((6, 2, 32), dtype=np.float64)
    for k in range(6):
        reg[k, 0] = aggregate_grid(fields_s[k], region_mask, 6)
        reg[k, 1] = aggregate_grid(fields_h[k], region_mask, 6)
        prv[k, 0] = aggregate_grid(fields_s[k], province_mask, 32)
        prv[k, 1] = aggregate_grid(fields_h[k], province_mask, 32)
    return reg, prv, scale

def region_state_point(exposure, storm_af, heavy_af):
    nmodel = exposure.shape[0]
    out = np.zeros((nmodel, 6, 7), dtype=np.float64)
    for r in range(6):
        out[:, :, r + 1] = (
            exposure[:, :, 0, r] * storm_af[r]
            + exposure[:, :, 1, r] * heavy_af[r]
        )
    out[:, :, 0] = np.sum(out[:, :, 1:], axis=2)
    return out

def province_state_point(exposure, storm_af, heavy_af, province_region):
    nmodel = exposure.shape[0]
    out = np.zeros((nmodel, 6, 32), dtype=np.float64)
    for ip in range(32):
        r = int(province_region[ip]) - 1
        out[:, :, ip] = (
            exposure[:, :, 0, ip] * storm_af[r]
            + exposure[:, :, 1, ip] * heavy_af[r]
        )
    return out

def region_state_draws(exposure, storm_draw, heavy_draw):
    nmc = storm_draw.shape[0]
    nmodel = exposure.shape[0]
    out = np.zeros((nmc, nmodel, 6, 7), dtype=np.float64)
    for r in range(6):
        out[:, :, :, r + 1] = (
            storm_draw[:, r, None, None] * exposure[None, :, :, 0, r]
            + heavy_draw[:, r, None, None] * exposure[None, :, :, 1, r]
        )
    out[:, :, :, 0] = np.sum(out[:, :, :, 1:], axis=3)
    return out

def province_state_draws(exposure, storm_draw, heavy_draw, province_region):
    nmc = storm_draw.shape[0]
    nmodel = exposure.shape[0]
    out = np.zeros((nmc, nmodel, 6, 32), dtype=np.float64)
    for ip in range(32):
        r = int(province_region[ip]) - 1
        out[:, :, :, ip] = (
            storm_draw[:, r, None, None] * exposure[None, :, :, 0, ip]
            + heavy_draw[:, r, None, None] * exposure[None, :, :, 1, ip]
        )
    return out

def components_from_states(states):
    climate = states[..., 1, :] - states[..., 0, :]
    pop_size = states[..., 2, :] - states[..., 0, :]
    redistribution = states[..., 3, :] - states[..., 2, :]
    interaction = states[..., 5, :] - states[..., 1, :] - states[..., 3, :] + states[..., 0, :]
    total = states[..., 5, :] - states[..., 0, :]
    return np.stack([climate, pop_size, redistribution, interaction, total], axis=-2)

def population_component_from_states(states):
    return states[..., 3, :] - states[..., 0, :]

def safe_ratio(a, b, threshold):
    a, b = np.broadcast_arrays(np.asarray(a, dtype=np.float64), np.asarray(b, dtype=np.float64))
    out = np.full(a.shape, np.nan, dtype=np.float64)
    valid = np.isfinite(a) & np.isfinite(b) & (np.abs(b) > threshold)
    out[valid] = a[valid] / b[valid]
    return out

def summarize(states_point, states_draw, pct_threshold):
    comp_point_model = components_from_states(states_point)
    pop_point_model = population_component_from_states(states_point)
    comp_point = np.mean(comp_point_model, axis=0)
    pop_point = np.mean(pop_point_model, axis=0)
    state_point = np.mean(states_point, axis=0)
    state_flat = states_draw.reshape(-1, states_draw.shape[-2], states_draw.shape[-1])
    comp_draw = components_from_states(states_draw)
    pop_draw = population_component_from_states(states_draw)
    comp_flat = comp_draw.reshape(-1, comp_draw.shape[-2], comp_draw.shape[-1])
    pop_flat = pop_draw.reshape(-1, pop_draw.shape[-1])
    state_low = np.nanquantile(state_flat, 0.025, axis=0)
    state_high = np.nanquantile(state_flat, 0.975, axis=0)
    comp_low = np.nanquantile(comp_flat, 0.025, axis=0)
    comp_high = np.nanquantile(comp_flat, 0.975, axis=0)
    pop_low = np.nanquantile(pop_flat, 0.025, axis=0)
    pop_high = np.nanquantile(pop_flat, 0.975, axis=0)
    total_point = comp_point[4]
    pct_point = safe_ratio(comp_point[:4], total_point[None, :], pct_threshold) * 100.0
    pct_pop_point = safe_ratio(pop_point, total_point, pct_threshold) * 100.0
    total_draw = comp_draw[:, :, 4, :]
    pct_draw = safe_ratio(comp_draw[:, :, :4, :], total_draw[:, :, None, :], pct_threshold) * 100.0
    pct_pop_draw = safe_ratio(pop_draw, total_draw, pct_threshold) * 100.0
    pct_flat = pct_draw.reshape(-1, 4, pct_draw.shape[-1])
    pct_pop_flat = pct_pop_draw.reshape(-1, pct_pop_draw.shape[-1])
    pct_low = np.nanquantile(pct_flat, 0.025, axis=0)
    pct_high = np.nanquantile(pct_flat, 0.975, axis=0)
    pct_pop_low = np.nanquantile(pct_pop_flat, 0.025, axis=0)
    pct_pop_high = np.nanquantile(pct_pop_flat, 0.975, axis=0)
    valid_fraction = np.mean(np.isfinite(pct_pop_flat), axis=0)
    return {
        "state_point": state_point,
        "state_low": state_low,
        "state_high": state_high,
        "state_point_by_model": states_point,
        "component_point": comp_point,
        "component_low": comp_low,
        "component_high": comp_high,
        "component_point_by_model": comp_point_model,
        "population_point": pop_point,
        "population_low": pop_low,
        "population_high": pop_high,
        "pct_point": pct_point,
        "pct_low": pct_low,
        "pct_high": pct_high,
        "pct_population_point": pct_pop_point,
        "pct_population_low": pct_pop_low,
        "pct_population_high": pct_pop_high,
        "pct_valid_fraction": valid_fraction,
    }

def empty_store(nspace):
    shape = (nspace, 3, 2)
    shape_state = (nspace, 3, 2, 6)
    shape_model_state = (nspace, 3, 2, 3, 6)
    shape_component = (nspace, 3, 2, 5)
    shape_model_component = (nspace, 3, 2, 3, 5)
    shape_pct = (nspace, 3, 2, 4)
    return {
        "state_point": np.full(shape_state, np.nan),
        "state_low": np.full(shape_state, np.nan),
        "state_high": np.full(shape_state, np.nan),
        "state_point_by_model": np.full(shape_model_state, np.nan),
        "component_point": np.full(shape_component, np.nan),
        "component_low": np.full(shape_component, np.nan),
        "component_high": np.full(shape_component, np.nan),
        "component_point_by_model": np.full(shape_model_component, np.nan),
        "population_point": np.full(shape, np.nan),
        "population_low": np.full(shape, np.nan),
        "population_high": np.full(shape, np.nan),
        "pct_point": np.full(shape_pct, np.nan),
        "pct_low": np.full(shape_pct, np.nan),
        "pct_high": np.full(shape_pct, np.nan),
        "pct_population_point": np.full(shape, np.nan),
        "pct_population_low": np.full(shape, np.nan),
        "pct_population_high": np.full(shape, np.nan),
        "pct_valid_fraction": np.full(shape, np.nan),
    }

def place_summary(store, result, scenario_index, pop_index):
    for key in ["state_point", "state_low", "state_high"]:
        store[key][:, scenario_index, pop_index, :] = np.moveaxis(result[key], -1, 0)
    store["state_point_by_model"][:, scenario_index, pop_index, :, :] = np.moveaxis(result["state_point_by_model"], -1, 0)
    for key in ["component_point", "component_low", "component_high"]:
        store[key][:, scenario_index, pop_index, :] = np.moveaxis(result[key], -1, 0)
    store["component_point_by_model"][:, scenario_index, pop_index, :, :] = np.moveaxis(result["component_point_by_model"], -1, 0)
    for key in ["population_point", "population_low", "population_high", "pct_population_point", "pct_population_low", "pct_population_high", "pct_valid_fraction"]:
        store[key][:, scenario_index, pop_index] = result[key]
    for key in ["pct_point", "pct_low", "pct_high"]:
        store[key][:, scenario_index, pop_index, :] = np.moveaxis(result[key], -1, 0)

def write_string_coord(ds, name, values):
    ds.createDimension(name, len(values))
    v = ds.createVariable(name, str, (name,))
    v[:] = np.asarray(values, dtype=object)

def create_plot_file(path, spatial_dim, spatial_values, display_values, store, pct_threshold):
    with Dataset(path, "w", format="NETCDF4") as ds:
        write_string_coord(ds, spatial_dim, spatial_values)
        write_string_coord(ds, "scenario", SCENARIO_NAMES)
        write_string_coord(ds, "pop_type", POP_TYPE_NAMES)
        write_string_coord(ds, "model", MODELS)
        write_string_coord(ds, "state", STATE_NAMES)
        write_string_coord(ds, "component", COMPONENT_NAMES)
        vdisplay = ds.createVariable(f"{spatial_dim}_display_name", str, (spatial_dim,))
        vdisplay[:] = np.asarray(display_values, dtype=object)
        dims = (spatial_dim, "scenario", "pop_type")
        var_map = {
            "abs_clim": ("component_point", 0),
            "abs_pop_size": ("component_point", 1),
            "abs_redistribution": ("component_point", 2),
            "abs_interaction": ("component_point", 3),
            "abs_total": ("component_point", 4),
        }
        for out_name, (source, idx) in var_map.items():
            for suffix, key in [("", source), ("_low", "component_low"), ("_high", "component_high")]:
                v = ds.createVariable(out_name + suffix, "f8", dims, zlib=True, complevel=4)
                v[:] = store[key][..., idx]
                v.units = "deaths yr-1"
        for suffix, key in [("", "population_point"), ("_low", "population_low"), ("_high", "population_high")]:
            v = ds.createVariable("abs_pop" + suffix, "f8", dims, zlib=True, complevel=4)
            v[:] = store[key]
            v.units = "deaths yr-1"
        pct_map = {
            "pct_clim": 0,
            "pct_pop_size": 1,
            "pct_redistribution": 2,
            "pct_interaction": 3,
        }
        for out_name, idx in pct_map.items():
            for suffix, key in [("", "pct_point"), ("_low", "pct_low"), ("_high", "pct_high")]:
                v = ds.createVariable(out_name + suffix, "f8", dims, zlib=True, complevel=4)
                v[:] = store[key][..., idx]
                v.units = "%"
        for suffix, key in [("", "pct_population_point"), ("_low", "pct_population_low"), ("_high", "pct_population_high")]:
            v = ds.createVariable("pct_pop" + suffix, "f8", dims, zlib=True, complevel=4)
            v[:] = store[key]
            v.units = "%"
        v = ds.createVariable("pct_valid_fraction", "f8", dims, zlib=True, complevel=4)
        v[:] = store["pct_valid_fraction"]
        v.units = "1"
        v = ds.createVariable("state_point", "f8", (spatial_dim, "scenario", "pop_type", "state"), zlib=True, complevel=4)
        v[:] = store["state_point"]
        v.units = "deaths yr-1"
        v = ds.createVariable("state_low", "f8", (spatial_dim, "scenario", "pop_type", "state"), zlib=True, complevel=4)
        v[:] = store["state_low"]
        v.units = "deaths yr-1"
        v = ds.createVariable("state_high", "f8", (spatial_dim, "scenario", "pop_type", "state"), zlib=True, complevel=4)
        v[:] = store["state_high"]
        v.units = "deaths yr-1"
        v = ds.createVariable("state_point_by_model", "f8", (spatial_dim, "scenario", "pop_type", "model", "state"), zlib=True, complevel=4)
        v[:] = store["state_point_by_model"]
        v.units = "deaths yr-1"
        v = ds.createVariable("component_point_by_model", "f8", (spatial_dim, "scenario", "pop_type", "model", "component"), zlib=True, complevel=4)
        v[:] = store["component_point_by_model"]
        v.units = "deaths yr-1"
        ds.title = "Factorial decomposition data for projected precipitation-associated mortality"
        ds.climate_component = "M10-M00"
        ds.population_size_component = "M0size-M00"
        ds.redistribution_component = "M01-M0size"
        ds.population_component = "M01-M00 = population size + redistribution"
        ds.interaction_component = "M11-M10-M01+M00"
        ds.total_change = "M11-M00"
        ds.state_M00 = "historical climate and historical population"
        ds.state_M10 = "future climate and historical population"
        ds.state_M0size = "historical climate and future population size with historical national spatial shares"
        ds.state_M01 = "historical climate and future population"
        ds.state_M1size = "future climate and future population size with historical national spatial shares"
        ds.state_M11 = "future climate and future population"
        ds.population_size_definition = "Psize(y)=P0*sum(P1(y))/sum(P0), preserving the historical national spatial distribution"
        ds.central_estimate = "RR point estimates and arithmetic mean across the three CWRF climate members"
        ds.uncertainty = "2.5th-97.5th percentiles across paired RR Monte Carlo draws and three CWRF climate members"
        ds.rr_pairing = "The same RR draw is used across all counterfactual states within each realization"
        ds.percentage_definition = "component divided by total change times 100"
        ds.percentage_denominator_threshold = float(pct_threshold)
        ds.historical_climate_period = "1995-2014"
        ds.future_climate_period = "2031-2060"
        ds.historical_population_reference = "mean population field over 2010-2014, averaged across the five SSP entries as in the mortality calculation"
        ds.af_definition = "(RR-1)/RR"

def write_summary_csv(path, spatial_name, spatial_values, display_values, store):
    fields = [
        spatial_name,
        "display_name",
        "scenario",
        "population_type",
        "climate",
        "climate_low",
        "climate_high",
        "population_size",
        "population_size_low",
        "population_size_high",
        "redistribution",
        "redistribution_low",
        "redistribution_high",
        "population_total",
        "population_total_low",
        "population_total_high",
        "interaction",
        "interaction_low",
        "interaction_high",
        "total_change",
        "total_change_low",
        "total_change_high",
        "pct_climate",
        "pct_population_size",
        "pct_redistribution",
        "pct_population_total",
        "pct_interaction",
        "pct_valid_fraction",
        "additive_closure",
        "population_closure",
    ]
    with open(path, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fields)
        writer.writeheader()
        for i, key in enumerate(spatial_values):
            for s, scenario in enumerate(SCENARIO_NAMES):
                for p, pop in enumerate(POP_TYPE_NAMES):
                    c = store["component_point"][i, s, p]
                    row = {
                        spatial_name: key,
                        "display_name": display_values[i],
                        "scenario": scenario,
                        "population_type": pop,
                        "climate": c[0],
                        "climate_low": store["component_low"][i, s, p, 0],
                        "climate_high": store["component_high"][i, s, p, 0],
                        "population_size": c[1],
                        "population_size_low": store["component_low"][i, s, p, 1],
                        "population_size_high": store["component_high"][i, s, p, 1],
                        "redistribution": c[2],
                        "redistribution_low": store["component_low"][i, s, p, 2],
                        "redistribution_high": store["component_high"][i, s, p, 2],
                        "population_total": store["population_point"][i, s, p],
                        "population_total_low": store["population_low"][i, s, p],
                        "population_total_high": store["population_high"][i, s, p],
                        "interaction": c[3],
                        "interaction_low": store["component_low"][i, s, p, 3],
                        "interaction_high": store["component_high"][i, s, p, 3],
                        "total_change": c[4],
                        "total_change_low": store["component_low"][i, s, p, 4],
                        "total_change_high": store["component_high"][i, s, p, 4],
                        "pct_climate": store["pct_point"][i, s, p, 0],
                        "pct_population_size": store["pct_point"][i, s, p, 1],
                        "pct_redistribution": store["pct_point"][i, s, p, 2],
                        "pct_population_total": store["pct_population_point"][i, s, p],
                        "pct_interaction": store["pct_point"][i, s, p, 3],
                        "pct_valid_fraction": store["pct_valid_fraction"][i, s, p],
                        "additive_closure": c[4] - np.sum(c[:4]),
                        "population_closure": store["population_point"][i, s, p] - c[1] - c[2],
                    }
                    writer.writerow(row)

def current_model_order(ds):
    names = str(getattr(ds, "model_names", "")).split(",")
    names = [x.strip() for x in names if x.strip()]
    if len(names) != 3:
        return MODELS
    return names

def current_period_by_model(path, scope, pop_index):
    with Dataset(path, "r") as ds:
        names = current_model_order(ds)
        if scope == "region":
            a = nc_array(ds, "region_deaths_point")[pop_index, :, :, :, 2]
        else:
            a = nc_array(ds, "province_deaths_point")[pop_index, :, :, :, 2]
        a = np.mean(a, axis=1)
        order = []
        for model in MODELS:
            if model not in names:
                raise ValueError(f"Model {model} not found in {path}: {names}")
            order.append(names.index(model))
        return a[order]

def write_qa(path, region_store, province_store, hist_region_by_pop, hist_province_by_pop, args):
    rows = []
    for s, scenario in enumerate(SCENARIOS):
        for p, pop in enumerate(POP_TYPE_NAMES):
            c = region_store["component_point"][:, s, p, :]
            rows.append({
                "check": "region_additive_closure",
                "scenario": SCENARIO_NAMES[s],
                "population_type": pop,
                "value": float(np.nanmax(np.abs(c[:, 4] - np.sum(c[:, :4], axis=1)))),
            })
            rows.append({
                "check": "region_population_closure",
                "scenario": SCENARIO_NAMES[s],
                "population_type": pop,
                "value": float(np.nanmax(np.abs(region_store["population_point"][:, s, p] - c[:, 1] - c[:, 2]))),
            })
            cp = province_store["component_point"][:, s, p, :]
            rows.append({
                "check": "province_additive_closure",
                "scenario": SCENARIO_NAMES[s],
                "population_type": pop,
                "value": float(np.nanmax(np.abs(cp[:, 4] - np.sum(cp[:, :4], axis=1)))),
            })
            rows.append({
                "check": "province_population_closure",
                "scenario": SCENARIO_NAMES[s],
                "population_type": pop,
                "value": float(np.nanmax(np.abs(province_store["population_point"][:, s, p] - cp[:, 1] - cp[:, 2]))),
            })
            rows.append({
                "check": "region_pct_valid_fraction_min",
                "scenario": SCENARIO_NAMES[s],
                "population_type": pop,
                "value": float(np.nanmin(region_store["pct_valid_fraction"][:, s, p])),
            })
            rows.append({
                "check": "province_pct_valid_fraction_min",
                "scenario": SCENARIO_NAMES[s],
                "population_type": pop,
                "value": float(np.nanmin(province_store["pct_valid_fraction"][:, s, p])),
            })
            hist_file = os.path.join(args.mortality_dir, "CWRF_mortality_hist_1995-2014.nc")
            fut_file = os.path.join(args.mortality_dir, f"CWRF_mortality_ssp{scenario}_2031-2060.nc")
            if os.path.exists(hist_file):
                rcur = current_period_by_model(hist_file, "region", p)
                pcur = current_period_by_model(hist_file, "province", p)
                rows.append({
                    "check": "M00_region_vs_current_mortality_max_abs",
                    "scenario": SCENARIO_NAMES[s],
                    "population_type": pop,
                    "value": float(np.nanmax(np.abs(hist_region_by_pop[p] - rcur))),
                })
                rows.append({
                    "check": "M00_province_vs_current_mortality_max_abs",
                    "scenario": SCENARIO_NAMES[s],
                    "population_type": pop,
                    "value": float(np.nanmax(np.abs(hist_province_by_pop[p] - pcur))),
                })
            if os.path.exists(fut_file):
                rcur = current_period_by_model(fut_file, "region", p)
                pcur = current_period_by_model(fut_file, "province", p)
                rcalc = np.moveaxis(region_store["state_point_by_model"][:, s, p, :, 5], 0, -1)
                pcalc = np.moveaxis(province_store["state_point_by_model"][:, s, p, :, 5], 0, -1)
                rows.append({
                    "check": "M11_region_vs_current_mortality_max_abs",
                    "scenario": SCENARIO_NAMES[s],
                    "population_type": pop,
                    "value": float(np.nanmax(np.abs(rcalc - rcur))),
                })
                rows.append({
                    "check": "M11_province_vs_current_mortality_max_abs",
                    "scenario": SCENARIO_NAMES[s],
                    "population_type": pop,
                    "value": float(np.nanmax(np.abs(pcalc - pcur))),
                })
    with open(path, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=["check", "scenario", "population_type", "value"])
        writer.writeheader()
        writer.writerows(rows)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--province-mask", default="0.province_CWRF.nc")
    parser.add_argument("--region-mask", default="0.region_CWRF.nc")
    parser.add_argument("--death-rate", default="1.death-rate_CWRF.nc")
    parser.add_argument("--total-pop", default="total_pop_CWRF.nc")
    parser.add_argument("--urban-pop", default="urban_pop_CWRF.nc")
    parser.add_argument("--cache-dir", default="cache_cwrf_mortality")
    parser.add_argument("--mortality-dir", default="CWRF_mortality")
    parser.add_argument("--output-dir", default=".")
    parser.add_argument("--n-mc", type=int, default=1000)
    parser.add_argument("--seed", type=int, default=20260811)
    parser.add_argument("--pct-denom-threshold", type=float, default=1.0e-10)
    args = parser.parse_args()

    os.makedirs(args.output_dir, exist_ok=True)

    province_mask = read_mask(args.province_mask, "province_mask")
    region_mask = read_mask(args.region_mask, "region_mask")
    death_rate = read_death_rate(args.death_rate)

    if province_mask.shape != region_mask.shape or region_mask.shape != death_rate.shape:
        raise ValueError("Static CWRF grids do not match")

    province_region = province_region_codes()
    storm_point, heavy_point = af_point()
    storm_draw, heavy_draw = af_draws(args.n_mc, args.seed)

    hist_years = np.arange(1995, 2015, dtype=np.int32)
    fut_years = np.arange(2031, 2061, dtype=np.int32)

    hist_climate = {}
    for model in MODELS:
        hs, hh = read_rain_cache(args.cache_dir, model, "hist", hist_years, region_mask.shape)
        hist_climate[model] = (hs, hh)

    region_store = empty_store(7)
    province_store = empty_store(32)

    hist_region_by_pop = {}
    hist_province_by_pop = {}

    with Dataset(args.total_pop, "r") as total_ds, Dataset(args.urban_pop, "r") as urban_ds:
        pop_datasets = [total_ds, urban_ds]
        p0_fields = [historical_population(total_ds), historical_population(urban_ds)]

        for p, ds in enumerate(pop_datasets):
            abs_spread, rel_spread = historical_ssp_spread(ds)
            print(f"{POP_TYPE_NAMES[p]} historical SSP spread max abs = {abs_spread}")
            print(f"{POP_TYPE_NAMES[p]} historical SSP spread max rel = {rel_spread}")

        for s, scenario in enumerate(SCENARIOS):
            future_pops = [
                future_population(total_ds, SSP_INDEX[scenario], fut_years),
                future_population(urban_ds, SSP_INDEX[scenario], fut_years),
            ]

            region_exposure = [np.zeros((3, 6, 2, 6), dtype=np.float64) for _ in range(2)]
            province_exposure = [np.zeros((3, 6, 2, 32), dtype=np.float64) for _ in range(2)]

            for im, model in enumerate(MODELS):
                fs, fh = read_rain_cache(args.cache_dir, model, scenario, fut_years, region_mask.shape)
                hs, hh = hist_climate[model]

                for p in range(2):
                    reg, prv, scale = exposure_states(
                        hs,
                        hh,
                        fs,
                        fh,
                        p0_fields[p],
                        future_pops[p],
                        death_rate,
                        region_mask,
                        province_mask,
                    )
                    region_exposure[p][im] = reg
                    province_exposure[p][im] = prv
                    print(
                        f"{SCENARIO_NAMES[s]} {POP_TYPE_NAMES[p]} {model}: "
                        f"future/historical national population scale = "
                        f"{float(np.mean(scale)):.6f} mean, {float(np.min(scale)):.6f}-{float(np.max(scale)):.6f}"
                    )

            for p in range(2):
                rpoint = region_state_point(region_exposure[p], storm_point, heavy_point)
                ppoint = province_state_point(province_exposure[p], storm_point, heavy_point, province_region)
                rdraw = region_state_draws(region_exposure[p], storm_draw, heavy_draw)
                pdraw = province_state_draws(province_exposure[p], storm_draw, heavy_draw, province_region)

                if s == 0:
                    hist_region_by_pop[p] = rpoint[:, 0, :]
                    hist_province_by_pop[p] = ppoint[:, 0, :]

                rsummary = summarize(rpoint, rdraw, args.pct_denom_threshold)
                psummary = summarize(ppoint, pdraw, args.pct_denom_threshold)

                place_summary(region_store, rsummary, s, p)
                place_summary(province_store, psummary, s, p)

    figure4_nc = os.path.join(args.output_dir, "Figure4_plot_data.nc")
    figures10_nc = os.path.join(args.output_dir, "FigureS10_plot_data.nc")
    figure4_csv = os.path.join(args.output_dir, "Figure4_contribution_summary.csv")
    figures10_csv = os.path.join(args.output_dir, "FigureS10_contribution_summary.csv")
    qa_csv = os.path.join(args.output_dir, "Figure4_S10_contribution_QC.csv")

    create_plot_file(
        figure4_nc,
        "region",
        REGION_KEYS,
        REGION_NAMES,
        region_store,
        args.pct_denom_threshold,
    )
    create_plot_file(
        figures10_nc,
        "province",
        PROVINCE_NAMES,
        PROVINCE_NAMES,
        province_store,
        args.pct_denom_threshold,
    )
    write_summary_csv(
        figure4_csv,
        "region",
        REGION_KEYS,
        REGION_NAMES,
        region_store,
    )
    write_summary_csv(
        figures10_csv,
        "province",
        PROVINCE_NAMES,
        PROVINCE_NAMES,
        province_store,
    )
    write_qa(
        qa_csv,
        region_store,
        province_store,
        hist_region_by_pop,
        hist_province_by_pop,
        args,
    )

    print(figure4_nc)
    print(figures10_nc)
    print(figure4_csv)
    print(figures10_csv)
    print(qa_csv)

if __name__ == "__main__":
    main()
