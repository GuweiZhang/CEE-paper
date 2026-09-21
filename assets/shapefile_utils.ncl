

undef("get_shapefile_prefix")
function get_shapefile_prefix(shapefile_name[1]:string)
begin
  s = str_split(shapefile_name,".")
  ns = dimsizes(s)
  if(ns.eq.1)
    return(s)
  else
    return(str_join(s(0:ns-2),"_"))
  end if
end

undef("print_shapefile_info")
procedure print_shapefile_info(shapefile_name[1]:string)
local n, f, var_names, geo_dims, num_features, lat, lon, nvars, dq
begin
  dq = str_get_dq()

  f = addfile(shapefile_name,"r")

  var_names    = getfilevarnames(f)
  geo_dims     = getfilevardimsizes(f,"geometry")
  num_features = geo_dims(0)
  lon          = f->x
  lat          = f->y
  nvars        = dimsizes(var_names)

  print("======================================================================")
  print("Filename: " + dq + shapefile_name + dq)
  print("   Geometry type: " + f@geometry_type)
  print("   # of features: " + num_features)
  print("   Min/max lat:   " + sprintf("%7.2f",min(lat)) + "/" + sprintf("%7.2f",max(lat)))
  print("   Min/max lon:   " + sprintf("%7.2f",min(lon)) + "/" + sprintf("%7.2f",max(lon)))
  print("   Variable names and their types:")
  do n=0,nvars-1
     print("       " + var_names(n) + " : " + getfilevartypes(f,var_names(n)))
  end do
  print("======================================================================")
end

undef("shapefile_mask_data")
function shapefile_mask_data(data:numeric,shapefile_name[1]:string,\
                             opt[1]:logical)
local mask_start_time, mask_end_time,keep_true_value, keep_false_value, \
dims, rank, grid_type, lat1d, lon1d, nlatlon1d, f, segments, geometry, \
segsDims, geomDims, geom_segIndex, geom_numSegs, segs_xyzIndex,
segs_numPnts,numFeatures, lat, lon, shp_mask_names, found, nf, numFeatures, \
startSegment, numSegments, seg, startPT, endPT, lon_sub, lat_sub, \
min_lat_shp, max_lat_shp, min_lon_shp, max_lon_shp
begin
  mask_start_time = get_cpu_time()

  if(.not.isfilepresent(shapefile_name)) then
    print("shapefile_mask_data : Error: " + shapefile_name + \
          " either doesn't exist or is not a valid shapefile.")
    exit
  end if
  f = addfile(shapefile_name,"r")

  DEBUG       = get_res_value_keep(opt,"debug",False)
  KEEP        = get_res_value_keep(opt,"keep",True)
  RETURN_MASK = get_res_value_keep(opt,"return_mask",False)
  LOOP_CHECK  = get_res_value_keep(opt,"loop_check",True)
  SHP_VAR     = opt.and.isatt(opt,"shape_var")
  if(opt.and.isatt(opt,"shape_var")) then
    if(.not.isatt(opt,"shape_names")) then
      print("shapefile_mask_data : Error: if you set 'shape_var' you must also set 'shape_names'")
      exit
    end if
    shp_var_name   = opt@shape_var
    usr_mask_names = opt@shape_names

    if(isfilevar(f,shp_var_name)) then
      shp_mask_names = f->$shp_var_name$
    else
      print("shapefile_mask_data : Error: The given variable name to use does not exist on the given shapefile.")
      exit
    end if

    num_found = 0
    nusr_mask_names = dimsizes(usr_mask_names)
    do i=0,nusr_mask_names-1
      if(any(usr_mask_names(i).eq.shp_mask_names)) then
        num_found = num_found+1
      end if
    end do
    if(num_found.eq.0) then
      print("shapefile_mask_data : Error: none of the given mask_names match the names on the shapefile.")
      exit
    end if
    if(num_found.lt.nusr_mask_names) then
      print("shapefile_mask_data : warning: Only found " + num_found + \
            " of the " + nusr_mask_names)
      print("                      given mask_names on the shapefile.")
    end if
  end if

  if(KEEP) then
    keep_true_value  = 1
    keep_false_value = 0
  else
    keep_true_value  = 0
    keep_false_value = 1
  end if

  dims = dimsizes(data)
  rank = dimsizes(dims)

  grid_type = ""
  if(rank.eq.2.and.\
     isdimnamed(data,0).and.iscoord(data,data!0).and.\
     isdimnamed(data,1).and.iscoord(data,data!1)) then
    lat1d = ndtooned(conform_dims(dims,data&$data!0$,0))
    lon1d = ndtooned(conform_dims(dims,data&$data!1$,1))
    grid_type = "rectilinear"
  else if(rank.eq.2.and.all(isatt(data,(/"lat2d","lon2d"/)))) then

    lat1d = ndtooned(data@lat2d)
    lon1d = ndtooned(data@lon2d)
    if(product(dims).eq.dimsizes(lat1d).and.\
       product(dims).eq.dimsizes(lon1d)) then
      grid_type = "curvilinear"
    end if
  else if(rank.eq.1.and.all(isatt(data,(/"lat1d","lon1d"/)))) then

    lat1d = data@lat1d
    lon1d = data@lon1d
    if(dims.eq.dimsizes(lat1d).and.\
       product(dims).eq.dimsizes(lon1d)) then
      grid_type = "unstructured"
    end if
  end if
  end if
  end if

  if(grid_type.eq."") then
    print("shapefile_mask_data: Error: not a valid rectilinear, curvilinear, or unstructured grid")
    exit
  end if
  nlatlon1d = dimsizes(lat1d)

  segments = f->segments
  geometry = f->geometry
  segsDims = dimsizes(segments)
  geomDims = dimsizes(geometry)

  geom_segIndex = f@geom_segIndex
  geom_numSegs  = f@geom_numSegs
  segs_xyzIndex = f@segs_xyzIndex
  segs_numPnts  = f@segs_numPnts
  numFeatures   = geomDims(0)

  lon = f->x
  lat = f->y

  if(SHP_VAR.and..not.(opt.and.isatt(opt,"minlat").and.isatt(opt,"maxlat").and.\
                               isatt(opt,"minlon").and.isatt(opt,"maxlon"))) then
    found = False
    do nf=0,numFeatures-1
      if(any(shp_mask_names(nf).eq.usr_mask_names)) then
        startSegment = geometry(nf, geom_segIndex)
        numSegments  = geometry(nf, geom_numSegs)
        do seg=startSegment, startSegment+numSegments-1
          startPT = segments(seg, segs_xyzIndex)
          endPT   = startPT + segments(seg, segs_numPnts) - 1
          lat_sub := lat(startPT:endPT)
          lon_sub := lon(startPT:endPT)
          if(found) then
            min_lat_shp = min((/min_lat_shp,min(lat_sub)/))
            max_lat_shp = max((/max_lat_shp,max(lat_sub)/))
            min_lon_shp = min((/min_lon_shp,min(lon_sub)/))
            max_lon_shp = max((/max_lon_shp,max(lon_sub)/))
          else
            min_lat_shp = min(lat_sub)
            max_lat_shp = max(lat_sub)
            min_lon_shp = min(lon_sub)
            max_lon_shp = max(lon_sub)
            found       = True
          end if
        end do
      end if
    end do
  else

    min_lat_shp = min(lat)
    max_lat_shp = max(lat)
    min_lon_shp = min(lon)
    max_lon_shp = max(lon)
  end if

  min_lat_data = min(lat1d)
  max_lat_data = max(lat1d)
  min_lon_data = min(lon1d)
  max_lon_data = max(lon1d)

  min_lat_chk = get_res_value(opt,"minlat",min_lat_shp)
  max_lat_chk = get_res_value(opt,"maxlat",max_lat_shp)
  min_lon_chk = get_res_value(opt,"minlon",min_lon_shp)
  max_lon_chk = get_res_value(opt,"maxlon",max_lon_shp)

  if(.not.LOOP_CHECK) then
    ii_latlon = ind(min_lat_chk.le.lat1d.and.lat1d.le.max_lat_chk.and.\
                    min_lon_chk.le.lon1d.and.lon1d.le.max_lon_chk)
    nii = dimsizes(ii_latlon)
  end if

  if(DEBUG) then
    print("==================================================")
    print("Shapefile:         " + shapefile_name)
    if(SHP_VAR) then
      print("Areas of interest: " + str_join(""+usr_mask_names,","))
    else
      print("Areas of interest: the whole shapefile")
    end if
    print("min_lat_chk:       " + min_lat_chk)
    print("max_lat_chk:       " + max_lat_chk)
    print("min_lon_chk:       " + min_lon_chk)
    print("max_lon_chk:       " + max_lon_chk)
    print("min_lat_data:      " + min_lat_data)
    print("max_lat_data:      " + max_lat_data)
    print("min_lon_data:      " + min_lon_data)
    print("max_lon_data:      " + max_lon_data)
    print(dimsizes(lat1d) + " data values originally")
    if(.not.LOOP_CHECK) then
      print(nii + " data values within given shapefile areas.")
    end if
    if(keep_true_value.eq.1) then
      print("Will keep data values inside given shapefile areas")
    else
      print("Will toss data values inside given shapefile areas")
    end if
  end if

  data_mask_1d = new(nlatlon1d,integer)
  data_mask_1d = keep_false_value

  if(LOOP_CHECK) then
    do nf=0,numFeatures-1
      if(.not.SHP_VAR.or.(SHP_VAR.and.\
         any(shp_mask_names(nf).eq.usr_mask_names))) then
        startSegment = geometry(nf, geom_segIndex)
        numSegments  = geometry(nf, geom_numSegs)
        do seg=startSegment, startSegment+numSegments-1
          startPT = segments(seg, segs_xyzIndex)
          endPT   = startPT + segments(seg, segs_numPnts) - 1
          lat_sub := lat(startPT:endPT)
          lon_sub := lon(startPT:endPT)
          ii_latlon := ind(min(lat_sub).le.lat1d.and.lat1d.le.max(lat_sub).and.\
                           min(lon_sub).le.lon1d.and.lon1d.le.max(lon_sub))
          if(any(ismissing(ii_latlon))) then
            continue
          end if
          nii = dimsizes(ii_latlon)
          do n=0,nii-1
            iltln = ii_latlon(n)
            if(data_mask_1d(iltln).ne.keep_true_value.and.\
               gc_inout(lat1d(iltln),lon1d(iltln),lat_sub,lon_sub)) then
              data_mask_1d(iltln) = keep_true_value
            end if
          end do
        end do
      end if
    end do
  else
    do n=0,nii-1
      iltln = ii_latlon(n)
      do nf=0,numFeatures-1
        if(data_mask_1d(iltln).ne.keep_true_value.and.\
           (.not.SHP_VAR.or.(SHP_VAR.and.\
           any(shp_mask_names(nf).eq.usr_mask_names)))) then
          startSegment = geometry(nf, geom_segIndex)
          numSegments  = geometry(nf, geom_numSegs)
          do seg=startSegment, startSegment+numSegments-1
            startPT = segments(seg, segs_xyzIndex)
            endPT   = startPT + segments(seg, segs_numPnts) - 1
            lat_sub := lat(startPT:endPT)
            lon_sub := lon(startPT:endPT)
            if(.not.(all(lon_sub.lt.min_lon_data).or. \
                     all(lon_sub.gt.max_lon_data).or. \
                     all(lat_sub.lt.min_lat_data).or. \
                     all(lat_sub.gt.max_lat_data)).and.\
               gc_inout(lat1d(iltln),lon1d(iltln),lat_sub,lon_sub)) then
              data_mask_1d(iltln) = keep_true_value
              break
            end if
          end do
        end if
      end do
    end do
  end if
  if(DEBUG) then
    print("==================================================")
    if(KEEP) then
      print(num(data_mask_1d.eq.keep_true_value) + " data values kept")
   else
      print(num(data_mask_1d.ne.keep_true_value) + " data values kept")
    end if
  end if

  if(.not.isatt(data,"_FillValue")) then
    data_msg = default_fillvalue(typeof(data))
  else
    data_msg = data@_FillValue
  end if

  if(RETURN_MASK) then
    data_mask = onedtond(data_mask_1d,dims)
  else
    data_mask = where(onedtond(data_mask_1d,dims).eq.1,data,data_msg)
    copy_VarMeta(data,data_mask)

    if(.not.isatt(data,"_FillValue")) then
      data_mask@_FillValue = data_msg
    end if
  end if

  if(DEBUG) then

    mask_end_time = get_cpu_time()
    print("shapefile_mask_data: elapsed time: " + \
          (mask_end_time-mask_start_time) + " CPU seconds.")
    print("==================================================")
  end if
  return(data_mask)
end

undef("create_shapefile_map")
function create_shapefile_map(wks,shapefile_name,geometry_type,lat,lon)
local res
begin
  res                       = True

  res@tiMainString          = shapefile_name

  res@gsnMaximize           = True
  res@gsnDraw               = False
  res@gsnFrame              = False

  if(geometry_type.eq."point") then
    res@mpOutlineOn           = True
    res@mpOutlineBoundarySets = "AllBoundaries"
  else
    res@mpFillOn              = False
    res@mpOutlineOn           = False
  end if
  res@mpMinLatF             = min(lat)
  res@mpMaxLatF             = max(lat)
  res@mpMinLonF             = min(lon)
  res@mpMaxLonF             = max(lon)

  res@pmTickMarkDisplayMode = "Always"

  map = gsn_csm_map(wks,res)

  return(map)
end

undef("plot_shapefile")
procedure plot_shapefile(shapefile_name)
local f, wks, shp_type, sres, geometry_type
begin

  f = addfile(shapefile_name,"r")

  if(.not.isatt(f,"geometry_type")) then
    print("plot_shapefile: Error: This doesn't appear to be a valid shapefile")
    print("No 'geometry_type' attribute is present.")
    exit
  else if(.not.any(f@geometry_type.eq.(/"point","polyline","polygon"/))) then
    print("plot_shapefile: Warning: the 'geometry_type' attribute on '" + shapefile_name + "'")
    print("             is not set to 'point', 'polyline', or 'polygon'.")
    print("             Will try to plot this data using 'point', but you")
    print("             may want to examine the file further to make sure")
    print("             it is correct.")
    geometry_type = "point"
  else
    geometry_type = f@geometry_type
  end if
  end if

  wks = gsn_open_wks("png",get_shapefile_prefix(shapefile_name))

  lat = f->y
  lon = f->x
  map = create_shapefile_map(wks,shapefile_name,geometry_type,lat,lon)

  sres = True
  if(geometry_type.eq."point") then
    sres@gsMarkerIndex = 16
    id = gsn_add_shapefile_polymarkers(wks,map,shapefile_name,sres)
  else if(geometry_type.eq."polyline") then
    id = gsn_add_shapefile_polylines(wks,map,shapefile_name,sres)
  else if(geometry_type.eq."polygon") then
    sres@gsFillColor = "SkyBlue"
    id1 = gsn_add_shapefile_polygons(wks,map,shapefile_name,sres)
    id2 = gsn_add_shapefile_polylines(wks,map,shapefile_name,sres)
  end if
  end if
  end if

  draw(map)
  frame(wks)
end
