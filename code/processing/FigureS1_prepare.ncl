load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
begin

  f_at2m0 = addfile("external_inputs/MPI-ESM1-2-HR_pr_hist_1995-2014.nc","r")
  f_at2m1 = addfile("external_inputs/CESM2_pr_hist_1995-2014.nc","r")
  f_at2m2 = addfile("external_inputs/IPSL-CM6A-LR_pr_hist_1995-2014.nc","r")

  m0 = f_at2m0->pr(:,:,:)
  m1 = f_at2m1->pr(:,:,:)
  m2 = f_at2m2->pr(:,:,:)

  nn = dimsizes(m0)
  bias_cmip = new((/3, nn(1), nn(2)/), float)
  bias_cmip@_FillValue = -9999.0
  bias_cwrf = new((/3, nn(1), nn(2)/), float)
  bias_cwrf@_FillValue = -9999.0

  CMIP_CLM_0 = clmMonTLL(m0)
  bias_cmip(0,:,:) = dim_sum_n_Wrap(CMIP_CLM_0, 0)

  CMIP_CLM_1 = clmMonTLL(m1)
  bias_cmip(1,:,:) = dim_sum_n_Wrap(CMIP_CLM_1, 0)

  CMIP_CLM_2 = clmMonTLL(m2)
  bias_cmip(2,:,:) = dim_sum_n_Wrap(CMIP_CLM_2, 0)

  f_cwrf0 = addfile("external_inputs/MPI_PRAVG_hist_1995-2014_mon_CN05.nc","r")
  f_cwrf1 = addfile("external_inputs/CESM2_PRAVG_hist_1995-2014_mon_CN05.nc","r")
  f_cwrf2 = addfile("external_inputs/IPSL_PRAVG_hist_1995-2014_mon_CN05.nc","r")

  cc0 = doubletofloat(f_cwrf0->PRAVG(:,:,:))
  cc1 = doubletofloat(f_cwrf1->PRAVG(:,:,:))
  cc2 = doubletofloat(f_cwrf2->PRAVG(:,:,:))

  c0 = tofloat(sprintf("%.1f", cc0))
  c1 = tofloat(sprintf("%.1f", cc1))
  c2 = tofloat(sprintf("%.1f", cc2))

  copy_VarCoords(cc0, c0)
  copy_VarCoords(cc1, c1)
  copy_VarCoords(cc2, c2)

  CWRF_CLM_0 = clmMonTLL(c0)
  copy_VarCoords(CMIP_CLM_0, CWRF_CLM_0)
  bias_cwrf(0,:,:) = dim_sum_n_Wrap(CWRF_CLM_0, 0)

  CWRF_CLM_1 = clmMonTLL(c1)
  copy_VarCoords(CMIP_CLM_0, CWRF_CLM_1)
  bias_cwrf(1,:,:) = dim_sum_n_Wrap(CWRF_CLM_1, 0)

  CWRF_CLM_2 = clmMonTLL(c2)
  copy_VarCoords(CMIP_CLM_0, CWRF_CLM_2)
  bias_cwrf(2,:,:) = dim_sum_n_Wrap(CWRF_CLM_2, 0)

  fobs_r = addfile("external_inputs/CN05.1_Pre_1995_2014_month_sum_025x025_mm.nc","r")
  v0 = fobs_r->pre

  OBS_CLM = clmMonTLL(v0)
  obs = dim_sum_n_Wrap(OBS_CLM, 0)

  bias_cmip = bias_cmip * 24.0 * 3600.0 * 30.0
  copy_VarCoords(v0(0:2,:,:), bias_cmip)
  copy_VarCoords(v0(0:2,:,:), bias_cwrf)

  do j = 0, 2
    bias_cmip(j,:,:) = where(ismissing(obs), bias_cmip@_FillValue, bias_cmip(j,:,:))
    bias_cwrf(j,:,:) = where(ismissing(obs), bias_cwrf@_FillValue, bias_cwrf(j,:,:))
  end do

  bias_cmipa = dim_avg_n_Wrap(bias_cmip, 0)
  bias_cwrfa = dim_avg_n_Wrap(bias_cwrf, 0)

  clat = 1.0
  pcc = new(8, float)
  abias = new(8, float)

  pcc(0) = pattern_cor(obs, bias_cmipa, clat, 1)
  pcc(1) = pattern_cor(obs, bias_cwrfa, clat, 1)

  ba0 = abs(bias_cmipa - obs)
  ba0 = where(ismissing(obs), ba0@_FillValue, ba0)
  abias(0) = dim_avg(dim_avg(ba0))

  ba1 = abs(bias_cwrfa - obs)
  ba1 = where(ismissing(obs), ba1@_FillValue, ba1)
  abias(1) = dim_avg(dim_avg(ba1))

  do j = 0, 2
    pcc(j+2) = pattern_cor(obs, bias_cmip(j,:,:), clat, 1)
    pcc(j+5) = pattern_cor(obs, bias_cwrf(j,:,:), clat, 1)

    baj_cmip = abs(bias_cmip(j,:,:) - obs)
    baj_cmip = where(ismissing(obs), baj_cmip@_FillValue, baj_cmip)
    abias(j+2) = dim_avg(dim_avg(baj_cmip))

    baj_cwrf = abs(bias_cwrf(j,:,:) - obs)
    baj_cwrf = where(ismissing(obs), baj_cwrf@_FillValue, baj_cwrf)
    abias(j+5) = dim_avg(dim_avg(baj_cwrf))
  end do

  out_filename = "FigureS1_plot_data.nc"
  if (isfilepresent(out_filename)) then
    print("Output already exists: " + out_filename)
    exit
  end if
  fout = addfile(out_filename, "c")

  pcc!0 = "model"
  abias!0 = "model"

  fout->obs = obs
  fout->bias_cmip = bias_cmip
  fout->bias_cwrf = bias_cwrf
  fout->bias_cmipa = bias_cmipa
  fout->bias_cwrfa = bias_cwrfa
  fout->pcc = pcc
  fout->abias = abias

  print("Success! Data for Figure S2 saved to: " + out_filename)
end
