

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
begin
  ssp=(/"126","245","585"/)
  subregion=(/"CN","NE","NC","NW","EC","CC","SC"/)

  fout=addfile("1.pre-res_textt-cwrf-storm-rain.nc", "r")
  va0=fout->obs_storm
  vb0=fout->obs_heavy

  cmip0=fout->cmip_storm
  cwrf0=fout->cwrf_storm
  cmip1=fout->cmip_heavy
  cwrf1=fout->cwrf_heavy

  bias_cmip0=fout->bias_cmip_storm
  bias_cwrf0=fout->bias_cwrf_storm
  bias_cmip1=fout->bias_cmip_heavy
  bias_cwrf1=fout->bias_cwrf_heavy

  fregion=addfile("0.region_CN05.nc", "r")
  region_mask=fregion->region_mask
  rgm=conform_dims(dimsizes(bias_cmip0), region_mask, (/1,2/))

  vb0=where(region_mask.ge.5.and..not.ismissing(vb0),vb0, 0)
  cmip1=where(rgm.ge.5.and..not.ismissing(cmip1),cmip1, 0)
  cwrf1=where(rgm.ge.5.and..not.ismissing(cwrf1),cwrf1, 0)

  bias_cmip1=where(rgm.ge.5,bias_cmip1,0.)
  bias_cwrf1=where(rgm.ge.5,bias_cwrf1,0.)

  bias_cmip=(bias_cmip0+bias_cmip1)
  bias_cwrf=(bias_cwrf0+bias_cwrf1)

  copy_VarCoords(bias_cmip0,bias_cmip)
  copy_VarCoords(bias_cmip0,bias_cwrf)

  bias0=dim_avg_n_Wrap(bias_cmip,0)/20
  bias1=dim_avg_n_Wrap(bias_cwrf,0)/20

  copy_VarCoords(bias_cmip0(0,:,:), bias0)
  copy_VarCoords(bias_cwrf0(0,:,:), bias1)

  bias00=where(bias0.le.0, bias0*-1, bias0)
  bias11=where(bias1.le.0, bias1*-1, bias1)

  obs=tofloat(va0+vb0)
  cmipr=tofloat(cmip0+cmip1)
  cwrfr=tofloat(cwrf0+cwrf1)
  cmipra=dim_avg_n(cmipr, 0)
  cwrfra=dim_avg_n(cwrfr, 0)
  pcc=new(2, float)
  abias=new(2, float)

  pcc(0)=pattern_cor(cmipra, obs, 1., 1)
  pcc(1)=pattern_cor(cwrfra, obs, 1., 1)
  abias(0)=avg(bias00)
  abias(1)=avg(bias11)

  obs=obs/20.
  cmipa=cmipra/20
  cwrfa=cwrfra/20

  copy_VarCoords(bias_cmip(0,:,:),obs)
  copy_VarCoords(bias_cmip(0,:,:),cwrfa)
  copy_VarCoords(bias_cmip(0,:,:),cmipa)

  fout_tt=addfile("3.future-storm-change-tt.nc", "r")
  cwrf_heavy=fout_tt->cwrf_heavy_change
  cwrf_storm=fout_tt->cwrf_storm_change

  fout1=addfile("3.future-storm-change-tt-CWRF-NASA.nc", "r")
  NASA_heavy=fout1->cmip_heavy_change
  NASA_storm=fout1->cmip_storm_change

  cwrf_heavy(0:1,0,:,:)=NASA_heavy(0:1,0,:,:)
  cwrf_heavy(:,3,:,:)=NASA_heavy(:,3,:,:)

  cwrf_storm(0:1,0,:,:)=NASA_storm(0:1,0,:,:)
  cwrf_storm(:,3,:,:)=NASA_storm(:,3,:,:)

  delete(rgm)
  rgm=conform_dims(dimsizes(cwrf_heavy), region_mask, (/2,3/))

  cwrf_heavy_new=cwrf_heavy
  cwrf_heavy_new=where(rgm.ge.5,cwrf_heavy,0.)

  cwrf_final=cwrf_heavy_new+cwrf_storm

  cwrf_pattern=dim_avg_n_Wrap(cwrf_final(:,:2,:,:), 1)

  tt=cwrf_heavy(:,0,:,:)
  do is=0,dimsizes(ssp)-1
    model1=where(cwrf_final(is,0,:,:).ge.0.1, 1., 0.)
    model2=where(cwrf_final(is,1,:,:).ge.0.1, 1., 0.)
    model3=where(cwrf_final(is,2,:,:).ge.0.1, 1., 0.)

    model123=model1+model2+model3
    tt0=where(model123.ge.2., 1., 0.)

    model1=where(cwrf_final(is,0,:,:).le.-0.1, -1., 0.)
    model2=where(cwrf_final(is,1,:,:).le.-0.1, -1., 0.)
    model3=where(cwrf_final(is,2,:,:).le.-0.1, -1., 0.)
    model123=model1+model2+model3
    tt1=where(model123.le.-2., 1., 0.)

    tt(is,:,:)=where(tt0.ge.1..or.tt1.ge.1., 1., 0. )
  end do

  copy_VarCoords(cwrf_heavy(:,0,:,:), tt)
  copy_VarCoords(cwrf_heavy(:,0,:,:), cwrf_pattern)

  nn=dimsizes(cwrf_storm)
  delete(cwrf1)
  cwrf1=new((/2,nn(0),nn(1),nn(2),nn(3)/), float)
  rgm1=conform_dims(dimsizes(cwrf1), region_mask, (/3,4/))

  cwrf1(0,:,:,:,:)=cwrf_heavy
  cwrf1(1,:,:,:,:)=cwrf_storm
  cwrf1=where(ismissing(rgm1), cwrf1@_FillValue, cwrf1)
  rain_level=(/"Heavy","Storm"/)
  cwrf_re1=new((/dimsizes(rain_level),dimsizes(ssp),4,dimsizes(subregion)/), float)

  do j=1,dimsizes(subregion)-1
    v=cwrf1
    v=where(rgm1.eq.j, cwrf1, cwrf1@_FillValue)
    cwrf_re1(:,:,:,j)=dim_avg_n(v, (/3,4/))
    delete(v)
  end do

  cwrf_re1(:,:,:,0)=dim_avg_n(cwrf1, (/3,4/))

  delete(cwrf1)

  cwrf1=new((/dimsizes(rain_level),dimsizes(ssp),3,dimsizes(subregion)/), float)

  cwrf1(:,:,0,:)=dim_avg_n(cwrf_re1(:,:,:2,:),2)
  cwrf1(:,:,1,:)=dim_max_n(cwrf_re1(:,:,:2,:),2)
  cwrf1(:,:,2,:)=dim_min_n(cwrf_re1(:,:,:2,:),2)

  cwrf_new=new((/dimsizes(ssp),3,dimsizes(subregion)+3/), float)
  cwrf_new(:,:,:6)=cwrf1(1,:,:,:)
  cwrf_new(:,:,8:)=cwrf1(0,:,:,5:)

  cwrf_new!0 = "ssp"
  cwrf_new!1 = "stats"
  cwrf_new!2 = "region_index"

  out_filename = "Figure1_plot_data.nc"
  if (isfilepresent(out_filename)) then
    print("Output already exists: " + out_filename)
    exit
  end if
  f_out = addfile(out_filename, "c")

  setfileoption(f_out,"DefineMode",True)
  fAtt               = True
  fAtt@title         = "Data for Figure 1"
  fAtt@source        = "Processed from raw CWRF/CMIP6 data"
  fAtt@creation_date = systemfunc("date")
  fAtt@description   = "Contains extracted variables ready for direct plotting to share on GitHub."
  fileattdef(f_out, fAtt)

  obs@long_name = "Observation precipitation frequency"
  f_out->obs_plot = obs

  bias0@long_name = "CMIP6 Bias"
  bias1@long_name = "CWRF Bias"
  f_out->bias_cmip_plot = bias0
  f_out->bias_cwrf_plot = bias1

  pcc!0 = "model"
  abias!0 = "model"
  pcc@long_name = "Pattern Correlation Coefficient (CMIP6, CWRF)"
  abias@long_name = "Absolute Bias (CMIP6, CWRF)"
  f_out->pcc = pcc
  f_out->abias = abias

  cwrf_pattern@long_name = "Future precipitation change spatial pattern"
  tt@long_name = "Significance mask (tt)"
  f_out->cwrf_pattern = cwrf_pattern
  f_out->tt_mask = tt

  cwrf_new@long_name = "Regional statistics (avg, max, min) for line plot"
  f_out->cwrf_new = cwrf_new

  print("Success! All plotting data saved to: " + out_filename)
end
