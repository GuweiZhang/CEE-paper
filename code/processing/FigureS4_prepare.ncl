

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
begin
  fout = addfile("3.future-storm-change-tt.nc", "r")
  cwrf_heavy = fout->cwrf_heavy_change
  cwrf_storm = fout->cwrf_storm_change

  fout1 = addfile("3.future-storm-change-tt-CWRF-NASA.nc", "r")
  NASA_heavy = fout1->cmip_heavy_change
  NASA_storm = fout1->cmip_storm_change

  cwrf_heavy(0:1,0,:,:) = NASA_heavy(0:1,0,:,:)
  cwrf_heavy(:,3,:,:) = NASA_heavy(:,3,:,:)

  cwrf_storm(0:1,0,:,:) = NASA_storm(0:1,0,:,:)
  cwrf_storm(:,3,:,:) = NASA_storm(:,3,:,:)

  fregion = addfile("0.region_CN05.nc", "r")
  region_mask = fregion->region_mask

  rgm = conform_dims(dimsizes(cwrf_heavy), region_mask, (/2,3/))

  cwrf_heavy_new = where(rgm.ge.4, cwrf_heavy, 0.)

  cwrf1 = tofloat(cwrf_heavy_new + cwrf_storm)
  copy_VarCoords(cwrf_heavy, cwrf1)

  out_filename = "FigureS4_plot_data.nc"
  if (isfilepresent(out_filename)) then
    print("Output already exists: " + out_filename)
    exit
  end if
  f_out = addfile(out_filename, "c")

  f_out->cwrf1 = cwrf1

  print("Success! Data for Figure S4 saved to: " + out_filename)
end
