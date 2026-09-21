load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"

begin

ssp=(/"126","245","585"/)

fobs_r=addfile("OBS/CN05.1_Pre_1995_2014_daily_025x025.nc","r")
obs0 = fobs_r->pre
obs=obs0
obs=where(ismissing(obs), -9999, obs)

fregion=addfile("0.region_CN05.nc", "r")
region_mask=fregion->region_mask

rgm=conform_dims(dimsizes(obs), region_mask, (/1,2/))

obs_cc=where(rgm.ge.5,obs,-9999.)
obs_sc=where(rgm.ge.6,obs,-9999.)
obs_cc@_FillValue=-9999
obs_cc@_FillValue=-9999

copy_VarCoords(obs0,obs)
copy_VarCoords(obs0,obs_cc)
copy_VarCoords(obs0,obs_sc)

setfileoption("nc","Format","LargeFile")

system("rm -rf OBS-hist.nc")
fout=addfile("OBS-hist.nc", "c")
fout->pr_obs=obs
fout->scpr_obs=obs_sc
fout->ccpr_obs=obs_cc

exit

f_at2m0 = addfile("raw/MPI_PRAVG_hist_1995-2014_daily_CN05.nc","r")
f_at2m1 = addfile("raw/CESM2_PRAVG_hist_1995-2014_daily_CN05.nc","r")
f_at2m2 = addfile("raw/IPSL_PRAVG_hist_1995-2014_daily_CN05.nc","r")

c0   = f_at2m0->PRAVG(:,:,:)
c1   = f_at2m1->PRAVG(:,:,:)
c2   = f_at2m2->PRAVG(:,:,:)

nn=dimsizes(c0)
cwrf0=new((/3,7305,nn(1),nn(2)/), float)

nyear=2014-1995+1
startday=0
startday_cesm=0
do iy=0,nyear-2
year=1995+iy

if(isleapyear(year))
  add_day=366
else
  add_day=365
end if
endday=startday+add_day-1
endday_cesm=startday_cesm+365-1

cwrf0(0,startday:endday,:,:)=c0(startday:endday,:,:)

if(isleapyear(year))
cwrf0(1,startday:startday+31+28,:,:)=c1(startday_cesm:startday_cesm+31+28,:,:)
cwrf0(1,startday+31+29,:,:)=(c0(startday+31+29,:,:)+c2(startday+31+29,:,:))/2.0
cwrf0(1,startday+31+29:endday,:,:)=c1(startday_cesm+31+28:endday_cesm,:,:)
else
cwrf0(1,startday:endday,:,:)=c1(startday_cesm:endday_cesm,:,:)
end if

cwrf0(2,startday:endday,:,:)=c2(startday:endday,:,:)
startday=endday+1
startday_cesm=endday_cesm+1

end do

iy=nyear-1
year=1995+iy

if(isleapyear(year))
  add_day=366
else
  add_day=365
end if

n0=dimsizes(c0(startday:,:,:))
cwrf0(0,startday:startday+n0(0)-1,:,:)=c0(startday:,:,:)

n1=dimsizes(c1(startday_cesm:,:,:))
cwrf0(1,startday:startday+n1(0)-1,:,:)=c1(startday_cesm:,:,:)

n2=dimsizes(c2(startday:,:,:))
cwrf0(2,startday:startday+n2(0)-1,:,:)=c2(startday:,:,:)

cwrf0=where(ismissing(cwrf0), -9999., cwrf0)
cwrf0@_FillValue=-9999.
cwrfa=dim_avg_n(cwrf0,0)

fregion=addfile("0.region_CN05.nc", "r")
region_mask=fregion->region_mask

rgm=conform_dims(dimsizes(cwrfa), region_mask, (/1,2/))
cwrfa=where(ismissing(rgm), -9999, cwrfa)
cwrfa@_FillValue=-9999

cwrfa_cc=where(rgm.ge.5,cwrfa,-9999.)
cwrfa_sc=where(rgm.ge.6,cwrfa,-9999.)
cwrfa_cc@_FillValue=-9999
cwrfa_cc@_FillValue=-9999

copy_VarCoords(c0, cwrfa)
copy_VarCoords(c0, cwrfa_cc)
copy_VarCoords(c0, cwrfa_sc)

f_at2m0 = addfile("NASA/MPI-ESM1-2-HR-_hist_1995-2014_daily_CN05.nc","r")
f_at2m1 = addfile("NASA/CESM2-_hist_1995-2014_daily_CN05.nc","r")
f_at2m2 = addfile("NASA/IPSL-CM6A-LR-_hist_1995-2014_daily_CN05.nc","r")
m0  = f_at2m0->pr(:,:,:)
m1  = f_at2m1->pr(:,:,:)
m2  = f_at2m2->pr(:,:,:)

mm0=m0*3600*24
mm1=m1*3600*24
mm2=m2*3600*24

cmip0=new((/3,7305,nn(1),nn(2)/), float)

startday=0
startday_cesm=0
do iy=0,nyear-1
year=1995+iy

if(isleapyear(year))
  add_day=366
else
  add_day=365
end if
endday=startday+add_day-1
endday_cesm=startday_cesm+365-1

cmip0(0,startday:endday,:,:)=mm0(startday:endday,:,:)

if(isleapyear(year))
cmip0(1,startday:startday+31+28,:,:)=mm1(startday_cesm:startday_cesm+31+28,:,:)
cmip0(1,startday+29,:,:)=(mm0(startday+29,:,:)+mm2(startday+29,:,:))/2.0
cmip0(1,startday+29:endday,:,:)=mm1(startday_cesm+28:endday_cesm,:,:)
else
cmip0(1,startday:endday,:,:)=mm1(startday_cesm:endday_cesm,:,:)
end if

cmip0(2,startday:endday,:,:)=mm2(startday:endday,:,:)
startday=endday+1
startday_cesm=endday_cesm+1
end do
cmip0=where(ismissing(cmip0), -9999., cmip0)
cmip0@_FillValue=-9999.
cmipa=dim_avg_n(cmip0,0)

cmipa=where(ismissing(rgm), -9999, cmipa)
cmipa@_FillValue=-9999

cmipa_cc=where(rgm.ge.5,cmipa,-9999.)
cmipa_sc=where(rgm.ge.6,cmipa,-9999.)
cmipa_cc@_FillValue=-9999
cmipa_cc@_FillValue=-9999

copy_VarCoords(c0, cmipa)
copy_VarCoords(c0, cmipa_cc)
copy_VarCoords(c0, cmipa_sc)

setfileoption("nc","Format","LargeFile")

system("rm -rf CWRF-NASA-hist.nc")
fout=addfile("CWRF-NASA-hist.nc", "c")
fout->pr_cwrf=cwrfa
fout->pr_nasa=cmipa
exit
system("rm -rf CWRF-NASA-cc-hist.nc")
fout=addfile("CWRF-NASA-cc-hist.nc", "c")
fout->ccpr_cwrf=cwrfa_cc
fout->ccpr_nasa=cmipa_cc
system("rm -rf CWRF-NASA-sc-hist.nc")
fout=addfile("CWRF-NASA-sc-hist.nc", "c")
fout->scpr_cwrf=cwrfa_sc
fout->scpr_nasa=cmipa_sc

end
