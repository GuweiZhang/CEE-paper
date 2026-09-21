                                                                             
import xarray as xr
import numpy as np
import pandas as pd

input_file = 'CWRF-NASA-hist.nc'
input_file_cc = 'CWRF-NASA-cc-hist.nc'
input_file_sc = 'CWRF-NASA-sc-hist.nc'
input_file_obs = 'OBS-hist.nc'             
input_file_cmip = 'CMIP6-hist.nc'                         

missing_value = -9999
bins = np.arange(0, 502, 2) 
bin_centers = (bins[:-1] + bins[1:]) / 2

CHUNK_DAYS = 128

def get_pdf_and_ci(data_array):
    pass

    n_days = int(data_array.shape[0])
    nbins = len(bin_centers)
    bin0 = float(bins[0])
    bin1 = float(bins[-1])
    binw = float(bins[1] - bins[0])

    sum_pdf = np.zeros(nbins, dtype=np.float64)
    sumsq_pdf = np.zeros(nbins, dtype=np.float64)

    for start in range(0, n_days, CHUNK_DAYS):
        end = min(start + CHUNK_DAYS, n_days)

        block = np.asarray(
            data_array[start:end, :, :].values,
            dtype=np.float32
        )
        nt = block.shape[0]
        flat = block.reshape(nt, -1)

        in_range = (
            np.isfinite(flat)
            & (flat > missing_value)
            & (flat >= bin0)
            & (flat <= bin1)
        )

        safe = np.where(in_range, flat, np.float32(bin0))
        idx = np.floor((safe - bin0) / binw).astype(np.int32)
        idx[idx == nbins] = nbins - 1                       

        day_id = np.broadcast_to(
            np.arange(nt, dtype=np.int64)[:, None],
            idx.shape
        )
        codes = day_id[in_range] * nbins + idx[in_range]

        counts = np.bincount(
            codes,
            minlength=nt * nbins
        ).reshape(nt, nbins)

        totals = counts.sum(axis=1)
        daily_pdf = np.zeros((nt, nbins), dtype=np.float64)
        good = totals > 0
        daily_pdf[good, :] = (
            counts[good, :] / totals[good, None] / binw
        )

        sum_pdf += daily_pdf.sum(axis=0)
        sumsq_pdf += np.square(daily_pdf).sum(axis=0)

        print(f"\r    processed {end}/{n_days} days", end="", flush=True)

    print()

    pdf_mean = sum_pdf / n_days
    variance = sumsq_pdf / n_days - pdf_mean * pdf_mean
    variance = np.maximum(variance, 0.0)
    pdf_std = np.sqrt(variance)
    pdf_sem = pdf_std / np.sqrt(n_days)
    ci_95 = 1.96 * pdf_sem

    return pdf_mean, ci_95

ds_nat = xr.open_dataset(input_file, engine='netcdf4', cache=False)
ds_cc = xr.open_dataset(input_file_cc, engine='netcdf4', cache=False)
ds_sc = xr.open_dataset(input_file_sc, engine='netcdf4', cache=False)
ds_obs = xr.open_dataset(input_file_obs, engine='netcdf4', cache=False) 
ds_cmip = xr.open_dataset(input_file_cmip, engine='netcdf4', cache=False)                   

tasks = {
    'National': ('pr_cwrf', 'pr_nasa', 'pr_obs', 'pr_cmip', ds_nat, ds_obs, ds_cmip), 
    'SC': ('scpr_cwrf', 'scpr_nasa', 'scpr_obs', 'scpr_cmip', ds_sc, ds_obs, ds_cmip), 
    'CC': ('ccpr_cwrf', 'ccpr_nasa', 'ccpr_obs', 'ccpr_cmip', ds_cc, ds_obs, ds_cmip)
}

results = {}              

for region, (v_cwrf, v_nasa, v_obs, v_cmip, ds_region, ds_obs_region, ds_cmip_region) in tasks.items():
                                            
    m_c, c_c = get_pdf_and_ci(ds_region[v_cwrf])
    m_n, c_n = get_pdf_and_ci(ds_region[v_nasa])
    m_o, c_o = get_pdf_and_ci(ds_obs_region[v_obs])
    m_cmip, c_cmip = get_pdf_and_ci(ds_cmip_region[v_cmip])                
    
    results[region] = {
        'CWRF_M': m_c, 'CWRF_CI': c_c, 
        'NASA_M': m_n, 'NASA_CI': c_n,
        'OBS_M': m_o, 'OBS_CI': c_o,
        'CMIP_M': m_cmip, 'CMIP_CI': c_cmip                
    }

ds_nat.close()
ds_cc.close()
ds_sc.close()
ds_obs.close() 
ds_cmip.close()                

csv_data = {
    'Precipitation_Intensity(mm/day)': bin_centers
}

for region in ['National', 'SC', 'CC']:
    data = results[region]

    csv_data[f'{region}_OBS_Mean']  = data['OBS_M']
    csv_data[f'{region}_OBS_CI']    = data['OBS_CI']
    
    csv_data[f'{region}_CMIP_Mean'] = data['CMIP_M']                   
    csv_data[f'{region}_CMIP_CI']   = data['CMIP_CI']
    
    csv_data[f'{region}_CWRF_Mean'] = data['CWRF_M']
    csv_data[f'{region}_CWRF_CI']   = data['CWRF_CI']
    
    csv_data[f'{region}_NASA_Mean'] = data['NASA_M']
    csv_data[f'{region}_NASA_CI']   = data['NASA_CI']

df_export = pd.DataFrame(csv_data)

csv_filename = 'KLRD_PDF_Results_hist.csv'
df_export.to_csv(csv_filename, index=False)

print(f"CSV exported: {csv_filename}")