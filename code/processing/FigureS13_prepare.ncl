

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
begin

  f0 = addfile("CWRF_30km_topo.nc", "r")
  tcwrf = f0->topo

  f1 = addfile("external_inputs/geo_em.d01_updated201705.nc", "r")
  lu = f1->LU_INDEX(0,:,:)
  lon2d = f1->XLONG_M(0,:,:)
  lat2d = f1->XLAT_M(0,:,:)

  lu@lat2d = lat2d
  lu@lon2d = lon2d

  copy_VarCoords(lu, tcwrf)
  tcwrf = where(lu.eq.16, tcwrf, tcwrf@_FillValue)
  lu = where(lu.eq.16, lu@_FillValue, lu)

  tcwrf@lat2d = lat2d
  tcwrf@lon2d = lon2d

  nlat = 171
  nlon = 231
  luzone = lu

  luzone(0:14,:) = -9999
  luzone(:,0:14) = -9999
  luzone(nlat-1-14:nlat-1,:) = -9999
  luzone(:,nlon-1-14:nlon-1) = -9999

  luzone = where(luzone.eq.-9999, luzone, 32676)
  luzone@_FillValue = 32676
  luzone@lat2d = lat2d
  luzone@lon2d = lon2d

  out_filename = "FigureS13_plot_data.nc"
  if (isfilepresent(out_filename)) then
    print("Output already exists: " + out_filename)
    exit
  end if
  fout = addfile(out_filename, "c")

  fout->tcwrf = tcwrf
  fout->lu = lu
  fout->luzone = luzone
  fout->lat2d = lat2d
  fout->lon2d = lon2d

  print("Success! Data for Figure S13 saved to: " + out_filename)
end
