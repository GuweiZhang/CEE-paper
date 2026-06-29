begin
  ssp = (/"126","245","585"/)
  subregion = (/"CN","NE","NC","NW","EC","CC","SC"/)

  f = addfile("Figure1_plot_data.nc", "r")
  obs = f->obs_plot
  bias0 = f->bias_cmip_plot
  bias1 = f->bias_cwrf_plot
  cwrf_pattern = f->cwrf_pattern
  tt = f->tt_mask
  cwrf_new = f->cwrf_new
  pcc = f->pcc
  abias = f->abias
  delete(tt@long_name)
  delete(obs@long_name)
  delete(bias0@long_name)
  delete(bias1@long_name)  
  ;***************************************************************
  wks = gsn_open_wks("eps", "Figure1")

  res = True 
  res@gsnFrame = False
  res@gsnDraw = False  
  res@gsnAddCyclic = False

  ;---------------------------------------------------------------
 
  res@mpMinLatF = 15.
  res@mpMaxLatF = 56.
  res@mpMinLonF = 72.
  res@mpMaxLonF = 136.
  res@gsnMajorLatSpacing = 10. 
  res@gsnMajorLonSpacing = 20. 
  res@tmXBMinorOn = False
  res@tmYLMinorOn = False
  res@mpFillOn = True
  res@mpDataSetName = "Earth..4"
  res@mpDataBaseVersion = "MediumRes"
  res@mpAreaMaskingOn = True
  res@mpMaskAreaSpecifiers = (/"China"/)
  res@mpOutlineSpecifiers = (/"China","China:Provinces"/)
    
  res@mpLandFillColor = "white"
  res@mpInlandWaterFillColor = "white"
  res@mpOceanFillColor = "white"
  res@mpFillBoundarySets = "NoBoundaries"
  res@mpOutlineBoundarySets = "NoBoundaries"
  res@mpNationalLineColor = "black"
  res@mpProvincialLineColor = "Gray"
  res@mpGeophysicalLineColor = "black"
  res@mpNationalLineThicknessF = 1.
  res@mpProvincialLineThicknessF = 0.5
  res@mpGeophysicalLineThicknessF = 0.5

  res@tmYLLabelFontHeightF = 0.025
  res@tmXBLabelFontHeightF = 0.025
  res@pmLabelBarOrthogonalPosF = 0.1

  res@tmBorderThicknessF = 1.0
  res@tmXBMajorThicknessF = res@tmBorderThicknessF
  res@tmYLMajorThicknessF = res@tmBorderThicknessF
  res@gsnLeftString=""
  ;res@tiMainString=""
  ;---------------------------------------------------------------
  res@cnLevelSelectionMode = "ExplicitLevels"
  res@lbLabelBarOn = False
  res@lbBoxSeparatorLinesOn = False
  res@cnFillOn = True
  res@cnFillDrawOrder = "PreDraw"
  res@cnLinesOn = False    
  res@cnLineLabelsOn = False          
  res@lbLabelAutoStride = True
  res@pmTickMarkDisplayMode = "Always"

  res@tmXTOn = False
  res@tmYROn = False

  res@tmXBLabelFont = 25
  res@tmYLLabelFont = 25

  res@cnFillPalette = "precip2_17lev"
  res@cnLevelSelectionMode = "ExplicitLevels"
  res@cnLevels = ispan(0, 20, 2)

  plot00 = new(3, graphic)
  plot00(0) = gsn_csm_contour_map_ce(wks, obs, res)
  delete(res@cnLevels)

  ress = res
  ress@cnFillPalette = "BlAqGrWh2YeOrReVi22"
  ress@cnLevels = fspan(-1, 1, 11)
  plot00(1) = gsn_csm_contour_map_ce(wks, bias0, ress)
  plot00(2) = gsn_csm_contour_map_ce(wks, bias1, ress)

  tes = True
  tes@txFontHeightF = 0.022
  tes@txJust = "CenterLeft"
  tes@txFont = 25

  a1 = gsn_add_text(wks, plot00(1), "PCC: " + tostring_with_format(pcc(0), "%3.2f"), 74, 22, tes)
  a0 = gsn_add_text(wks, plot00(1), "ABIAS: " + tostring_with_format(abias(0), "%3.2f d/yr"), 74, 18, tes)

  b1 = gsn_add_text(wks, plot00(2), "PCC: " + tostring_with_format(pcc(1), "%3.2f"), 74, 22, tes)
  b0 = gsn_add_text(wks, plot00(2), "ABIAS: " + tostring_with_format(abias(1), "%3.2f d/yr"), 74, 18, tes)

  res@cnFillPalette = "hotcold_18lev"
  res@cnLevels = (/-5,-3,-2,-1,-0.5,-0.1,0,0.1,0.5,1,2,3,5/)

  res2 = True 
  res2@gsnFrame = False
  res2@gsnDraw = False 
  res2@gsnAddCyclic = False

  ;---------------------------------------------------------------

  res2@cnFillDrawOrder = "PostDraw"
  res2@cnFillOn = True
  res2@cnMonoFillPattern = False   
  res2@cnMonoFillColor = True   
  res2@cnLineLabelsOn = False  
  res2@cnInfoLabelOn = False   
  res2@cnLinesOn = False  
  res2@cnLevelSelectionMode = "ExplicitLevels"       
  res2@cnLevels = (/0.9/)
  res2@cnFillPatterns = (/-1,17/)
  res2@lbPerimOn = False   
  res2@cnFillScaleF = 0.6
  res2@cnFillDotSizeF = 0.002

  plot0 = new(3, graphic)

  res_text = True
  res_text@txFontHeightF = 0.025

  do i=0, 2
    plot0(i) = gsn_csm_contour_map_overlay(wks, cwrf_pattern(i,:,:), tt(i,:,:), res, res2)
  end do

  nhres = True
  nhres = res
  nhres@gsnMaximize = False
  nhres@gsnFrame = False
  nhres@gsnDraw = False      
  nhres@vpHeightF = 0.13    
  nhres@vpWidthF = 0.13   
  nhres@mpMinLatF = 2.0    
  nhres@mpMaxLatF = 23.0
  nhres@mpMinLonF = 105.0
  nhres@mpMaxLonF = 123.0
  nhres@lbLabelBarOn = False
  nhres@tmXBOn = False 
  nhres@tmYLOn = False
  nhres@tmYROn = False
  nhres@tmXTOn = False
  nhres@gsnLeftString = ""
  nhres@gsnRightString = ""

  nhres@mpNationalLineThicknessF = 0.5
  nhres@mpProvincialLineThicknessF = 0.25
  nhres@mpGeophysicalLineThicknessF = 0.25

  nhres@tmBorderThicknessF = 0.75
  nhres@tmXBMajorThicknessF = res@tmBorderThicknessF
  nhres@tmYLMajorThicknessF = res@tmXBMajorThicknessF

  nhplot = new(3, graphic)
  plotnh = new(3, graphic)

  do j=0, 2
    nhplot(j) = gsn_csm_contour_map_overlay(wks, cwrf_pattern(j,:,:), tt(j,:,:), nhres, res2)
  end do

  nhplot00 = new(3, graphic)
  plotnh00 = new(3, graphic)

  delete(nhres@cnLevels)

  nhres@cnFillPalette = "precip_11lev"
  nhres@cnLevelSelectionMode = "ExplicitLevels"
  nhres@cnLevels = ispan(1, 10, 1)
  nhplot00(0) = gsn_csm_contour_map_ce(wks, obs, nhres)

  delete(nhres@cnLevels)
  nhres@cnFillPalette = "BlAqGrWh2YeOrReVi22"
  nhres@cnLevelSelectionMode = "ExplicitLevels"
  nhres@cnLevels = fspan(-1, 1, 11)
  nhplot00(1) = gsn_csm_contour_map_ce(wks, bias0, nhres)
  nhplot00(2) = gsn_csm_contour_map_ce(wks, bias1, nhres)

  adres = True
  adres@amParallelPosF = 0.5 
  adres@amOrthogonalPosF = 0.5  
  adres@amJust = "BottomRight"
  
  do i=0, 2
    plotnh(i) = gsn_add_annotation(plot0(i), nhplot(i), adres)
    plotnh00(i) = gsn_add_annotation(plot00(i), nhplot00(i), adres)
  end do

  title = (/"SSP1-2.6","SSP2-4.5","SSP5-8.5"/)
  plot_title = new(dimsizes(title)*2, graphic)
  
  res_text = True
  res_text@txJust = "CenterLeft"
  res_text@txFontHeightF = 0.03
  res_text@txFont = 25

  do i=0, dimsizes(title)-1
    plot_title(i) = gsn_add_text(wks, plot0(i), title(i), 73.5, 53, res_text)
  end do

  title_obs = (/"OBS","CMIP6_Bias","CWRF_Bias"/)
  do i=0, 2
    plot_title(i+3) = gsn_add_text(wks, plot00(i), title_obs(i), 73.5, 53, res_text)
  end do

  ;---------------------------------------------------------------------------------------------------------------------

  res3 = True               
  res3@gsnDraw = False            
  res3@gsnFrame = False              
  res3@vpXF = 0
  res3@vpHeightF = 0.4               
  res3@vpWidthF = 0.9

  res3@tmXTOn = False
  res3@tmYROn = False

  res3@xyMonoLineColor = False 
  res3@trXMinF = 0.3            
  res3@trXMaxF = 10.7
  res3@tmXBMode = "Explicit"
  res3@tmXBValues = (/1,2,3,4,5,6,7,9,10/)
  res3@tmXBLabels = (/"China","NE","NC","NW","EC","CC","SC","CC","SC"/)

  res3@gsnLeftStringOrthogonalPosF = 0.04
  res3@gsnRightStringOrthogonalPosF = 0.04
  res3@gsnLeftStringFontHeightF = 0.01
  res3@gsnRightStringFontHeightF = 0.01
  res3@tmYLLabelFontHeightF = 0.014
  res3@tmXBLabelFontHeightF = 0.018

  res3@tmXTOn = False
  res3@tmYROn = False

  res3@gsnYRefLine = 0.
  res3@tmXBMajorOutwardLengthF = 0.01
  res3@tmYLMajorOutwardLengthF = 0.01
  res3@tmXBMajorLengthF = 0.01
  res3@tmYLMajorLengthF = 0.01

  res3@tmYLMinorOn = False
  res3@tmXBMinorLengthF = 0.005
  res3@tmYLMinorLengthF = 0.005

  res3@gsnXYBarChart = False
  res3@gsnXYBarChartBarWidth = 0.145
  res3@xyLineThicknessF = 0.1
  res3@xyLineColor = "black"

  res3@tmBorderThicknessF = 1.
  res3@tmXBMajorThicknessF = 1.
  res3@tmYLMajorThicknessF = 1.

  res3@gsnYRefLineColor = "gray40"

  res3@tmXBLabelFont = 25
  res3@tmYLLabelFont = res3@tmXBLabelFont
  res3@tmYLMode = "Explicit"

  color = (/"forestgreen","dodgerblue3","red3"/)

  res3_text = True
  res3_text@txFontHeightF = 0.025

  res3@xyLineThicknesses = 6.0
  res3@xyLineColor = "white"

  dnhall_heat0 = cwrf_new(0,0,:)
  dnhall_heat0 = 0

  plot2 = new(1, graphic)

  YMAX = 1.5
  YMIN = -0.5
  res3@trYMaxF = YMAX
  res3@trYMinF = YMIN              
  xxtime0 = fspan(0.84,9.84,10)
  xxtime1 = fspan(1.0,10.0,10)
  xxtime2 = fspan(1.16,10.16,10)

  res3@tmYLValues = fspan(YMIN, YMAX, 5)
  res3@tmYLLabels = tostring_with_format(res3@tmYLValues, "%3.1f")

  res3@tiYAxisString = "Changes in frequency (d/yr)"
  res3@tiYAxisFont = 25
  res3@tiYAxisFontHeightF = 0.015
  plot2 = gsn_csm_xy(wks, xxtime0, dnhall_heat0, res3)
  delete(res3@tiYAxisString)

  lsres3 = True
  lsres3@gsLineThicknessF = 10.

  dum0 = new(dimsizes(subregion)+3, graphic)
  dum1 = new(dimsizes(subregion)+3, graphic)
  dum2 = new(dimsizes(subregion)+3, graphic)

  do i=0, dimsizes(subregion)-1
    lsres3@gsLineColor = color(0)
    dum0(i) = gsn_add_polyline(wks, plot2, (/xxtime0(i),xxtime0(i)/), (/cwrf_new(0,1,i),cwrf_new(0,2,i)/), lsres3)
    lsres3@gsLineColor = color(1)
    dum1(i) = gsn_add_polyline(wks, plot2, (/xxtime1(i),xxtime1(i)/), (/cwrf_new(1,1,i),cwrf_new(1,2,i)/), lsres3)
    lsres3@gsLineColor = color(2)
    dum2(i) = gsn_add_polyline(wks, plot2, (/xxtime2(i),xxtime2(i)/), (/cwrf_new(2,1,i),cwrf_new(2,2,i)/), lsres3)
  end do

  do i=dimsizes(subregion)+1, dimsizes(subregion)+2
    lsres3@gsLineColor = color(0)
    dum0(i) = gsn_add_polyline(wks, plot2, (/xxtime0(i),xxtime0(i)/), (/cwrf_new(0,1,i),cwrf_new(0,2,i)/), lsres3)
    lsres3@gsLineColor = color(1)
    dum1(i) = gsn_add_polyline(wks, plot2, (/xxtime1(i),xxtime1(i)/), (/cwrf_new(1,1,i),cwrf_new(1,2,i)/), lsres3)
    lsres3@gsLineColor = color(2)
    dum2(i) = gsn_add_polyline(wks, plot2, (/xxtime2(i),xxtime2(i)/), (/cwrf_new(2,1,i),cwrf_new(2,2,i)/), lsres3)
  end do
  
  xd = 0.2
  lsres3@gsLineColor = color(0)
  sample0 = gsn_add_polyline(wks, plot2, (/8.3+xd,9.0+xd/), (/-0.1,-0.1/), lsres3)
  lsres3@gsLineColor = color(1)
  sample1 = gsn_add_polyline(wks, plot2, (/8.3+xd,9.0+xd/), (/-0.25,-0.25/), lsres3)
  lsres3@gsLineColor = color(2)
  sample2 = gsn_add_polyline(wks, plot2, (/8.3+xd,9.0+xd/), (/-0.4,-0.4/), lsres3)

  gsres3 = True
  gsres3@gsMarkerIndex = 16
  gsres3@gsMarkerSizeF = 0.006
  gsres3@gsMarkerColor = "black"
  gsres3@gsMarkerThicknessF = 2.0
  
  cdum0 = new(dimsizes(subregion)+3, graphic)
  cdum1 = new(dimsizes(subregion)+3, graphic)
  cdum2 = new(dimsizes(subregion)+3, graphic)

  do i=0, dimsizes(subregion)+2
    cdum0(i) = gsn_add_polymarker(wks, plot2, xxtime0(i), cwrf_new(0,0,i), gsres3)
    cdum1(i) = gsn_add_polymarker(wks, plot2, xxtime1(i), cwrf_new(1,0,i), gsres3)
    cdum2(i) = gsn_add_polymarker(wks, plot2, xxtime2(i), cwrf_new(2,0,i), gsres3)
  end do

  sample00 = gsn_add_polymarker(wks, plot2, (9.0-8.3)*0.5+8.3+xd, -0.1, gsres3)
  sample01 = gsn_add_polymarker(wks, plot2, (9.0-8.3)*0.5+8.3+xd, -0.25, gsres3)
  sample02 = gsn_add_polymarker(wks, plot2, (9.0-8.3)*0.5+8.3+xd, -0.4, gsres3)

  gsres3@gsMarkerColor = "white"
  gsres3@gsMarkerIndex = 16 
  gsres3@gsMarkerSizeF = 0.002
  gsres3@gsMarkerThicknessF = 3.0

  ccdum0 = new(dimsizes(subregion)+3, graphic)
  ccdum1 = new(dimsizes(subregion)+3, graphic)
  ccdum2 = new(dimsizes(subregion)+3, graphic)

  do i=0, dimsizes(subregion)-1
    ccdum0(i) = gsn_add_polymarker(wks, plot2, xxtime0(i), cwrf_new(0,0,i), gsres3)
    ccdum1(i) = gsn_add_polymarker(wks, plot2, xxtime1(i), cwrf_new(1,0,i), gsres3)
    ccdum2(i) = gsn_add_polymarker(wks, plot2, xxtime2(i), cwrf_new(2,0,i), gsres3)
  end do

  do i=dimsizes(subregion)+1, dimsizes(subregion)+2
    ccdum0(i) = gsn_add_polymarker(wks, plot2, xxtime0(i), cwrf_new(0,0,i), gsres3)
    ccdum1(i) = gsn_add_polymarker(wks, plot2, xxtime1(i), cwrf_new(1,0,i), gsres3)
    ccdum2(i) = gsn_add_polymarker(wks, plot2, xxtime2(i), cwrf_new(2,0,i), gsres3)
  end do

  sample000 = gsn_add_polymarker(wks, plot2, (9.0-8.3)*0.5+8.3+xd, -0.1, gsres3)
  sample001 = gsn_add_polymarker(wks, plot2, (9.0-8.3)*0.5+8.3+xd, -0.25, gsres3)
  sample002 = gsn_add_polymarker(wks, plot2, (9.0-8.3)*0.5+8.3+xd, -0.4, gsres3)

  res3_text = True
  res3_text@txJust = "CenterLeft"
  res3_text@txFontHeightF = 0.018
  res3_text@txFont = 25

  plot_title0 = new(2, graphic)
  plot_title0(0) = gsn_add_text(wks, plot2, "Storm rain", 0.5, (YMAX-YMIN)*0.93+YMIN, res3_text)
  plot_title0(1) = gsn_add_text(wks, plot2, "Heavy rain", 8.2, (YMAX-YMIN)*0.93+YMIN, res3_text)

  res3_text@txFontHeightF = 0.012
  sample0000 = gsn_add_text(wks, plot2, "SSP1-2.6", (9.0-8.3)*0.5+8.3+0.9, -0.1, res3_text)
  sample0001 = gsn_add_text(wks, plot2, "SSP2-4.5", (9.0-8.3)*0.5+8.3+0.9, -0.25, res3_text)
  sample0002 = gsn_add_text(wks, plot2, "SSP5-8.5", (9.0-8.3)*0.5+8.3+0.9, -0.4, res3_text)

  lsres3@gsLineThicknessF = 1.5
  lsres3@gsLineColor = "black"
  line0 = gsn_add_polyline(wks, plot2, (/8,8/), (/YMAX,YMIN/), lsres3)
  
  ;---------------------------------------------------------
  
  resdP = True  
  resdP@gsnFrame = False                
  resdP@gsnPanelRowSpec = True  
  resdP@gsnPanelCenter = True
  resdP@gsnPanelLabelBar = True
  resdP@lbLabelFont = 25
  resdP@gsnPanelXWhiteSpacePercent = 3
  resdP@gsnPanelYWhiteSpacePercent = 2
  resdP@amJust = "TopLeft"  
  resdP@gsnMaximize = True  
  resdP@gsnPanelFigureStringsFontHeightF = 0.013
  resdP@gsnPanelFigureStringsPerimOn = False
  resdP@lbBoxLineThicknessF = 0.5
  resdP@lbBoxSeparatorLinesOn = False
  resdP@gsnPanelFigureStringsFontHeightF = 0.01
  resdP@pmLabelBarWidthF = 0.55
  resdP@pmLabelBarHeightF = 0.04
  resdP@lbLabelFontHeightF = 0.008

  resdP@gsnPanelTop = 0.75
  resdP@gsnPanelBottom = 0.575
  gsn_panel(wks, plot0, (/3/), resdP) 

  resdP@gsnPanelLabelBar = False
  resdP@gsnPanelTop = 0.54
  resdP@gsnPanelBottom = 0.20
  gsn_panel(wks, plot2, (/1/), resdP) 

  resdP@gsnPanelLabelBar = True
  resdP@pmLabelBarWidthF = 0.18
  resdP@pmLabelBarHeightF = 0.04
  resdP@lbLabelFontHeightF = 0.008
  resdP@gsnPanelTop = 0.97
  resdP@gsnPanelBottom = 0.795

  resdP@gsnPanelLeft = 0.14
  resdP@gsnPanelRight = 0.38
  gsn_panel(wks, plot00(0), (/1/), resdP) 
  
  resdP@pmLabelBarWidthF = 0.36
  xd = 0.03
  resdP@gsnPanelLeft = 0.34+xd
  resdP@gsnPanelRight = 0.83+xd
  gsn_panel(wks, plot00(1:), (/2/), resdP) 

  res3_text@txFontHeightF = 0.008
  gsn_text_ndc(wks, "units: d/yr", 0.8, 0.814, res3_text)
  gsn_text_ndc(wks, "units: d/yr", 0.365, 0.814, res3_text)
  gsn_text_ndc(wks, "units: d/yr", 0.78, 0.594, res3_text)

  res3_text@txJust = "CenterLeft"
  res3_text@txFontHeightF = 0.018
  res3_text@txFont = 26

  gsn_text_ndc(wks, "a", 0.15, 0.99, res3_text)
  gsn_text_ndc(wks, "b", 0.15, 0.77, res3_text)
  gsn_text_ndc(wks, "c", 0.15, 0.55, res3_text)

  frame(wks)
end