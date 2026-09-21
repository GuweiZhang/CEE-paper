import os
import re
import csv
import json
import glob
import argparse
import calendar as pycalendar
import numpy as np
from netCDF4 import Dataset, num2date, date2num

MODELS = ["MPI", "CESM2", "IPSL"]
SCENARIOS = ["hist", "126", "245", "585"]
MODEL_DEFAULT_CALENDAR = {"MPI": "gregorian", "CESM2": "365_day", "IPSL": "gregorian"}
SSP_INDEX = {"126": 1, "245": 2, "585": 5}
REGION_NAMES = ["CN", "NE", "NC", "NW", "EC", "CC", "SC"]
CATEGORY_NAMES = ["storm", "heavy", "total"]
POP_TYPE_NAMES = ["total", "urban"]
RR_STORM_MEAN = np.array([1.147, 1.211, 1.021, 1.021, 1.295, 1.254], dtype=np.float64)
RR_STORM_LOW = np.array([0.647, 0.770, 0.436, 0.746, 0.825, 0.590], dtype=np.float64)
RR_STORM_HIGH = np.array([2.034, 1.906, 2.389, 1.396, 2.034, 2.665], dtype=np.float64)
RR_HEAVY_MEAN = np.array([np.nan, np.nan, np.nan, np.nan, 1.051, 1.151], dtype=np.float64)
RR_HEAVY_LOW = np.array([np.nan, np.nan, np.nan, np.nan, 0.834, 0.958], dtype=np.float64)
RR_HEAVY_HIGH = np.array([np.nan, np.nan, np.nan, np.nan, 1.324, 1.384], dtype=np.float64)
CACHE_VERSION = "3"

def canonical_calendar(value):
    value = str(value).lower()
    if value in ["365_day", "noleap"]:
        return "365_day"
    if value in ["360_day"]:
        return "360_day"
    return "gregorian"

def days_in_year(year, cal):
    if cal == "365_day":
        return 365
    if cal == "360_day":
        return 360
    return 366 if pycalendar.isleap(year) else 365

def total_expected(start_year, end_year, cal):
    return sum(days_in_year(y, cal) for y in range(start_year, end_year + 1))

def period_for_scenario(scenario):
    if scenario == "hist":
        return 1995, 2014
    return 2031, 2060

def read_mask(path, preferred):
    with Dataset(path, "r") as ds:
        name = preferred if preferred in ds.variables else "region_mask"
        a = ds.variables[name][:]
        if np.ma.isMaskedArray(a):
            a = a.filled(-9999)
        return np.asarray(a, dtype=np.int16)

def read_death_rate(path):
    with Dataset(path, "r") as ds:
        name = "death_rate_daily" if "death_rate_daily" in ds.variables else "death_rate"
        a = ds.variables[name][:]
        if np.ma.isMaskedArray(a):
            a = a.filled(np.nan)
        a = np.asarray(a, dtype=np.float64)
        if name == "death_rate":
            a = a / 365.0
        a[~np.isfinite(a)] = 0.0
        return a

def read_grid(path):
    with Dataset(path, "r") as ds:
        lat = np.asarray(ds.variables["XLAT"][:], dtype=np.float64)
        lon = np.asarray(ds.variables["XLONG"][:], dtype=np.float64)
    if lat.ndim == 3:
        lat = lat[0]
    if lon.ndim == 3:
        lon = lon[0]
    return lat, lon

def find_precip_file(directory, model, scenario):
    patterns = [
        f"{model}_PRAVG_hist_*_daily.nc" if scenario == "hist" else f"{model}_PRAVG_ssp{scenario}_*_daily.nc",
        f"*{model}*PRAVG*hist*daily*.nc" if scenario == "hist" else f"*{model}*PRAVG*ssp{scenario}*daily*.nc",
    ]
    matches = []
    for pattern in patterns:
        matches.extend(glob.glob(os.path.join(directory, pattern)))
    matches = sorted(set(p for p in matches if "POP" not in os.path.basename(p).upper()))
    if len(matches) == 1:
        return matches[0]
    if not matches:
        raise FileNotFoundError(f"No precipitation file found for {model} {scenario}")
    raise RuntimeError(f"Multiple precipitation files found for {model} {scenario}: {matches}")

def find_precip_variable(ds):
    for name in ["PRAVG", "pr", "precip", "precipitation"]:
        if name in ds.variables:
            return name
    raise KeyError("No precipitation variable found")

def precip_factor(var):
    units = str(getattr(var, "units", "")).lower().replace(" ", "")
    if ("kg" in units and ("s-1" in units or "/s" in units)) or "mm/s" in units or "mms-1" in units:
        return 86400.0
    return 1.0

def time_axis_is_good(ds, start_year, end_year):
    if "time" not in ds.variables:
        return False, None, None, None
    t = ds.variables["time"]
    units = getattr(t, "units", "")
    cal_raw = getattr(t, "calendar", "standard")
    try:
        dates = num2date(np.asarray(t[:], dtype=np.float64), units=units, calendar=cal_raw, only_use_cftime_datetimes=True)
        norm = np.asarray(date2num(dates, "days since 0001-01-01", calendar=cal_raw), dtype=np.float64)
        diffs = np.diff(norm)
        good = bool(np.all(np.isclose(diffs, 1.0, atol=1e-8)))
        years = np.asarray([d.year for d in dates], dtype=np.int32)
        if years.size == 0 or years[0] != start_year or years[-1] != end_year:
            good = False
        return good, dates, canonical_calendar(cal_raw), cal_raw
    except Exception:
        return False, None, None, cal_raw

def build_sequential_slices(records, start_year, end_year, cal):
    rows = []
    start = 0
    for year in range(start_year, end_year + 1):
        expected = days_in_year(year, cal)
        remaining = records - start
        if remaining <= 0:
            rows.append((year, start, start, 0, expected))
            continue
        actual = min(expected, remaining)
        end = start + actual
        rows.append((year, start, end, actual, expected))
        start = end
    if start != records:
        raise ValueError(f"{records - start} extra records remain after {end_year}")
    return rows

def choose_reconstructed_calendar(model, records, start_year, end_year):
    greg = total_expected(start_year, end_year, "gregorian")
    noleap = total_expected(start_year, end_year, "365_day")
    if records == greg:
        return "gregorian", "record count exactly matches Gregorian calendar"
    if records == noleap:
        return "365_day", "record count exactly matches 365_day calendar"
    preferred = MODEL_DEFAULT_CALENDAR[model]
    expected = total_expected(start_year, end_year, preferred)
    if 0 <= expected - records <= 31:
        return preferred, f"assumed {preferred} with {expected - records} terminal missing days"
    alternate = "365_day" if preferred == "gregorian" else "gregorian"
    alt_expected = total_expected(start_year, end_year, alternate)
    if 0 <= alt_expected - records <= 31:
        return alternate, f"assumed {alternate} with {alt_expected - records} terminal missing days"
    raise ValueError(f"Cannot infer calendar from {records} records for {model} {start_year}-{end_year}")

def get_year_slices(path, model, scenario):
    start_year, end_year = period_for_scenario(scenario)
    with Dataset(path, "r") as ds:
        pvar = find_precip_variable(ds)
        records = int(ds.variables[pvar].shape[0])
        good, dates, decoded_cal, raw_cal = time_axis_is_good(ds, start_year, end_year)
        if good:
            years = np.asarray([d.year for d in dates], dtype=np.int32)
            rows = []
            for year in range(start_year, end_year + 1):
                idx = np.where(years == year)[0]
                expected = days_in_year(year, decoded_cal)
                if idx.size == 0:
                    rows.append((year, 0, 0, 0, expected))
                else:
                    if not np.array_equal(idx, np.arange(idx[0], idx[-1] + 1)):
                        raise ValueError(f"Non-contiguous records within {year} in {path}")
                    rows.append((year, int(idx[0]), int(idx[-1] + 1), int(idx.size), expected))
            method = f"decoded time coordinate ({raw_cal})"
            return pvar, decoded_cal, method, rows
        cal, reason = choose_reconstructed_calendar(model, records, start_year, end_year)
        rows = build_sequential_slices(records, start_year, end_year, cal)
        method = f"reconstructed sequential axis: {reason}"
        return pvar, cal, method, rows

def read_precip_block(var, start, end, shape, factor):
    raw = var[start:end, ...]
    if np.ma.isMaskedArray(raw):
        raw = raw.filled(np.nan)
    a = np.asarray(raw, dtype=np.float64)
    while a.ndim > 3:
        singleton = [i for i in range(1, a.ndim - 2) if a.shape[i] == 1]
        if not singleton:
            raise ValueError(f"Unsupported precipitation shape {a.shape}")
        a = np.squeeze(a, axis=singleton[0])
    if a.ndim != 3 or a.shape[1:] != shape:
        raise ValueError(f"Precipitation shape {a.shape} does not match CWRF grid {shape}")
    for attr in ["_FillValue", "missing_value"]:
        if hasattr(var, attr):
            values = np.atleast_1d(getattr(var, attr)).astype(np.float64)
            for value in values:
                if np.isfinite(value):
                    a[a == value] = np.nan
    a[~np.isfinite(a)] = np.nan
    if factor != 1.0:
        a *= factor
    a[np.abs(a) > 1.0e6] = np.nan
    a[(a < 0.0) & (a > -1.0e-6)] = 0.0
    a[a < -1.0e-6] = np.nan
    return a

def rain_cache_path(cache_dir, model, scenario):
    return os.path.join(cache_dir, "rain_days", f"{model}_{scenario}_rain_days.nc")

def build_rain_cache(source, cache, model, scenario, grid_shape, heavy_min, storm_min, incomplete_policy):
    pvar, cal, method, rows = get_year_slices(source, model, scenario)
    os.makedirs(os.path.dirname(cache), exist_ok=True)
    with Dataset(source, "r") as src, Dataset(cache, "w", format="NETCDF4") as out:
        var = src.variables[pvar]
        factor = precip_factor(var)
        ny, nx = grid_shape
        out.createDimension("year", len(rows))
        out.createDimension("south_north", ny)
        out.createDimension("west_east", nx)
        vy = out.createVariable("year", "i4", ("year",))
        vo = out.createVariable("observed_days", "i2", ("year",))
        ve = out.createVariable("expected_days", "i2", ("year",))
        vs = out.createVariable("storm_days", "f4", ("year", "south_north", "west_east"), zlib=True, complevel=4)
        vh = out.createVariable("heavy_days", "f4", ("year", "south_north", "west_east"), zlib=True, complevel=4)
        vy[:] = [r[0] for r in rows]
        vo[:] = [r[3] for r in rows]
        ve[:] = [r[4] for r in rows]
        for i, (year, start, end, observed, expected) in enumerate(rows):
            print(f"{model} {scenario} {year}: {observed}/{expected} days")
            if observed == 0:
                vs[i] = np.zeros(grid_shape, dtype=np.float32)
                vh[i] = np.zeros(grid_shape, dtype=np.float32)
                continue
            data = read_precip_block(var, start, end, grid_shape, factor)
            finite = np.isfinite(data)
            storm = np.sum(finite & (data >= storm_min), axis=0).astype(np.float64)
            heavy = np.sum(finite & (data >= heavy_min) & (data < storm_min), axis=0).astype(np.float64)
            if incomplete_policy == "annualize" and observed < expected:
                scale = expected / observed
                storm *= scale
                heavy *= scale
            vs[i] = storm.astype(np.float32)
            vh[i] = heavy.astype(np.float32)
        out.source_file = os.path.abspath(source)
        out.calendar_used = cal
        out.time_handling = method
        out.incomplete_year_policy = incomplete_policy
        out.cache_version = CACHE_VERSION
        out.heavy_min = float(heavy_min)
        out.storm_min = float(storm_min)
    return rows, cal, method

def ensure_rain_cache(source, cache, model, scenario, grid_shape, heavy_min, storm_min, incomplete_policy, rebuild):
    if rebuild or not os.path.exists(cache):
        return build_rain_cache(source, cache, model, scenario, grid_shape, heavy_min, storm_min, incomplete_policy)
    with Dataset(cache, "r") as ds:
        same = (
            getattr(ds, "source_file", "") == os.path.abspath(source)
            and abs(float(getattr(ds, "heavy_min", -1)) - heavy_min) < 1e-8
            and abs(float(getattr(ds, "storm_min", -1)) - storm_min) < 1e-8
            and getattr(ds, "incomplete_year_policy", "") == incomplete_policy
            and getattr(ds, "cache_version", "") == CACHE_VERSION
        )
        if same:
            years = np.asarray(ds.variables["year"][:], dtype=int)
            observed = np.asarray(ds.variables["observed_days"][:], dtype=int)
            expected = np.asarray(ds.variables["expected_days"][:], dtype=int)
            rows = [(int(y), 0, 0, int(o), int(e)) for y, o, e in zip(years, observed, expected)]
            return rows, getattr(ds, "calendar_used", ""), getattr(ds, "time_handling", "")
    return build_rain_cache(source, cache, model, scenario, grid_shape, heavy_min, storm_min, incomplete_policy)

def coordinate_values(ds, dim_name, length, fallback):
    if dim_name in ds.variables:
        values = np.asarray(ds.variables[dim_name][:])
        if values.ndim == 1 and values.size == length:
            return values
    return np.asarray(fallback)

def population_axes(ds):
    var = ds.variables["pop"]
    if var.ndim != 4:
        raise ValueError(f"Population variable must be 4-D, got {var.shape}")
    d0, d1 = var.dimensions[:2]
    ssp = coordinate_values(ds, d0, var.shape[0], np.arange(1, var.shape[0] + 1))
    years = coordinate_values(ds, d1, var.shape[1], np.arange(2010, 2010 + var.shape[1]))
    return var, ssp, years

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
    idx_year = [int(np.where(years == y)[0][0]) for y in range(2010, 2015)]
    fields = []
    for i0 in range(var.shape[0]):
        for i1 in idx_year:
            fields.append(read_population_field(var, i0, i1))
    return np.mean(fields, axis=0)

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

def aggregate(a, mask, n):
    out = np.zeros(n, dtype=np.float64)
    for code in range(1, n + 1):
        out[code - 1] = np.sum(a[mask == code])
    return out

def safe_rate(deaths, population):
    deaths = np.asarray(deaths, dtype=np.float64)
    population = np.asarray(population, dtype=np.float64)
    out = np.full(np.broadcast_shapes(deaths.shape, population.shape), np.nan, dtype=np.float64)
    d, p = np.broadcast_arrays(deaths, population)
    valid = np.isfinite(d) & np.isfinite(p) & (p > 0)
    out[valid] = d[valid] / p[valid]
    return out

def rr_af_point():
    storm = (RR_STORM_MEAN - 1.0) / RR_STORM_MEAN
    heavy = np.zeros(6, dtype=np.float64)
    active = np.isfinite(RR_HEAVY_MEAN)
    heavy[active] = (RR_HEAVY_MEAN[active] - 1.0) / RR_HEAVY_MEAN[active]
    return storm, heavy

def af_fields(region):
    storm, heavy = rr_af_point()
    sf = np.zeros(region.shape, dtype=np.float64)
    hf = np.zeros(region.shape, dtype=np.float64)
    for code in range(1, 7):
        sf[region == code] = storm[code - 1]
        hf[region == code] = heavy[code - 1]
    return sf, hf

def mc_af(n, seed):
    rng = np.random.default_rng(seed)
    storm_se = (np.log(RR_STORM_HIGH) - np.log(RR_STORM_LOW)) / (2 * 1.96)
    storm_rr = np.exp(rng.normal(np.log(RR_STORM_MEAN), storm_se, size=(n, 6)))
    storm = (storm_rr - 1.0) / storm_rr
    heavy = np.zeros((n, 6), dtype=np.float64)
    active = np.isfinite(RR_HEAVY_MEAN)
    heavy_se = (np.log(RR_HEAVY_HIGH[active]) - np.log(RR_HEAVY_LOW[active])) / (2 * 1.96)
    heavy_rr = np.exp(rng.normal(np.log(RR_HEAVY_MEAN[active]), heavy_se, size=(n, active.sum())))
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

def create_output(path, years, lat, lon):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    ds = Dataset(path, "w", format="NETCDF4")
    ny, nx = lat.shape
    for name, size in [("pop_type", 2), ("model", 3), ("year", len(years)), ("category", 3), ("region", 7), ("province", 32), ("south_north", ny), ("west_east", nx)]:
        ds.createDimension(name, size)
    ds.createVariable("year", "i4", ("year",))[:] = years
    ds.createVariable("XLAT", "f4", ("south_north", "west_east"))[:] = lat.astype(np.float32)
    ds.createVariable("XLONG", "f4", ("south_north", "west_east"))[:] = lon.astype(np.float32)
    v = ds.createVariable("deaths_point", "f4", ("pop_type", "model", "year", "category", "south_north", "west_east"), zlib=True, complevel=4)
    v.units = "deaths yr-1"
    v = ds.createVariable("region_deaths_point", "f8", ("pop_type", "model", "year", "region", "category"), zlib=True, complevel=4)
    v.units = "deaths yr-1"
    v = ds.createVariable("province_deaths_point", "f8", ("pop_type", "model", "year", "province", "category"), zlib=True, complevel=4)
    v.units = "deaths yr-1"
    v = ds.createVariable("region_mortality_rate_point", "f8", ("pop_type", "model", "year", "region", "category"), zlib=True, complevel=4)
    v.units = "deaths person-1 yr-1"
    v.definition = "attributable deaths divided by population"
    v = ds.createVariable("province_mortality_rate_point", "f8", ("pop_type", "model", "year", "province", "category"), zlib=True, complevel=4)
    v.units = "deaths person-1 yr-1"
    v.definition = "attributable deaths divided by population"
    v = ds.createVariable("region_population", "f8", ("pop_type", "year", "region"), zlib=True, complevel=4)
    v.units = "persons"
    v = ds.createVariable("province_population", "f8", ("pop_type", "year", "province"), zlib=True, complevel=4)
    v.units = "persons"
    for name in ["region_deaths_point_ensemble", "region_deaths_ci_low", "region_deaths_ci_high"]:
        v = ds.createVariable(name, "f8", ("pop_type", "year", "region"), zlib=True, complevel=4)
        v.units = "deaths yr-1"
    for name in ["region_mortality_rate_point_ensemble", "region_mortality_rate_ci_low", "region_mortality_rate_ci_high"]:
        v = ds.createVariable(name, "f8", ("pop_type", "year", "region"), zlib=True, complevel=4)
        v.units = "deaths person-1 yr-1"
        v.definition = "attributable deaths divided by population"
    for name in ["province_deaths_point_ensemble", "province_deaths_ci_low", "province_deaths_ci_high"]:
        v = ds.createVariable(name, "f8", ("pop_type", "year", "province"), zlib=True, complevel=4)
        v.units = "deaths yr-1"
    for name in ["province_mortality_rate_point_ensemble", "province_mortality_rate_ci_low", "province_mortality_rate_ci_high"]:
        v = ds.createVariable(name, "f8", ("pop_type", "year", "province"), zlib=True, complevel=4)
        v.units = "deaths person-1 yr-1"
        v.definition = "attributable deaths divided by population"
    for name in ["region_deaths_period_point", "region_deaths_period_ci_low", "region_deaths_period_ci_high"]:
        v = ds.createVariable(name, "f8", ("pop_type", "region"), zlib=True, complevel=4)
        v.units = "deaths yr-1"
    for name in ["region_mortality_rate_period_point", "region_mortality_rate_period_ci_low", "region_mortality_rate_period_ci_high"]:
        v = ds.createVariable(name, "f8", ("pop_type", "region"), zlib=True, complevel=4)
        v.units = "deaths person-1 yr-1"
        v.definition = "period-mean attributable deaths divided by period-mean population"
    for name in ["province_deaths_period_point", "province_deaths_period_ci_low", "province_deaths_period_ci_high"]:
        v = ds.createVariable(name, "f8", ("pop_type", "province"), zlib=True, complevel=4)
        v.units = "deaths yr-1"
    for name in ["province_mortality_rate_period_point", "province_mortality_rate_period_ci_low", "province_mortality_rate_period_ci_high"]:
        v = ds.createVariable(name, "f8", ("pop_type", "province"), zlib=True, complevel=4)
        v.units = "deaths person-1 yr-1"
        v.definition = "period-mean attributable deaths divided by period-mean population"
    ds.pop_type_names = ",".join(POP_TYPE_NAMES)
    ds.model_names = ",".join(MODELS)
    ds.category_names = ",".join(CATEGORY_NAMES)
    ds.region_names = ",".join(REGION_NAMES)
    return ds

def compute_uncertainty(ds, brs, brh, bps, bph, storm_draws, heavy_draws):
    nmc = storm_draws.shape[0]
    region_point = np.asarray(ds.variables["region_deaths_point"][:, :, :, :, 2], dtype=np.float64)
    province_point = np.asarray(ds.variables["province_deaths_point"][:, :, :, :, 2], dtype=np.float64)
    region_population = np.asarray(ds.variables["region_population"][:], dtype=np.float64)
    province_population = np.asarray(ds.variables["province_population"][:], dtype=np.float64)
    ds.variables["region_deaths_point_ensemble"][:] = np.mean(region_point, axis=1)
    ds.variables["province_deaths_point_ensemble"][:] = np.mean(province_point, axis=1)
    ds.variables["region_mortality_rate_point_ensemble"][:] = safe_rate(np.mean(region_point, axis=1), region_population)
    ds.variables["province_mortality_rate_point_ensemble"][:] = safe_rate(np.mean(province_point, axis=1), province_population)
    n_year = region_point.shape[2]
    province_region = province_region_codes()
    for p in range(2):
        region_low = np.zeros((n_year, 7), dtype=np.float64)
        region_high = np.zeros((n_year, 7), dtype=np.float64)
        province_low = np.zeros((n_year, 32), dtype=np.float64)
        province_high = np.zeros((n_year, 32), dtype=np.float64)
        region_rate_low = np.zeros((n_year, 7), dtype=np.float64)
        region_rate_high = np.zeros((n_year, 7), dtype=np.float64)
        province_rate_low = np.zeros((n_year, 32), dtype=np.float64)
        province_rate_high = np.zeros((n_year, 32), dtype=np.float64)
        for y in range(n_year):
            rdraws = np.zeros((nmc, 3, 7), dtype=np.float64)
            for r in range(6):
                rdraws[:, :, r + 1] = storm_draws[:, r, None] * brs[p, :, y, r][None, :] + heavy_draws[:, r, None] * brh[p, :, y, r][None, :]
            rdraws[:, :, 0] = np.sum(rdraws[:, :, 1:], axis=2)
            rflat = rdraws.reshape(nmc * 3, 7)
            region_low[y] = np.quantile(rflat, 0.025, axis=0)
            region_high[y] = np.quantile(rflat, 0.975, axis=0)
            rrate = safe_rate(rflat, region_population[p, y][None, :])
            region_rate_low[y] = np.quantile(rrate, 0.025, axis=0)
            region_rate_high[y] = np.quantile(rrate, 0.975, axis=0)
            pdraws = np.zeros((nmc, 3, 32), dtype=np.float64)
            for ip in range(32):
                r = province_region[ip] - 1
                pdraws[:, :, ip] = storm_draws[:, r, None] * bps[p, :, y, ip][None, :] + heavy_draws[:, r, None] * bph[p, :, y, ip][None, :]
            pflat = pdraws.reshape(nmc * 3, 32)
            province_low[y] = np.quantile(pflat, 0.025, axis=0)
            province_high[y] = np.quantile(pflat, 0.975, axis=0)
            prate = safe_rate(pflat, province_population[p, y][None, :])
            province_rate_low[y] = np.quantile(prate, 0.025, axis=0)
            province_rate_high[y] = np.quantile(prate, 0.975, axis=0)
        ds.variables["region_deaths_ci_low"][p] = region_low
        ds.variables["region_deaths_ci_high"][p] = region_high
        ds.variables["region_mortality_rate_ci_low"][p] = region_rate_low
        ds.variables["region_mortality_rate_ci_high"][p] = region_rate_high
        ds.variables["province_deaths_ci_low"][p] = province_low
        ds.variables["province_deaths_ci_high"][p] = province_high
        ds.variables["province_mortality_rate_ci_low"][p] = province_rate_low
        ds.variables["province_mortality_rate_ci_high"][p] = province_rate_high
        rperiod = np.zeros((nmc, 3, 7), dtype=np.float64)
        for r in range(6):
            rperiod[:, :, r + 1] = storm_draws[:, r, None] * np.mean(brs[p, :, :, r], axis=1)[None, :] + heavy_draws[:, r, None] * np.mean(brh[p, :, :, r], axis=1)[None, :]
        rperiod[:, :, 0] = np.sum(rperiod[:, :, 1:], axis=2)
        rflat = rperiod.reshape(nmc * 3, 7)
        mean_rpop = np.mean(region_population[p], axis=0)
        ds.variables["region_deaths_period_ci_low"][p] = np.quantile(rflat, 0.025, axis=0)
        ds.variables["region_deaths_period_ci_high"][p] = np.quantile(rflat, 0.975, axis=0)
        ds.variables["region_deaths_period_point"][p] = np.mean(region_point[p], axis=(0, 1))
        rrate = safe_rate(rflat, mean_rpop[None, :])
        ds.variables["region_mortality_rate_period_ci_low"][p] = np.quantile(rrate, 0.025, axis=0)
        ds.variables["region_mortality_rate_period_ci_high"][p] = np.quantile(rrate, 0.975, axis=0)
        ds.variables["region_mortality_rate_period_point"][p] = safe_rate(ds.variables["region_deaths_period_point"][p][:], mean_rpop)
        pperiod = np.zeros((nmc, 3, 32), dtype=np.float64)
        for ip in range(32):
            r = province_region[ip] - 1
            pperiod[:, :, ip] = storm_draws[:, r, None] * np.mean(bps[p, :, :, ip], axis=1)[None, :] + heavy_draws[:, r, None] * np.mean(bph[p, :, :, ip], axis=1)[None, :]
        pflat = pperiod.reshape(nmc * 3, 32)
        mean_ppop = np.mean(province_population[p], axis=0)
        ds.variables["province_deaths_period_ci_low"][p] = np.quantile(pflat, 0.025, axis=0)
        ds.variables["province_deaths_period_ci_high"][p] = np.quantile(pflat, 0.975, axis=0)
        ds.variables["province_deaths_period_point"][p] = np.mean(province_point[p], axis=(0, 1))
        prate = safe_rate(pflat, mean_ppop[None, :])
        ds.variables["province_mortality_rate_period_ci_low"][p] = np.quantile(prate, 0.025, axis=0)
        ds.variables["province_mortality_rate_period_ci_high"][p] = np.quantile(prate, 0.975, axis=0)
        ds.variables["province_mortality_rate_period_point"][p] = safe_rate(ds.variables["province_deaths_period_point"][p][:], mean_ppop)

def run_scenario(scenario, args, province, region, death_rate, lat, lon, total_ds, urban_ds, storm_draws, heavy_draws, time_rows):
    start_year, end_year = period_for_scenario(scenario)
    years = np.arange(start_year, end_year + 1, dtype=np.int32)
    if scenario == "hist":
        total_base = historical_population(total_ds)
        urban_base = historical_population(urban_ds)
        total_pop = np.repeat(total_base[None, :, :], len(years), axis=0)
        urban_pop = np.repeat(urban_base[None, :, :], len(years), axis=0)
    else:
        ssp = SSP_INDEX[scenario]
        total_pop = future_population(total_ds, ssp, years)
        urban_pop = future_population(urban_ds, ssp, years)
    output = os.path.join(args.output_dir, f"CWRF_mortality_{'hist_1995-2014' if scenario == 'hist' else 'ssp'+scenario+'_2031-2060'}.nc")
    dsout = create_output(output, years, lat, lon)
    dsout.scenario = scenario
    dsout.incomplete_year_policy = args.incomplete_policy
    dsout.af_definition = "(RR-1)/RR"
    dsout.mortality_rate_definition = "attributable deaths divided by the corresponding total or urban population"
    dsout.monte_carlo_draws = args.n_mc
    sf, hf = af_fields(region)
    n_year = len(years)
    region_population = np.zeros((2, n_year, 7), dtype=np.float64)
    province_population = np.zeros((2, n_year, 32), dtype=np.float64)
    brs = np.zeros((2, 3, n_year, 6), dtype=np.float64)
    brh = np.zeros((2, 3, n_year, 6), dtype=np.float64)
    bps = np.zeros((2, 3, n_year, 32), dtype=np.float64)
    bph = np.zeros((2, 3, n_year, 32), dtype=np.float64)
    for y in range(n_year):
        for p, pop in enumerate([total_pop[y], urban_pop[y]]):
            regpop = aggregate(pop, region, 6)
            provpop = aggregate(pop, province, 32)
            region_population[p, y, 0] = np.sum(regpop)
            region_population[p, y, 1:] = regpop
            province_population[p, y] = provpop
            dsout.variables["region_population"][p, y] = region_population[p, y]
            dsout.variables["province_population"][p, y] = province_population[p, y]
    for im, model in enumerate(MODELS):
        source = find_precip_file(args.cwrf_dir, model, scenario)
        cache = rain_cache_path(args.cache_dir, model, scenario)
        rows, cal, method = ensure_rain_cache(source, cache, model, scenario, lat.shape, args.heavy_min, args.storm_min, args.incomplete_policy, args.rebuild_cache)
        for year, _, _, observed, expected in rows:
            time_rows.append([scenario, model, os.path.basename(source), cal, year, observed, expected, observed - expected, method])
        with Dataset(cache, "r") as rain:
            storm_days = rain.variables["storm_days"]
            heavy_days = rain.variables["heavy_days"]
            for iy in range(n_year):
                storm = np.asarray(storm_days[iy], dtype=np.float64)
                heavy = np.asarray(heavy_days[iy], dtype=np.float64)
                for p, pop in enumerate([total_pop[iy], urban_pop[iy]]):
                    base = pop * death_rate
                    bs = base * storm
                    bh = base * heavy
                    death_storm = bs * sf
                    death_heavy = bh * hf
                    death_total = death_storm + death_heavy
                    dsout.variables["deaths_point"][p, im, iy, 0] = death_storm.astype(np.float32)
                    dsout.variables["deaths_point"][p, im, iy, 1] = death_heavy.astype(np.float32)
                    dsout.variables["deaths_point"][p, im, iy, 2] = death_total.astype(np.float32)
                    rs = aggregate(death_storm, region, 6)
                    rh = aggregate(death_heavy, region, 6)
                    rt = rs + rh
                    region_deaths = np.zeros((7, 3), dtype=np.float64)
                    region_deaths[0, 0] = np.sum(rs)
                    region_deaths[0, 1] = np.sum(rh)
                    region_deaths[0, 2] = np.sum(rt)
                    region_deaths[1:, 0] = rs
                    region_deaths[1:, 1] = rh
                    region_deaths[1:, 2] = rt
                    dsout.variables["region_deaths_point"][p, im, iy] = region_deaths
                    dsout.variables["region_mortality_rate_point"][p, im, iy] = safe_rate(region_deaths, region_population[p, iy, :, None])
                    ps = aggregate(death_storm, province, 32)
                    ph = aggregate(death_heavy, province, 32)
                    pt = ps + ph
                    province_deaths = np.stack([ps, ph, pt], axis=1)
                    dsout.variables["province_deaths_point"][p, im, iy] = province_deaths
                    dsout.variables["province_mortality_rate_point"][p, im, iy] = safe_rate(province_deaths, province_population[p, iy, :, None])
                    brs[p, im, iy] = aggregate(bs, region, 6)
                    brh[p, im, iy] = aggregate(bh, region, 6)
                    bps[p, im, iy] = aggregate(bs, province, 32)
                    bph[p, im, iy] = aggregate(bh, province, 32)
        print(f"Finished {model} {scenario}")
    compute_uncertainty(dsout, brs, brh, bps, bph, storm_draws, heavy_draws)
    dsout.close()
    print(f"Created: {output}")
    return output

def write_time_report(rows, path):
    with open(path, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f, delimiter="\t")
        writer.writerow(["scenario", "model", "file", "calendar_used", "year", "observed_days", "expected_days", "difference", "time_handling"])
        writer.writerows(rows)

def write_summary(paths, path):
    rows = []
    province_rows = []
    for file in paths:
        with Dataset(file, "r") as ds:
            scenario = getattr(ds, "scenario")
            rdeath = np.asarray(ds.variables["region_deaths_period_point"][:], dtype=np.float64)
            rlow = np.asarray(ds.variables["region_deaths_period_ci_low"][:], dtype=np.float64)
            rhigh = np.asarray(ds.variables["region_deaths_period_ci_high"][:], dtype=np.float64)
            rrate = np.asarray(ds.variables["region_mortality_rate_period_point"][:], dtype=np.float64)
            rrate_low = np.asarray(ds.variables["region_mortality_rate_period_ci_low"][:], dtype=np.float64)
            rrate_high = np.asarray(ds.variables["region_mortality_rate_period_ci_high"][:], dtype=np.float64)
            rpop = np.mean(np.asarray(ds.variables["region_population"][:], dtype=np.float64), axis=1)
            pdeath = np.asarray(ds.variables["province_deaths_period_point"][:], dtype=np.float64)
            plow = np.asarray(ds.variables["province_deaths_period_ci_low"][:], dtype=np.float64)
            phigh = np.asarray(ds.variables["province_deaths_period_ci_high"][:], dtype=np.float64)
            prate = np.asarray(ds.variables["province_mortality_rate_period_point"][:], dtype=np.float64)
            prate_low = np.asarray(ds.variables["province_mortality_rate_period_ci_low"][:], dtype=np.float64)
            prate_high = np.asarray(ds.variables["province_mortality_rate_period_ci_high"][:], dtype=np.float64)
            ppop = np.mean(np.asarray(ds.variables["province_population"][:], dtype=np.float64), axis=1)
            for p, pname in enumerate(POP_TYPE_NAMES):
                for r, rname in enumerate(REGION_NAMES):
                    rows.append([scenario, pname, rname, rdeath[p, r], rlow[p, r], rhigh[p, r], rpop[p, r], rrate[p, r], rrate_low[p, r], rrate_high[p, r], rrate[p, r] * 1e5])
                for ip in range(32):
                    province_rows.append([scenario, pname, ip + 1, pdeath[p, ip], plow[p, ip], phigh[p, ip], ppop[p, ip], prate[p, ip], prate_low[p, ip], prate_high[p, ip], prate[p, ip] * 1e5])
    with open(path, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(["scenario", "population_type", "region", "annual_deaths_point", "annual_deaths_ci_low", "annual_deaths_ci_high", "period_mean_population", "mortality_rate_point", "mortality_rate_ci_low", "mortality_rate_ci_high", "mortality_rate_per_100000_point"])
        writer.writerows(rows)
    province_path = os.path.join(os.path.dirname(path), "CWRF_mortality_province_period_summary.csv")
    with open(province_path, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(["scenario", "population_type", "province_code", "annual_deaths_point", "annual_deaths_ci_low", "annual_deaths_ci_high", "period_mean_population", "mortality_rate_point", "mortality_rate_ci_low", "mortality_rate_ci_high", "mortality_rate_per_100000_point"])
        writer.writerows(province_rows)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--province-mask", default="0.province_CWRF.nc")
    parser.add_argument("--region-mask", default="0.region_CWRF.nc")
    parser.add_argument("--death-rate", default="1.death-rate_CWRF.nc")
    parser.add_argument("--total-pop", default="total_pop_CWRF.nc")
    parser.add_argument("--urban-pop", default="urban_pop_CWRF.nc")
    parser.add_argument("--cwrf-dir", default="../CWRF")
    parser.add_argument("--cache-dir", default="cache_cwrf_mortality")
    parser.add_argument("--output-dir", default="CWRF_mortality")
    parser.add_argument("--heavy-min", type=float, default=25.0)
    parser.add_argument("--storm-min", type=float, default=50.0)
    parser.add_argument("--n-mc", type=int, default=1000)
    parser.add_argument("--seed", type=int, default=20260811)
    parser.add_argument("--scenarios", nargs="+", default=SCENARIOS)
    parser.add_argument("--incomplete-policy", choices=["observed", "annualize"], default="observed")
    parser.add_argument("--rebuild-cache", action="store_true")
    args = parser.parse_args()
    os.makedirs(args.cache_dir, exist_ok=True)
    os.makedirs(args.output_dir, exist_ok=True)
    province = read_mask(args.province_mask, "province_mask")
    region = read_mask(args.region_mask, "region_mask")
    death_rate = read_death_rate(args.death_rate)
    lat, lon = read_grid(args.region_mask)
    if province.shape != region.shape or region.shape != death_rate.shape or region.shape != lat.shape:
        raise ValueError("Static CWRF grids do not match")
    storm_draws, heavy_draws = mc_af(args.n_mc, args.seed)
    time_rows = []
    outputs = []
    with Dataset(args.total_pop, "r") as total_ds, Dataset(args.urban_pop, "r") as urban_ds:
        for scenario in args.scenarios:
            outputs.append(run_scenario(scenario, args, province, region, death_rate, lat, lon, total_ds, urban_ds, storm_draws, heavy_draws, time_rows))
    write_time_report(time_rows, os.path.join(args.output_dir, "CWRF_mortality_time_handling.tsv"))
    write_summary(outputs, os.path.join(args.output_dir, "CWRF_mortality_period_summary.csv"))

if __name__ == "__main__":
    main()
