

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
begin
  f1 = addfile("1.pre-res_textt-cwrf-storm-rain-nasa.nc", "r")
  va0 = f1->obs_storm
  vb0 = f1->obs_heavy
  cmip0 = f1->cmip_storm
  cwrf0 = f1->cwrf_storm
  cmip1 = f1->cmip_heavy
  cwrf1 = f1->cwrf_heavy
  bias_cmip0 = f1->bias_cmip_storm
  bias_cwrf0 = f1->bias_cwrf_storm
  bias_cmip1 = f1->bias_cmip_heavy
  bias_cwrf1 = f1->bias_cwrf_heavy

  fregion = addfile("0.region_CN05.nc", "r")
  region_mask = fregion->region_mask

  rgm = conform_dims(dimsizes(bias_cmip0), region_mask, (/1,2/))

  vb0_tmp = where(region_mask.ge.5 .and. .not.ismissing(vb0), vb0, 0)
  cmip1_tmp = where(rgm.ge.5 .and. .not.ismissing(cmip1), cmip1, 0)
  cwrf1_tmp = where(rgm.ge.5 .and. .not.ismissing(cwrf1), cwrf1, 0)

  bias_cmip1_tmp = where(rgm.ge.5, bias_cmip1, 0.)
  bias_cwrf1_tmp = where(rgm.ge.5, bias_cwrf1, 0.)

  bias_cmip = (bias_cmip0 + bias_cmip1_tmp) * 0.05
  bias_cwrf = (bias_cwrf0 + bias_cwrf1_tmp) * 0.05
  copy_VarCoords(bias_cmip0, bias_cmip)
  copy_VarCoords(bias_cmip0, bias_cwrf)

  bias0 = dim_avg_n_Wrap(bias_cmip, 0)
  bias1 = dim_avg_n_Wrap(bias_cwrf, 0)
  bias00 = where(bias0.le.0, bias0*-1, bias0)
  bias11 = where(bias1.le.0, bias1*-1, bias1)

  obs = tofloat(va0 + vb0_tmp)
  cmipr = tofloat(cmip0 + cmip1_tmp)
  cwrfr = tofloat(cwrf0 + cwrf1_tmp)
  cmipra = dim_avg_n(cmipr, 0)
  cwrfra = dim_avg_n(cwrfr, 0)

  pcc = new(2, float)
  abias = new(2, float)
  pcc(0) = pattern_cor(cmipra, obs, 1., 1)
  pcc(1) = pattern_cor(cwrfra, obs, 1., 1)
  abias(0) = avg(bias00)
  abias(1) = avg(bias11)

  obs_plot = obs / 20.
  cmipa_plot = cmipra / 20.
  cwrfa_plot = cwrfra / 20.

  copy_VarCoords(bias_cmip0(0,:,:), obs_plot)
  copy_VarCoords(bias_cmip0(0,:,:), cmipa_plot)
  copy_VarCoords(bias_cmip0(0,:,:), cwrfa_plot)

  data = asciiread("KLRD_PDF_Results.csv", -1, "string")
  data_hist = asciiread("KLRD_PDF_Results_hist.csv", -1, "string")
  delim = ","
  nrows = dimsizes(data) - 1

  plot_data = new((/nrows, 19/), float)
  plot_data_hist = new((/nrows, 25/), float)

  do i = 0, nrows-1
      tmp1 = str_split_csv(data(i+1), delim, 0)
      plot_data(i,:) = tofloat(tmp1(0,:))

      tmp2 = str_split_csv(data_hist(i+1), delim, 0)
      plot_data_hist(i,:) = tofloat(tmp2(0,:))
  end do

  eps = 1e-12
  plot_data = where(plot_data .le. 0, eps, plot_data)
  plot_data_hist = where(plot_data_hist .le. 0, eps, plot_data_hist)
  bin_centers = plot_data(:,0)

  ssp = (/"126","245","585"/)
  fout_nasa = addfile("3.future-storm-change-tt-CWRF-NASA.nc", "r")
  cwrf_heavy = fout_nasa->cmip_heavy_change
  cwrf_storm = fout_nasa->cmip_storm_change

  rgm2 = conform_dims(dimsizes(cwrf_heavy), region_mask, (/2,3/))
  cwrf_heavy_new2 = where(rgm2.ge.5, cwrf_heavy, 0.)
  cwrf_final = cwrf_heavy_new2 + cwrf_storm
  cwrf_pattern = dim_avg_n_Wrap(cwrf_final(:,:2,:,:), 1)
  tt = cwrf_heavy(:,0,:,:)

  do is = 0, dimsizes(ssp)-1
    model1 = where(cwrf_final(is,0,:,:).ge.0.1, 1., 0.)
    model2 = where(cwrf_final(is,1,:,:).ge.0.1, 1., 0.)
    model3 = where(cwrf_final(is,2,:,:).ge.0.1, 1., 0.)
    model123 = model1 + model2 + model3
    tt0 = where(model123.ge.2., 1., 0.)

    model1_neg = where(cwrf_final(is,0,:,:).le.-0.1, -1., 0.)
    model2_neg = where(cwrf_final(is,1,:,:).le.-0.1, -1., 0.)
    model3_neg = where(cwrf_final(is,2,:,:).le.-0.1, -1., 0.)
    model123_neg = model1_neg + model2_neg + model3_neg
    tt1 = where(model123_neg.le.-2., 1., 0.)

    tt(is,:,:) = where(tt0.ge.1. .or. tt1.ge.1., 1., 0.)
  end do

  copy_VarCoords(cwrf_heavy(:,0,:,:), tt)
  copy_VarCoords(cwrf_heavy(:,0,:,:), cwrf_pattern)

  out_filename1 = "FigureS12_plot_data_part1.nc"
  if (isfilepresent(out_filename1)) then
    print("Output already exists: " + out_filename1)
    exit
  end if
  fnc1 = addfile(out_filename1, "c")
  fnc1->obs_plot = obs_plot
  fnc1->cmipa_plot = cmipa_plot
  fnc1->cwrfa_plot = cwrfa_plot
  fnc1->pcc = pcc
  fnc1->abias = abias
  fnc1->bin_centers = bin_centers
  fnc1->plot_data = plot_data
  fnc1->plot_data_hist = plot_data_hist

  out_filename2 = "FigureS12_plot_data_part2.nc"
  if (isfilepresent(out_filename2)) then
    print("Output already exists: " + out_filename2)
    exit
  end if
  fnc2 = addfile(out_filename2, "c")
  fnc2->cwrf_pattern = cwrf_pattern
  fnc2->tt = tt

  print("Success! Data for Figure S11 saved to Part 1 and Part 2.")
end
