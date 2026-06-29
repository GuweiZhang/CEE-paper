
load "add_changjiang_huanghei.ncl"
load "shapefile_utils.ncl"

begin
  f = addfile("FigureS12_plot_data.nc", "r")
  tcwrf = f->tcwrf
  lu = f->lu
  luzone = f->luzone
  lat2d = f->lat2d
  lon2d = f->lon2d

  if (isatt(lu, "lat2d")) then delete(lu@lat2d) end if
  if (isatt(lu, "lon2d")) then delete(lu@lon2d) end if
  if (isatt(tcwrf, "lat2d")) then delete(tcwrf@lat2d) end if
  if (isatt(tcwrf, "lon2d")) then delete(tcwrf@lon2d) end if
  if (isatt(luzone, "lat2d")) then delete(luzone@lat2d) end if
  if (isatt(luzone, "lon2d")) then delete(luzone@lon2d) end if

  lu@lat2d = lat2d
  lu@lon2d = lon2d
  tcwrf@lat2d = lat2d
  tcwrf@lon2d = lon2d
  luzone@lat2d = lat2d
  luzone@lon2d = lon2d

  dims = dimsizes(lat2d)
  nlat = dims(0)
  nlon = dims(1)
  buff_zone = 0

  pltType = "eps"
  wks = gsn_open_wks(pltType, "FigureS12")  
  plot = new(1, graphic)

  usgsinfo = (/"Urban and Built-Up", "Dryland Cropland and Pasture", "Irrigated Cropland and Pasture", "Cropland/Grassland Mosaic", "Cropland/Woodland Mosaic", "Grassland", "Shrubland", "Mixed Shrubland/Grassland", "Savanna", "Deciduous Broadleaf Forest", "Deciduous Needleleaf Forest", "Evergreen Broadleaf Forest", "Evergreen Needleleaf Forest", "Mixed Forest", "Water Bodies", "Herbaceous Wetland", "Wooded Wetland", "Barren or Sparsely Vegetated", "Wooded Tundra", "Mixed Tundra", "Snow or Ice"/)

  colorscheme = (/"red2", "forestgreen", "seagreen3", "olivedrab1", "cadetblue4", "yellow", "orange", "moccasin", "darkolivegreen1", "pink", "hotpink", "darkolivegreen", "purple", "mediumaquamarine", "deepskyblue", "lightskyblue", "blue", "lemonchiffon1", "gray30", "gray60", "white"/)

  levels = (/1,2,3,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,21,22/)

  res = True
  res@gsnDraw = False
  res@gsnFrame = False
  res@gsnAddCyclic = False
  res@gsnMaximize = False
  res@cnFillOn = True
  res@cnFillMode = "RasterFill"
  res@cnLinesOn = False
  res@cnLevelSelectionMode = "ExplicitLevels"
  res@cnLevels = levels + 0.1
  res@cnFillPalette = colorscheme
  res@gsnSpreadColors = False
  res@lbLabelBarOn = False
  res@cnInfoLabelOn = False
  res@cnLineLabelsOn = False
  res@lbLabelPosition = "Center"
  res@lbLabelAlignment = "BoxCenters"
  res@lbLabelStride = 1
  res@lbLabelAutoStride = False
  res@pmLabelBarHeightF = 0.075
  res@pmLabelBarWidthF = 0.60
  res@pmLabelBarOrthogonalPosF = 0.01
  res@lbLabelFontColor = "black"
  res@lbLabelFontHeightF = 0.011
  res@lbLabelFontThicknessF = 1.5
  res@gsnRightString = ""
  res@gsnLeftString = ""

  res2 = True
  res2@gsnDraw = False
  res2@gsnFrame = False
  res2@gsnAddCyclic = False
  res2@lbLabelBarOn = False
  res2@cnFillOn = True
  res2@cnLinesOn = False
  res2@cnLevelSelectionMode = "ExplicitLevels"
  res2@cnLevels = (/-9998/)
  res2@cnMonoFillPattern = False
  res2@cnConstFEnableFill = True
  res2@cnFillPatterns = (/6,6/)
  res2@cnFillColors = (/"black","black"/)
  res2@cnInfoLabelOn = False
  res2@gsnRightString = ""
  res2@gsnLeftString = ""
  res2@cnConstFLabelBackgroundColor = "transparent"
  res2@cnConstFLabelOn = False

  plot3 = gsn_csm_contour(wks, lu, res)
  plot4 = gsn_csm_contour(wks, luzone, res2)

  res3 = True
  res3@gsnDraw = False
  res3@gsnFrame = False
  res3@gsnAddCyclic = False
  res3@gsnMaximize = False
  res3@cnFillOn = True
  res3@cnFillMode = "RasterFill"
  res3@cnLinesOn = False
  res3@cnLineLabelsOn = False
  gsn_define_colormap(wks, "MPL_PuBu")
  gsn_reverse_colormap(wks)
  res3@cnLevels = fspan(0, -3000, 254)
  res3@lbLabelBarOn = False
  res3@mpOutlineOn = True
  res3@mpDataBaseVersion = "MediumRes"
  res3@mpDataSetName = "Earth..4"
  res3@mpOutlineSpecifiers = (/"China"/)
  res3@mpNationalLineColor = "black"
  res3@mpNationalLineDashPattern = 0.
  res3@mpNationalLineThicknessF = 5.
  res3@mpProjection = "LambertConformal"
  res3@mpLambertParallel1F = 30
  res3@mpLambertParallel2F = 60
  res3@mpLambertMeridianF = 110
  res3@mpLimitMode = "Corners"
  res3@pmTickMarkDisplayMode = "Always"
  res3@mpLeftCornerLatF = lat2d(nlat-1-buff_zone, buff_zone)
  res3@mpLeftCornerLonF = lon2d(nlat-1-buff_zone, buff_zone)
  res3@mpRightCornerLatF = lat2d(buff_zone, nlon-1-buff_zone)
  res3@mpRightCornerLonF = lon2d(buff_zone, nlon-1-buff_zone)
  res3@tmXBOn = False
  res3@tmXTOn = False
  res3@tmYLOn = False
  res3@tmYROn = False
  res3@tmBorderThicknessF = 3.0

  plot(0) = gsn_csm_contour_map(wks, tcwrf, res3)

  river = True
  river@gsLineThicknessF = 1.0
  river@gsLineColor = "royalblue"
  shp_name = "river-1j/river-1j.shp"
  ploy = gsn_add_shapefile_polylines(wks, plot(0), shp_name, river)

  river@gsLineThicknessF = 4.0
  river@gsLineColor = "red3"
  river@gsLineDashPattern = 5.
  shp_name1 = "region_internal_lines.shp"
  ploy1 = gsn_add_shapefile_polylines(wks, plot(0), shp_name1, river)

  overlay(plot(0), plot3)
  overlay(plot(0), plot4)

  res3_text = True
  res3_text@txJust = "CenterLeft"
  res3_text@txFont = 26
  res3_text@txFontHeightF = 0.012
  res3_text@txFontColor = "black"
  
  r0 = gsn_add_text(wks, plot4, "NW", 90, 38, res3_text)
  r1 = gsn_add_text(wks, plot4, "NC", 111.5, 41, res3_text)
  r2 = gsn_add_text(wks, plot4, "NE", 125, 45, res3_text)
  r3 = gsn_add_text(wks, plot4, "CC", 111, 30, res3_text)
  r4 = gsn_add_text(wks, plot4, "EC", 117, 31, res3_text)
  r5 = gsn_add_text(wks, plot4, "SC", 104, 26, res3_text)

  resP = True
  resP@gsnFrame = False
  resP@gsnPanelLabelBar = False
  resP@lbLabelFontHeightF = 0.015
  resP@gsnPanelBottom = 0.2
  resP@gsnPanelMainString = ""
  resP@lbLabelPosition = "Right"
  resP@lbLabelAlignment = "BoxCenters"
  resP@lbOrientation = "Vertical"
  resP@lbLabelFontHeightF = 0.01
  if (isatt(res, "lbLabelStrings")) then
    resP@lbLabelStrings = res@lbLabelStrings
  end if
  resP@lbLabelJust = "CenterCenter"
  resP@gsnMaximize = True
  resP@lbLabelOffsetF = -0.25
  resP@pmLabelBarWidthF = 0.08
  resP@lbLabelFontColor = "black"
  resP@lbLabelFontThicknessF = "1.5"

  gsn_panel(wks, plot, (/1,1/), resP)

  lbres = True
  lbres@vpWidthF = 0.06
  lbres@vpHeightF = 0.14
  lbres@lbBoxMajorExtentF = 0.08
  lbres@lbMonoFillPattern = True
  lbres@lbLabelFont = 25
  lbres@lbLabelFontHeightF = 0.01
  lbres@lbLabelJust = "CenterLeft"
  lbres@lbPerimOn = False
  lbres@lgPerimColor = "white"
  lbres@lbBoxLineColor = "black"
  lbres@lbBoxLineThicknessF = 0.1

  yaa = 0.28
  xa = 0.04
  yd = 0.03
  xd = 0.24

  do i = 0, 4   
    do j = 0, 3
      lbres@lbFillColors = colorscheme(i+j*5)
      labels = usgsinfo(i+j*5)   
      gsn_labelbar_ndc(wks, 1, labels, xa+j*xd, yaa-yd*i, lbres)
    end do 
  end do

  frame(wks)
end