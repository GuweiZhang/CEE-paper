

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
begin
  ssp = (/"126","245","585"/)
  subregion = (/"CN","NE","NC","NW","EC","CC","SC"/)

  fout = addfile("4.future-rain-change-tt.nc", "r")
  cwrf = fout->cwrf_storm_change

  fout1 = addfile("4.future-rain-change-tt-CWRF-NASA.nc", "r")
  cwrf_NASA = fout1->cmip_storm_change

  cwrf(0:1,0,:,:) = cwrf_NASA(0:1,0,:,:)
  cwrf(:,3,:,:) = dim_avg_n_Wrap(cwrf(:,:2,:,:), 1)

  fout_mask = addfile("0.region_CN05.nc", "r")
  region_mask = fout_mask->region_mask
  rgm = conform_dims(dimsizes(cwrf), region_mask, (/2,3/))
  cwrf = where(ismissing(rgm), cwrf@_FillValue, cwrf)

  cwrf_re = new((/dimsizes(ssp), 4, dimsizes(subregion)/), float)
  do j = 1, dimsizes(subregion)-1
    v = where(rgm.eq.j, cwrf, cwrf@_FillValue)
    cwrf_re(:,:,j) = dim_avg_n(v, (/2,3/))
    delete(v)
  end do
  cwrf_re(:,:,0) = dim_avg_n(cwrf, (/2,3/))

  cwrf_region = new((/dimsizes(ssp), 3, dimsizes(subregion)/), float)
  cwrf_region(:,0,:) = dim_avg_n(cwrf_re(:,:2,:), 1)
  cwrf_region(:,1,:) = dim_max_n(cwrf_re(:,:2,:), 1)
  cwrf_region(:,2,:) = dim_min_n(cwrf_re(:,:2,:), 1)

  cwrf_plot = cwrf(:,3,:,:)

  cwrf_plot!0 = "ssp"
  cwrf_plot!1 = "lat"
  cwrf_plot!2 = "lon"

  cwrf_region!0 = "ssp"
  cwrf_region!1 = "stats"
  cwrf_region!2 = "region"

  out_filename = "FigureS3_plot_data.nc"
  if (isfilepresent(out_filename)) then
    print("Output already exists: " + out_filename)
    exit
  end if
  f_out = addfile(out_filename, "c")

  f_out->cwrf_plot = cwrf_plot
  f_out->cwrf_region = cwrf_region

  print("Success! Data for Figure S3 saved to: " + out_filename)
end
