begin
  fout = addfile("1.pre-res_textt-cwrf-storm-rain.nc", "r")
  bias_cmip0 = fout->bias_cmip_storm
  bias_cwrf0 = fout->bias_cwrf_storm
  bias_cmip1 = fout->bias_cmip_heavy
  bias_cwrf1 = fout->bias_cwrf_heavy

  va0 = fout->obs_storm
  vb0 = fout->obs_heavy

  cmip0 = fout->cmip_storm
  cwrf0 = fout->cwrf_storm
  cmip1 = fout->cmip_heavy
  cwrf1 = fout->cwrf_heavy

  fregion = addfile("0.region_CN05.nc", "r")
  region_mask = fregion->region_mask
  rgm = conform_dims(dimsizes(bias_cmip0), region_mask, (/1,2/))

  bias_cmip1 = where(rgm.ge.4, bias_cmip1, 0.)
  bias_cwrf1 = where(rgm.ge.4, bias_cwrf1, 0.)

  bias_cmip = (bias_cmip0 + bias_cmip1) *0.05
  bias_cwrf = (bias_cwrf0 + bias_cwrf1) *0.05

  bias_cmip_abs = abs(bias_cmip)
  bias_cwrf_abs = abs(bias_cwrf)

  copy_VarCoords(bias_cmip0, bias_cmip)
  copy_VarCoords(bias_cmip0, bias_cwrf)

  vb0 = where(region_mask.ge.4.and..not.ismissing(vb0), vb0, 0)
  cmip1 = where(rgm.ge.4.and..not.ismissing(cmip1), cmip1, 0)
  cwrf1 = where(rgm.ge.4.and..not.ismissing(cwrf1), cwrf1, 0)

  obs = va0 + vb0
  cmipr = cmip0 + cmip1
  cwrfr = cwrf0 + cwrf1
  obs = where(ismissing(cwrfr(0,:,:)), obs@_FillValue, obs)

  pcc = new(6, float)
  abias = new(6, float)

  do i = 0, 2
    pcc(i) = pattern_cor(cmipr(i,:,:), obs, 1., 1)
    pcc(i+3) = pattern_cor(cwrfr(i,:,:), obs, 1., 1)
    abias(i) = dim_avg_n(dim_avg_n(bias_cmip_abs(i,:,:), 0), 0)
    abias(i+3) = dim_avg_n(dim_avg_n(bias_cwrf_abs(i,:,:), 0), 0)
  end do

  plot_bias_cmip = bias_cmip
  plot_bias_cwrf = bias_cwrf
  copy_VarCoords(bias_cmip, plot_bias_cmip)
  copy_VarCoords(bias_cwrf, plot_bias_cwrf)

  out_filename = "FigureS2_plot_data.nc"
  system("rm -f " + out_filename)
  f_out = addfile(out_filename, "c")

  f_out->plot_bias_cmip = plot_bias_cmip
  f_out->plot_bias_cwrf = plot_bias_cwrf
  f_out->pcc = pcc
  f_out->abias = abias

  print("Success! Data for Figure S2 saved to: " + out_filename)
end
