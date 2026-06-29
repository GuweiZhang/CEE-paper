

begin
  f = addfile("FigureS3_plot_data.nc", "r")
  cwrf_plot = f->cwrf_plot
  cwrf_region = f->cwrf_region

  subregion = (/"CN","NE","NC","NW","EC","CC","SC"/)
  ssp = (/"126","245","585"/)

  wks = gsn_open_wks("eps", "FigureS3")

  res = True 
  res@gsnFrame = False
  res@gsnDraw = False  
  res@gsnAddCyclic = False

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

  res@cnLevelSelectionMode = "ExplicitLevels"
  res@lbLabelBarOn = False
  res@lbBoxSeparatorLinesOn = False
  res@cnFillOn = True
  res@cnFillPalette = "MPL_BrBG"
  res@cnFillDrawOrder = "PreDraw"
  res@cnLinesOn = False    
  res@cnLineLabelsOn = False          
  res@lbLabelAutoStride = True
  res@pmTickMarkDisplayMode = "Always"
  res@tmXTOn = False
  res@tmYROn = False
  res@cnLevels = ispan(-200, 200, 25)
  res@tmXBLabelFont = 25
  res@tmYLLabelFont = 25

  plot0 = new(3, graphic)

  do i = 0, 2
    plot0(i) = gsn_csm_contour_map_ce(wks, cwrf_plot(i,:,:), res)
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

  do j = 0, 2
    nhplot(j) = gsn_csm_contour_map_ce(wks, cwrf_plot(j,:,:), nhres)
  end do

  adres = True
  adres@amParallelPosF = 0.5 
  adres@amOrthogonalPosF = 0.5  
  adres@amJust = "BottomRight"
  
  do i = 0, 2
    plotnh(i) = gsn_add_annotation(plot0(i), nhplot(i), adres)
  end do

  title = (/"SSP1-2.6","SSP2-4.5","SSP5-8.5"/)
  plot_title = new(dimsizes(title), graphic)
  
  res_text = True
  res_text@txJust = "CenterLeft"
  res_text@txFontHeightF = 0.03
  res_text@txFont = 25

  do i = 0, dimsizes(title)-1
    plot_title(i) = gsn_add_text(wks, plot0(i), title(i), 73.5, 53, res_text)
  end do

  res22 = True               
  res22@gsnDraw = False            
  res22@gsnFrame = False              
  res22@vpXF = 0
  res22@vpHeightF = 0.4               
  res22@vpWidthF = 0.9
  res22@tmXTOn = False
  res22@tmYROn = False
  res22@gsnMaximize = True
  res22@xyMonoLineColor = False 
  res22@trXMinF = 0.3            
  res22@trXMaxF = 7.7
  res22@tmXBMode = "Explicit"
  res22@tmXBValues = ispan(1, 7, 1)
  res22@tmXBLabels = (/"China","NE","NC","NW","EC","CC","SC"/)
  res22@txFontHeightF = 0.012
  res22@gsnLeftStringOrthogonalPosF = 0.04
  res22@gsnRightStringOrthogonalPosF = 0.04
  res22@gsnLeftStringFontHeightF = 0.01
  res22@gsnRightStringFontHeightF = 0.01
  res22@tmYLLabelFontHeightF = 0.013
  res22@tmXBLabelFontHeightF = 0.018
  res22@tmXTOn = False
  res22@tmYROn = False

  res22@gsnYRefLine = 0.
  res22@tmXBMajorOutwardLengthF = 0.01
  res22@tmYLMajorOutwardLengthF = 0.01
  res22@tmXBMajorLengthF = 0.01
  res22@tmYLMajorLengthF = 0.01
  res22@tmYLMinorOn = False
  res22@tmXBMinorLengthF = 0.005
  res22@tmYLMinorLengthF = 0.005
  res22@gsnXYBarChart = True
  res22@gsnXYBarChartBarWidth = 0.145
  res22@xyLineThicknessF = 0.1
  res22@xyLineColor = "black"
  res22@tmBorderThicknessF = 1.
  res22@tmXBMajorThicknessF = 1.
  res22@tmYLMajorThicknessF = 1.

  time0 = fspan(0.85, 6.85, 7)
  time1 = fspan(1.0, 7.0, 7)
  time2 = fspan(1.15, 7.15, 7)

  res22@tmXBLabelFont = 25
  res22@tmYLLabelFont = res22@tmXBLabelFont
  res22@tmYLMode = "Explicit"
  res22@tmYLValues = ispan(-25, 150, 25)
  res22@tmYLLabels = tostring(res22@tmYLValues)

  color = (/"forestgreen","dodgerblue3","red3"/)

  res22_text = True
  res22_text@txFontHeightF = 0.025
  res22@trYMinF = -25.              
  res22@trYMaxF = 150

  res22@gsnXYBarChartColors = color(0)
  plot1 = gsn_csm_xy(wks, time0, cwrf_region(0,0,:), res22)

  res22@gsnXYBarChartColors = color(1)
  plot11 = gsn_csm_xy(wks, time1, cwrf_region(1,0,:), res22)

  res22@gsnXYBarChartColors = color(2)
  plot12 = gsn_csm_xy(wks, time2, cwrf_region(2,0,:), res22)

  overlay(plot1, plot11)
  overlay(plot1, plot12)

  plotl0 = new(7, graphic)
  plotl1 = new(7, graphic)
  plotl2 = new(7, graphic)
  plotl00 = new(7, graphic)
  plotl01 = new(7, graphic)
  plotl02 = new(7, graphic)
  plotl10 = new(7, graphic)
  plotl11 = new(7, graphic)
  plotl12 = new(7, graphic)

  res22l = True
  res22l@gsLineThicknessF = 2.0

  do j = 0, dimsizes(subregion)-1
    plotl0(j) = gsn_add_polyline(wks, plot12, (/time0(j),time0(j)/), (/cwrf_region(0,1,j),cwrf_region(0,2,j)/), res22l)
    plotl1(j) = gsn_add_polyline(wks, plot12, (/time1(j),time1(j)/), (/cwrf_region(1,1,j),cwrf_region(1,2,j)/), res22l)
    plotl2(j) = gsn_add_polyline(wks, plot12, (/time2(j),time2(j)/), (/cwrf_region(2,1,j),cwrf_region(2,2,j)/), res22l)

    xa = 0.028
    plotl00(j) = gsn_add_polyline(wks, plot12, (/time0(j)-xa,time0(j)+xa/), (/cwrf_region(0,2,j),cwrf_region(0,2,j)/), res22l)
    plotl01(j) = gsn_add_polyline(wks, plot12, (/time1(j)-xa,time1(j)+xa/), (/cwrf_region(1,2,j),cwrf_region(1,2,j)/), res22l)
    plotl02(j) = gsn_add_polyline(wks, plot12, (/time2(j)-xa,time2(j)+xa/), (/cwrf_region(2,2,j),cwrf_region(2,2,j)/), res22l)

    plotl10(j) = gsn_add_polyline(wks, plot12, (/time0(j)-xa,time0(j)+xa/), (/cwrf_region(0,1,j),cwrf_region(0,1,j)/), res22l)
    plotl11(j) = gsn_add_polyline(wks, plot12, (/time1(j)-xa,time1(j)+xa/), (/cwrf_region(1,1,j),cwrf_region(1,1,j)/), res22l)
    plotl12(j) = gsn_add_polyline(wks, plot12, (/time2(j)-xa,time2(j)+xa/), (/cwrf_region(2,1,j),cwrf_region(2,1,j)/), res22l)
  end do

  lbres = True                 
  lbres@gsFillColor = color(0)
  lbres@gsLineColor = color(0)
  xd = 1.4
  xa_l = 0.3
  
  b20 = gsn_add_polygon(wks, plot12, (/3.6,4.2,4.2,3.6,3.6/)-xa_l, (/-18,-18,-10,-10,-18/), lbres)

  lbres@gsFillColor = color(1)
  lbres@gsLineColor = color(1)
  b21 = gsn_add_polygon(wks, plot12, (/3.6,4.2,4.2,3.6,3.6/)+xd-xa_l, (/-18,-18,-10,-10,-18/), lbres)

  lbres@gsFillColor = color(2)
  lbres@gsLineColor = color(2)
  b22 = gsn_add_polygon(wks, plot12, (/3.6,4.2,4.2,3.6,3.6/)+xd*2-xa_l, (/-18,-18,-10,-10,-18/), lbres)

  res2_text = True
  res2_text@txJust = "CenterLeft"
  res2_text@txFont = 25
  res2_text@txFontHeightF = 0.012

  b200 = gsn_add_text(wks, plot12, "SSP1-2.6", 4.2-xa_l+0.1, -14, res2_text)
  b210 = gsn_add_text(wks, plot12, "SSP2-4.5", 4.2-xa_l+0.1+xd, -14, res2_text)
  b220 = gsn_add_text(wks, plot12, "SSP5-8.5", 4.2-xa_l+0.1+xd*2, -14, res2_text)
  b223 = gsn_add_text(wks, plot12, "units: mm/yr", 0.6, -14, res2_text)

  res2_text@txFontHeightF = 0.018
  plot_titleb = gsn_add_text(wks, plot12, "Future precipitation changes", 0.4, 175*0.93-25, res2_text)

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
  resdP@gsnPanelTop = 0.97
  resdP@gsnPanelBottom = 0.795
  
  gsn_panel(wks, plot0, (/3/), resdP) 

  resdP@gsnPanelLabelBar = False
  resdP@gsnPanelTop = 0.76
  resdP@gsnPanelBottom = 0.42
  
  gsn_panel(wks, plot1, (/1/), resdP) 

  res3_text = True
  res3_text@txJust = "CenterLeft"
  res3_text@txFontHeightF = 0.018
  res3_text@txFont = 26

  gsn_text_ndc(wks, "a", 0.15, 0.99, res3_text)
  gsn_text_ndc(wks, "b", 0.15, 0.77, res3_text)

  res3_text@txFont = 25
  res3_text@txFontHeightF = 0.01
  gsn_text_ndc(wks, "units: mm/yr", 0.78, 0.814, res3_text)

  frame(wks)
end