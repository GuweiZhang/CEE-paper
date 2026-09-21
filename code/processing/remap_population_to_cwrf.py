                      
import os
import csv
import json
import hashlib
import argparse
import numpy as np
from netCDF4 import Dataset
from scipy import sparse
from shapely.geometry import Polygon
from shapely.strtree import STRtree
from pyproj import CRS, Transformer

def array_hash(*arrays):
    h = hashlib.sha1()
    for arr in arrays:
        a = np.ascontiguousarray(np.asarray(arr))
        h.update(str(a.shape).encode())
        h.update(str(a.dtype).encode())
        h.update(a.tobytes())
    return h.hexdigest()

def edges_from_centers(x):
    x = np.asarray(x, dtype=np.float64)
    if x.ndim != 1:
        raise ValueError("Coordinate array must be 1-D.")
    if len(x) < 2:
        raise ValueError("At least two coordinate centers are required.")
    edges = np.empty(len(x) + 1, dtype=np.float64)
    edges[1:-1] = 0.5 * (x[:-1] + x[1:])
    edges[0] = x[0] - 0.5 * (x[1] - x[0])
    edges[-1] = x[-1] + 0.5 * (x[-1] - x[-2])
    return edges

def infer_2d_corners(center):
    center = np.asarray(center, dtype=np.float64)
    ny, nx = center.shape
    if ny < 2 or nx < 2:
        raise ValueError("Target grid must be at least 2 x 2.")
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

def build_polygon(lons, lats, transformer):
    x, y = transformer.transform(lons, lats)
    poly = Polygon(zip(x, y))
    if not poly.is_valid:
        poly = poly.buffer(0)
    return poly

def read_population_grid(path):
    with Dataset(path, "r") as nc:
        lat = np.asarray(nc.variables["lat"][:], dtype=np.float64)
        lon = np.asarray(nc.variables["lon"][:], dtype=np.float64)
    return lat, lon

def read_cwrf_grid(path):
    with Dataset(path, "r") as nc:
        lat = np.asarray(nc.variables["XLAT"][:], dtype=np.float64)
        lon = np.asarray(nc.variables["XLONG"][:], dtype=np.float64)
    if lat.ndim == 3:
        lat = lat[0]
    if lon.ndim == 3:
        lon = lon[0]
    return lat, lon

def build_weights(src_lat, src_lon, tgt_lat, tgt_lon):
    nys = len(src_lat)
    nxs = len(src_lon)
    nyt, nxt = tgt_lat.shape
    nsrc = nys * nxs
    ntgt = nyt * nxt
    print("Building conservative remapping weights")
    print(f"Source grid: {nys} x {nxs} = {nsrc}")
    print(f"CWRF grid: {nyt} x {nxt} = {ntgt}")
    tgt_lon_unwrapped = np.rad2deg(np.unwrap(np.deg2rad(tgt_lon), axis=1))
    src_lat_edges = edges_from_centers(src_lat)
    src_lon_edges = edges_from_centers(src_lon)
    tgt_lat_corner = infer_2d_corners(tgt_lat)
    tgt_lon_corner = infer_2d_corners(tgt_lon_unwrapped)
    lat0 = float(np.nanmean(tgt_lat))
    lon0 = float(np.nanmean(tgt_lon_unwrapped))
    crs_geo = CRS.from_epsg(4326)
    crs_equal_area = CRS.from_proj4(
        f"+proj=laea +lat_0={lat0:.8f} +lon_0={lon0:.8f} +datum=WGS84 +units=m +no_defs"
    )
    transformer = Transformer.from_crs(crs_geo, crs_equal_area, always_xy=True)
    target_polygons = []
    target_area = np.zeros(ntgt, dtype=np.float64)
    for iy in range(nyt):
        for ix in range(nxt):
            lons = [
                tgt_lon_corner[iy, ix],
                tgt_lon_corner[iy, ix + 1],
                tgt_lon_corner[iy + 1, ix + 1],
                tgt_lon_corner[iy + 1, ix],
            ]
            lats = [
                tgt_lat_corner[iy, ix],
                tgt_lat_corner[iy, ix + 1],
                tgt_lat_corner[iy + 1, ix + 1],
                tgt_lat_corner[iy + 1, ix],
            ]
            poly = build_polygon(lons, lats, transformer)
            idx = iy * nxt + ix
            target_polygons.append(poly)
            target_area[idx] = poly.area
    if np.any(target_area <= 0):
        raise RuntimeError("Invalid CWRF grid-cell area detected.")
    tree = STRtree(target_polygons)
    geom_id_to_index = {id(g): i for i, g in enumerate(target_polygons)}
    rows = []
    cols = []
    data = []
    source_coverage = np.zeros(nsrc, dtype=np.float64)
    processed = 0
    for iy in range(nys):
        for ix in range(nxs):
            src_index = iy * nxs + ix
            lons = [
                src_lon_edges[ix],
                src_lon_edges[ix + 1],
                src_lon_edges[ix + 1],
                src_lon_edges[ix],
            ]
            lats = [
                src_lat_edges[iy],
                src_lat_edges[iy],
                src_lat_edges[iy + 1],
                src_lat_edges[iy + 1],
            ]
            src_poly = build_polygon(lons, lats, transformer)
            src_area = src_poly.area
            if src_area <= 0:
                continue
            candidates = tree.query(src_poly)
            if len(candidates) == 0:
                continue
            first = candidates[0]
            if isinstance(first, (int, np.integer)):
                candidate_indices = candidates
            else:
                candidate_indices = [geom_id_to_index[id(g)] for g in candidates]
            coverage = 0.0
            for tgt_index in candidate_indices:
                tgt_index = int(tgt_index)
                tgt_poly = target_polygons[tgt_index]
                if not src_poly.intersects(tgt_poly):
                    continue
                overlap = src_poly.intersection(tgt_poly)
                if overlap.is_empty:
                    continue
                overlap_area = overlap.area
                if overlap_area <= 0:
                    continue
                weight = overlap_area / src_area
                if weight < 1.0e-12:
                    continue
                rows.append(tgt_index)
                cols.append(src_index)
                data.append(weight)
                coverage += weight
            source_coverage[src_index] = coverage
            processed += 1
            if processed % 500 == 0:
                print(f"Processed {processed}/{nsrc} source cells")
    W = sparse.coo_matrix(
        (
            np.asarray(data, dtype=np.float64),
            (
                np.asarray(rows, dtype=np.int64),
                np.asarray(cols, dtype=np.int64),
            ),
        ),
        shape=(ntgt, nsrc),
    ).tocsr()
    print(f"Nonzero overlap pairs: {W.nnz}")
    positive = source_coverage > 0
    if positive.any():
        print(f"Coverage min: {source_coverage[positive].min():.8f}")
        print(f"Coverage mean: {source_coverage[positive].mean():.8f}")
        print(f"Coverage max: {source_coverage[positive].max():.8f}")
    return W, source_coverage, target_area.reshape(nyt, nxt)

def load_or_build_weights(src_lat, src_lon, tgt_lat, tgt_lon, weight_file, meta_file):
    current_hash = array_hash(src_lat, src_lon, tgt_lat, tgt_lon)
    if os.path.exists(weight_file) and os.path.exists(meta_file):
        with open(meta_file, "r", encoding="utf-8") as f:
            meta = json.load(f)
        if meta.get("grid_hash") == current_hash:
            print(f"Using cached weights: {weight_file}")
            W = sparse.load_npz(weight_file)
            source_coverage = np.asarray(meta["source_coverage"], dtype=np.float64)
            target_area = np.asarray(meta["target_area_km2"], dtype=np.float64)
            target_area = target_area.reshape(tgt_lat.shape) * 1.0e6
            return W, source_coverage, target_area
    W, source_coverage, target_area = build_weights(src_lat, src_lon, tgt_lat, tgt_lon)
    sparse.save_npz(weight_file, W, compressed=True)
    meta = {
        "grid_hash": current_hash,
        "source_shape": [len(src_lat), len(src_lon)],
        "target_shape": list(tgt_lat.shape),
        "source_coverage": source_coverage.tolist(),
        "target_area_km2": (target_area.ravel() / 1.0e6).tolist(),
        "method": "area-overlap conservative remapping",
    }
    with open(meta_file, "w", encoding="utf-8") as f:
        json.dump(meta, f, indent=2)
    return W, source_coverage, target_area

def create_output_file(output_file, ssp_values, time_values, tgt_lat, tgt_lon, target_area, source_file, population_type):
    ny, nx = tgt_lat.shape
    nc = Dataset(output_file, "w", format="NETCDF4")
    nc.createDimension("ssp", len(ssp_values))
    nc.createDimension("time", len(time_values))
    nc.createDimension("south_north", ny)
    nc.createDimension("west_east", nx)
    v_ssp = nc.createVariable("ssp", np.asarray(ssp_values).dtype, ("ssp",))
    v_time = nc.createVariable("time", np.asarray(time_values).dtype, ("time",))
    v_lat = nc.createVariable("XLAT", "f4", ("south_north", "west_east"))
    v_lon = nc.createVariable("XLONG", "f4", ("south_north", "west_east"))
    v_area = nc.createVariable("cell_area_km2", "f4", ("south_north", "west_east"), zlib=True, complevel=4)
    v_pop = nc.createVariable("pop", "f4", ("ssp", "time", "south_north", "west_east"), zlib=True, complevel=4, shuffle=True, fill_value=np.float32(-9999.0))
    v_ssp[:] = ssp_values
    v_time[:] = time_values
    v_lat[:] = tgt_lat.astype(np.float32)
    v_lon[:] = tgt_lon.astype(np.float32)
    v_area[:] = (target_area / 1.0e6).astype(np.float32)
    v_lat.units = "degrees_north"
    v_lat.standard_name = "latitude"
    v_lon.units = "degrees_east"
    v_lon.standard_name = "longitude"
    v_area.units = "km2"
    v_area.long_name = "CWRF grid cell area"
    v_pop.units = "persons"
    v_pop.long_name = f"{population_type} population count on native CWRF grid"
    v_pop.coordinates = "XLAT XLONG"
    nc.title = f"{population_type.capitalize()} population conservatively remapped to native CWRF grid"
    nc.source_population_file = source_file
    nc.remapping_method = "Area-overlap conservative remapping"
    nc.target_grid = "native CWRF grid"
    nc.target_grid_size = f"{ny} x {nx}"
    nc.population_assumption = "Input pop values are population counts per source grid cell"
    return nc

def remap_population_file(input_file, output_file, population_type, W, source_coverage, target_area, tgt_lat, tgt_lon, reference_ssp, reference_time, qc_rows):
    print(f"Processing {population_type}: {input_file}")
    src_nc = Dataset(input_file, "r")
    pop_var = src_nc.variables["pop"]
    if len(pop_var.shape) != 4:
        raise ValueError(f"{input_file}: pop must be 4-D.")
    nssp, ntime, _, _ = pop_var.shape
    if "ssp" in src_nc.variables:
        ssp_values = np.asarray(src_nc.variables["ssp"][:])
    else:
        if nssp != len(reference_ssp):
            raise ValueError("SSP dimension mismatch.")
        ssp_values = reference_ssp
    if "time" in src_nc.variables:
        time_values = np.asarray(src_nc.variables["time"][:])
    else:
        if ntime != len(reference_time):
            raise ValueError("Time dimension mismatch.")
        time_values = reference_time
    out_nc = create_output_file(output_file, ssp_values, time_values, tgt_lat, tgt_lon, target_area, input_file, population_type)
    out_pop = out_nc.variables["pop"]
    for iss in range(nssp):
        for it in range(ntime):
            source = pop_var[iss, it, :, :]
            if np.ma.isMaskedArray(source):
                source = source.filled(0.0)
            source = np.asarray(source, dtype=np.float64)
            source[~np.isfinite(source)] = 0.0
            source[source < 0] = 0.0
            src_flat = source.ravel()
            tgt_flat = W.dot(src_flat)
            target = tgt_flat.reshape(tgt_lat.shape)
            out_pop[iss, it, :, :] = target.astype(np.float32)
            source_total = float(np.sum(src_flat))
            covered_source_total = float(np.sum(src_flat * source_coverage))
            mapped_total = float(np.sum(tgt_flat))
            if source_total > 0:
                mapped_source_ratio = mapped_total / source_total
                relative_difference = (mapped_total - source_total) / source_total
            else:
                mapped_source_ratio = np.nan
                relative_difference = np.nan
            if covered_source_total > 0:
                numerical_closure_error = (mapped_total - covered_source_total) / covered_source_total
            else:
                numerical_closure_error = np.nan
            qc_rows.append({
                "dataset": population_type,
                "ssp_index": iss,
                "ssp": ssp_values[iss],
                "time_index": it,
                "time": time_values[it],
                "source_total": source_total,
                "mapped_total": mapped_total,
                "mapped_source_ratio": mapped_source_ratio,
                "relative_difference": relative_difference,
                "covered_source_total": covered_source_total,
                "numerical_closure_error": numerical_closure_error,
            })
            if it == 0 or it == ntime - 1 or (it + 1) % 10 == 0:
                print(f"{population_type} ssp={ssp_values[iss]} time={time_values[it]} source={source_total:.6e} mapped={mapped_total:.6e} ratio={mapped_source_ratio:.8f}")
    src_nc.close()
    out_nc.close()

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--total", default="total_pop-new.nc")
    parser.add_argument("--urban", default="urban_pop-new.nc")
    parser.add_argument("--hgt", default="HGT.nc")
    parser.add_argument("--out-total", default="total_pop_CWRF.nc")
    parser.add_argument("--out-urban", default="urban_pop_CWRF.nc")
    parser.add_argument("--qc", default="population_remap_qc.csv")
    parser.add_argument("--weights", default="conservative_pop_weights_cwrf.npz")
    parser.add_argument("--weight-meta", default="conservative_pop_weights_cwrf.json")
    args = parser.parse_args()
    for path in [args.total, args.urban, args.hgt]:
        if not os.path.exists(path):
            raise FileNotFoundError(path)
    src_lat, src_lon = read_population_grid(args.total)
    urban_lat, urban_lon = read_population_grid(args.urban)
    if not np.allclose(src_lat, urban_lat, atol=1.0e-6):
        raise ValueError("Latitude grids differ between total and urban files.")
    if not np.allclose(src_lon, urban_lon, atol=1.0e-6):
        raise ValueError("Longitude grids differ between total and urban files.")
    tgt_lat, tgt_lon = read_cwrf_grid(args.hgt)
    with Dataset(args.total, "r") as nc:
        if "ssp" not in nc.variables or "time" not in nc.variables:
            raise ValueError("Total population file must contain ssp and time coordinates.")
        ssp_values = np.asarray(nc.variables["ssp"][:])
        time_values = np.asarray(nc.variables["time"][:])
    W, source_coverage, target_area = load_or_build_weights(src_lat, src_lon, tgt_lat, tgt_lon, args.weights, args.weight_meta)
    qc_rows = []
    remap_population_file(args.total, args.out_total, "total", W, source_coverage, target_area, tgt_lat, tgt_lon, ssp_values, time_values, qc_rows)
    remap_population_file(args.urban, args.out_urban, "urban", W, source_coverage, target_area, tgt_lat, tgt_lon, ssp_values, time_values, qc_rows)
    fieldnames = [
        "dataset",
        "ssp_index",
        "ssp",
        "time_index",
        "time",
        "source_total",
        "mapped_total",
        "mapped_source_ratio",
        "relative_difference",
        "covered_source_total",
        "numerical_closure_error",
    ]
    with open(args.qc, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(qc_rows)
    print(f"Created: {args.out_total}")
    print(f"Created: {args.out_urban}")
    print(f"Created: {args.qc}")
    print(f"Created: {args.weights}")
    print(f"Created: {args.weight_meta}")

if __name__ == "__main__":
    main()
