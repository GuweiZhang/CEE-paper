import os
import csv
import json
import hashlib
import argparse
import numpy as np
from netCDF4 import Dataset
import shapefile
from shapely.geometry import shape, Polygon
from shapely.ops import unary_union, transform
from shapely.strtree import STRtree
from pyproj import CRS, Transformer

PROVINCE_NAMES = [
    "Heilongjiang Sheng",
    "Jilin Sheng",
    "Liaoning Sheng",
    "Beijing Shi",
    "Tianjin Shi",
    "Hebei Sheng",
    "SHanxi Sheng",
    "Neimongol Zizhiqu",
    "Ningxiahuizu Zizhiqu",
    "Shanxi Sheng",
    "Gansu Sheng",
    "Qinghai Sheng",
    "Xinjianguygur Zizhiqu",
    "Shandong Sheng",
    "Jiangsu Sheng",
    "Shanghai Shi",
    "Zhejiang Sheng",
    "Anhui Sheng",
    "Jiangxi Sheng",
    "Fujian Sheng",
    "Henan Sheng",
    "Hubei Sheng",
    "Hunan Sheng",
    "Chongqing Shi",
    "Sichuan Sheng",
    "Yunnan Sheng",
    "Guizhou Sheng",
    "Xizang Zizhiqu",
    "Guangxizhuangzu Zizhiqu",
    "Guangdong Sheng",
    "Hainan Sheng",
    "Taiwan Sheng",
]

HONG_KONG_MACAO = [
    "Hongkong Tebiexingzhengqu",
    "Aomen Tebiexingzhengqu",
]

HAINAN_ISLANDS = [
    "Xisha Qundao",
    "Zhongsha Qundao",
    "Nansha Qundao",
]

REGION_NAMES = ["NE", "NC", "NW", "EC", "CC", "SC"]

def file_signature(paths):
    h = hashlib.sha1()
    for path in paths:
        if not os.path.exists(path):
            continue
        stat = os.stat(path)
        h.update(os.path.abspath(path).encode())
        h.update(str(stat.st_size).encode())
        h.update(str(stat.st_mtime_ns).encode())
    return h.hexdigest()

def grid_hash(lat, lon):
    h = hashlib.sha1()
    for arr in [lat, lon]:
        a = np.ascontiguousarray(np.asarray(arr))
        h.update(str(a.shape).encode())
        h.update(str(a.dtype).encode())
        h.update(a.tobytes())
    return h.hexdigest()

def read_cwrf_grid(path):
    with Dataset(path, "r") as ds:
        lat = np.asarray(ds.variables["XLAT"][:], dtype=np.float64)
        lon = np.asarray(ds.variables["XLONG"][:], dtype=np.float64)
    if lat.ndim == 3:
        lat = lat[0]
    if lon.ndim == 3:
        lon = lon[0]
    if lat.ndim != 2 or lon.ndim != 2:
        raise ValueError("XLAT and XLONG must be 2-D.")
    return lat, lon

def infer_2d_corners(center):
    center = np.asarray(center, dtype=np.float64)
    ny, nx = center.shape
    padded = np.empty((ny + 2, nx + 2), dtype=np.float64)
    padded[1:-1, 1:-1] = center
    padded[0, 1:-1] = 2.0 * center[0, :] - center[1, :]
    padded[-1, 1:-1] = 2.0 * center[-1, :] - center[-2, :]
    padded[1:-1, 0] = 2.0 * center[:, 0] - center[:, 1]
    padded[1:-1, -1] = 2.0 * center[:, -1] - center[:, -2]
    padded[0, 0] = padded[0, 1] + padded[1, 0] - padded[1, 1]
    padded[0, -1] = padded[0, -2] + padded[1, -1] - padded[1, -2]
    padded[-1, 0] = padded[-2, 0] + padded[-1, 1] - padded[-2, 1]
    padded[-1, -1] = padded[-2, -1] + padded[-1, -2] - padded[-2, -2]
    return 0.25 * (
        padded[:-1, :-1]
        + padded[1:, :-1]
        + padded[:-1, 1:]
        + padded[1:, 1:]
    )

def open_shapefile(path):
    last_error = None
    for encoding in ["utf-8", "gbk", "latin1"]:
        try:
            reader = shapefile.Reader(path, encoding=encoding)
            reader.shapeRecords()
            return reader
        except Exception as exc:
            last_error = exc
    raise RuntimeError(f"Unable to read shapefile: {last_error}")

def read_province_geometries(shp_path, field_name):
    reader = open_shapefile(shp_path)
    fields = [f[0] for f in reader.fields[1:]]
    if field_name not in fields:
        raise KeyError(f"Field {field_name} not found. Available fields: {fields}")
    field_index = fields.index(field_name)

    geometries = {}
    for sr in reader.iterShapeRecords():
        name = str(sr.record[field_index]).strip()
        geom = shape(sr.shape.__geo_interface__)
        if geom.is_empty:
            continue
        if not geom.is_valid:
            geom = geom.buffer(0)
        geometries.setdefault(name, []).append(geom)

    province_geoms = {}
    missing = []

    for code, name in enumerate(PROVINCE_NAMES[:31], start=1):
        parts = list(geometries.get(name, []))
        if code == 30:
            for extra in HONG_KONG_MACAO:
                parts.extend(geometries.get(extra, []))
        if code == 31:
            for extra in HAINAN_ISLANDS:
                parts.extend(geometries.get(extra, []))
        if not parts:
            missing.append(name)
            continue
        geom = unary_union(parts)
        if not geom.is_valid:
            geom = geom.buffer(0)
        province_geoms[code] = geom

    taiwan_parts = geometries.get("Taiwan Sheng", [])
    if taiwan_parts:
        geom = unary_union(taiwan_parts)
        if not geom.is_valid:
            geom = geom.buffer(0)
        province_geoms[32] = geom
    else:
        missing.append("Taiwan Sheng")

    if missing:
        raise ValueError(f"Shapefile names not found: {missing}")

    return province_geoms

def region_from_province(province):
    region = np.full(province.shape, -9999, dtype=np.int16)
    region[(province >= 1) & (province <= 3)] = 1
    region[(province >= 4) & (province <= 8)] = 2
    region[(province >= 9) & (province <= 13)] = 3
    region[(province >= 14) & (province <= 20)] = 4
    region[(province >= 21) & (province <= 23)] = 5
    region[(province >= 24) & (province <= 32)] = 6
    return region

def build_province_mask(lat, lon, province_geoms):
    lon_unwrapped = np.rad2deg(np.unwrap(np.deg2rad(lon), axis=1))
    lat_corner = infer_2d_corners(lat)
    lon_corner = infer_2d_corners(lon_unwrapped)

    lat0 = float(np.nanmean(lat))
    lon0 = float(np.nanmean(lon_unwrapped))
    equal_area = CRS.from_proj4(
        f"+proj=laea +lat_0={lat0:.8f} +lon_0={lon0:.8f} +datum=WGS84 +units=m +no_defs"
    )
    transformer = Transformer.from_crs(CRS.from_epsg(4326), equal_area, always_xy=True)

    projected_geoms = []
    projected_codes = []

    for code in sorted(province_geoms):
        geom = transform(transformer.transform, province_geoms[code])
        if not geom.is_valid:
            geom = geom.buffer(0)
        projected_geoms.append(geom)
        projected_codes.append(code)

    tree = STRtree(projected_geoms)
    geom_id_to_index = {id(g): i for i, g in enumerate(projected_geoms)}

    ny, nx = lat.shape
    province = np.full((ny, nx), -9999, dtype=np.int16)
    overlap_fraction = np.zeros((ny, nx), dtype=np.float32)
    cell_area_km2 = np.zeros((ny, nx), dtype=np.float32)

    for iy in range(ny):
        if iy % 20 == 0 or iy == ny - 1:
            print(f"Processing CWRF row {iy + 1}/{ny}")

        for ix in range(nx):
            lons = [
                lon_corner[iy, ix],
                lon_corner[iy, ix + 1],
                lon_corner[iy + 1, ix + 1],
                lon_corner[iy + 1, ix],
            ]
            lats = [
                lat_corner[iy, ix],
                lat_corner[iy, ix + 1],
                lat_corner[iy + 1, ix + 1],
                lat_corner[iy + 1, ix],
            ]

            x, y = transformer.transform(lons, lats)
            cell = Polygon(zip(x, y))

            if not cell.is_valid:
                cell = cell.buffer(0)

            area = cell.area
            if area <= 0:
                continue

            cell_area_km2[iy, ix] = area / 1.0e6
            candidates = tree.query(cell)

            if len(candidates) == 0:
                continue

            first = candidates[0]
            if isinstance(first, (int, np.integer)):
                candidate_indices = [int(v) for v in candidates]
            else:
                candidate_indices = [geom_id_to_index[id(g)] for g in candidates]

            best_code = -9999
            best_area = 0.0

            for index in candidate_indices:
                geom = projected_geoms[index]
                if not cell.intersects(geom):
                    continue
                inter = cell.intersection(geom)
                if inter.is_empty:
                    continue
                overlap = inter.area
                if overlap > best_area:
                    best_area = overlap
                    best_code = projected_codes[index]

            if best_code > 0:
                province[iy, ix] = best_code
                overlap_fraction[iy, ix] = best_area / area

    return province, overlap_fraction, cell_area_km2

def compute_death_rates(province_code_file, province_death_file):
    province_code = np.loadtxt(province_code_file, dtype=np.int64).reshape(-1)
    province_death = np.loadtxt(province_death_file, dtype=np.float64)

    if province_death.ndim == 1:
        province_death = province_death.reshape(1, -1)

    if province_death.shape[1] < 3:
        raise ValueError("Province death file must contain at least three columns.")

    if province_death.shape[0] != province_code.size:
        raise ValueError(
            f"Row mismatch: {province_code_file} has {province_code.size} codes, "
            f"but {province_death_file} has {province_death.shape[0]} rows."
        )

    rates = np.full(32, np.nan, dtype=np.float64)

    for code in range(1, 32):
        mask = province_code == code
        denominator = np.sum(province_death[mask, 0])
        numerator = np.sum(province_death[mask, 2])

        if denominator <= 0:
            raise ValueError(f"Invalid denominator for province code {code}.")

        rates[code - 1] = numerator * 365.0 / denominator

    rates[31] = 6.3 / 1000.0
    return rates

def write_mask_file(path, lat, lon, variable_name, values, long_name, names):
    ny, nx = lat.shape

    with Dataset(path, "w", format="NETCDF4") as ds:
        ds.createDimension("south_north", ny)
        ds.createDimension("west_east", nx)

        vlat = ds.createVariable("XLAT", "f4", ("south_north", "west_east"))
        vlon = ds.createVariable("XLONG", "f4", ("south_north", "west_east"))
        var = ds.createVariable(
            variable_name,
            "i2",
            ("south_north", "west_east"),
            fill_value=np.int16(-9999),
            zlib=True,
            complevel=4,
        )

        vlat[:] = lat.astype(np.float32)
        vlon[:] = lon.astype(np.float32)
        var[:] = np.ma.masked_equal(values, -9999)

        vlat.units = "degrees_north"
        vlon.units = "degrees_east"
        var.long_name = long_name
        var.coordinates = "XLAT XLONG"

        ds.grid = "native CWRF 30-km grid"
        ds.assignment_method = "maximum area overlap between CWRF grid cells and administrative polygons"
        ds.names = "|".join(names)

def write_death_rate_file(path, lat, lon, province, rates):
    ny, nx = lat.shape
    annual = np.full((ny, nx), np.nan, dtype=np.float64)

    for code in range(1, 33):
        annual[province == code] = rates[code - 1]

    daily = annual / 365.0

    with Dataset(path, "w", format="NETCDF4") as ds:
        ds.createDimension("south_north", ny)
        ds.createDimension("west_east", nx)
        ds.createDimension("province", 32)

        vlat = ds.createVariable("XLAT", "f4", ("south_north", "west_east"))
        vlon = ds.createVariable("XLONG", "f4", ("south_north", "west_east"))
        vrate = ds.createVariable(
            "death_rate",
            "f4",
            ("south_north", "west_east"),
            fill_value=np.float32(-9999.0),
            zlib=True,
            complevel=4,
        )
        vdaily = ds.createVariable(
            "death_rate_daily",
            "f4",
            ("south_north", "west_east"),
            fill_value=np.float32(-9999.0),
            zlib=True,
            complevel=4,
        )
        vprov = ds.createVariable("province_rate", "f8", ("province",))

        vlat[:] = lat.astype(np.float32)
        vlon[:] = lon.astype(np.float32)
        vrate[:] = np.ma.masked_invalid(annual.astype(np.float32))
        vdaily[:] = np.ma.masked_invalid(daily.astype(np.float32))
        vprov[:] = rates

        vlat.units = "degrees_north"
        vlon.units = "degrees_east"
        vrate.units = "yr-1"
        vdaily.units = "day-1"
        vprov.units = "yr-1"
        vrate.long_name = "province-specific baseline annual non-accidental mortality rate"
        vdaily.long_name = "province-specific baseline daily non-accidental mortality rate"
        vrate.coordinates = "XLAT XLONG"
        vdaily.coordinates = "XLAT XLONG"

        ds.grid = "native CWRF 30-km grid"
        ds.province_names = "|".join(PROVINCE_NAMES)

def write_qc(path, province, region, overlap_fraction, cell_area_km2, rates):
    rows = []

    for code, name in enumerate(PROVINCE_NAMES, start=1):
        mask = province == code
        n = int(np.sum(mask))
        area = float(np.sum(cell_area_km2[mask])) if n > 0 else 0.0
        mean_overlap = float(np.mean(overlap_fraction[mask])) if n > 0 else np.nan
        region_code = int(region_from_province(np.array([[code]], dtype=np.int16))[0, 0])

        rows.append(
            {
                "province_code": code,
                "province_name": name,
                "region_code": region_code,
                "region_name": REGION_NAMES[region_code - 1],
                "cwrf_cells": n,
                "assigned_cell_area_km2": area,
                "mean_max_overlap_fraction": mean_overlap,
                "annual_baseline_mortality_rate": rates[code - 1],
                "daily_baseline_mortality_rate": rates[code - 1] / 365.0,
            }
        )

    with open(path, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        writer.writeheader()
        writer.writerows(rows)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--hgt", default="HGT.nc")
    parser.add_argument(
        "--shapefile",
        default="china-shapefiles-master/shapefiles/china.shp",
    )
    parser.add_argument("--shape-field", default="FENAME")
    parser.add_argument("--province-code", default="1.province.txt")
    parser.add_argument("--province-death", default="1.Province-death.txt")
    parser.add_argument("--province-output", default="0.province_CWRF.nc")
    parser.add_argument("--region-output", default="0.region_CWRF.nc")
    parser.add_argument("--death-output", default="1.death-rate_CWRF.nc")
    parser.add_argument("--qc-output", default="cwrf_health_static_qc.csv")
    parser.add_argument("--meta-output", default="cwrf_health_static_meta.json")
    parser.add_argument("--rebuild", action="store_true")
    args = parser.parse_args()

    required = [args.hgt, args.shapefile, args.province_code, args.province_death]
    for path in required:
        if not os.path.exists(path):
            raise FileNotFoundError(path)

    lat, lon = read_cwrf_grid(args.hgt)

    base, _ = os.path.splitext(args.shapefile)
    shp_components = [
        p for p in [base + ".shp", base + ".shx", base + ".dbf", base + ".prj", base + ".cpg"]
        if os.path.exists(p)
    ]

    signature = {
        "grid_hash": grid_hash(lat, lon),
        "shapefile_signature": file_signature(shp_components),
        "death_input_signature": file_signature([args.province_code, args.province_death]),
        "shape_field": args.shape_field,
    }

    outputs = [
        args.province_output,
        args.region_output,
        args.death_output,
        args.qc_output,
        args.meta_output,
    ]

    if not args.rebuild and all(os.path.exists(p) for p in outputs):
        try:
            with open(args.meta_output, "r", encoding="utf-8") as f:
                old = json.load(f)
            if old == signature:
                print("Static CWRF health files are up to date.")
                for path in outputs[:-1]:
                    print(path)
                return
        except Exception:
            pass

    province_geoms = read_province_geometries(args.shapefile, args.shape_field)
    province, overlap_fraction, cell_area_km2 = build_province_mask(lat, lon, province_geoms)
    region = region_from_province(province)
    rates = compute_death_rates(args.province_code, args.province_death)

    write_mask_file(
        args.province_output,
        lat,
        lon,
        "region_mask",
        province,
        "province code",
        PROVINCE_NAMES,
    )

    write_mask_file(
        args.region_output,
        lat,
        lon,
        "region_mask",
        region,
        "macro-region code",
        REGION_NAMES,
    )

    write_death_rate_file(args.death_output, lat, lon, province, rates)
    write_qc(args.qc_output, province, region, overlap_fraction, cell_area_km2, rates)

    with open(args.meta_output, "w", encoding="utf-8") as f:
        json.dump(signature, f, indent=2)

    assigned = int(np.sum(province > 0))
    print(f"Assigned CWRF cells: {assigned}")
    print(f"Created: {args.province_output}")
    print(f"Created: {args.region_output}")
    print(f"Created: {args.death_output}")
    print(f"Created: {args.qc_output}")

if __name__ == "__main__":
    main()
