

begin
  f = addfile("FigureS7_plot_data.nc", "r")
  pops = f->pops
  upops = f->upops

  ssp = (/"126","245","585"/)

  wks = gsn_open_wks("eps", "FigureS7")
  gsn_define_colormap(wks, "MPL_PuOr")

  plot = new(6, graphic)

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
  res@pmTickMarkDisplayMode = "Always"
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
  res@tmYLLabelFontHeightF = 0.021 
  res@tmXBLabelFontHeightF = 0.021
  res@pmLabelBarOrthogonalPosF = 0.1

  res@tmBorderThicknessF = 1.0
  res@tmXBMajorThicknessF = res@tmBorderThicknessF
  res@tmYLMajorThicknessF = res@tmBorderThicknessF

  res@cnLevelSelectionMode = "ExplicitLevels"
  res@lbLabelBarOn = False
  res@lbBoxSeparatorLinesOn = False
  res@cnFillOn = True
  res@cnFillDrawOrder = "PreDraw"
  res@cnLinesOn = False    
  res@cnLineLabelsOn = False          
  res@lbLabelAutoStride = True
  res@tmXTOn = False
  res@tmYROn = False

  gsn_reverse_colormap(wks)
  res@cnLevels = fspan(-.800, .800, 17)
  res@tmXBLabelFont = 25
  res@tmYLLabelFont = 25
  res@cnFillMode = "RasterFill"

  num1 = (/"SSP1-2.6","SSP1-2.6", "SSP2-4.5","SSP2-4.5", "SSP5-8.5","SSP5-8.5"/)
  num2 = (/"Total","Urban", "Total","Urban", "Total","Urban"/)

  res_text = True
  res_text@txFontHeightF = 0.025
  res_text@txFont = 25

  plot_Text0 = new(9, graphic)
  plot_Text1 = new(9, graphic)
  plot_Text2 = new(6, graphic)
  plot_Text3 = new(6, graphic)
  plot_Text4 = new(6, graphic)

  do is = 0, dimsizes(ssp)-1
    plot(is*2) = gsn_csm_contour_map(wks, pops(is,:,:), res)
    plot(is*2+1) = gsn_csm_contour_map(wks, upops(is,:,:), res)
  end do

  do i = 0, 5
    plot_Text0(i) = gsn_add_text(wks, plot(i), num2(i), 103.5, 53, res_text)
    plot_Text1(i) = gsn_add_text(wks, plot(i), num1(i), 103.5, 48, res_text)
  end do

  res_text@txJust = "CenterLeft"
  string0 = (/"1,382 (-2.2)","1,445 (+61.3)","1,382 (-2.2)"/)
  string1 = (/"1,012 (+288.5)","1,049 (+325.3)","1,114 (+390.7)"/)
  string2 = (/"73.2 %","72.6%","80.7%"/)

  do is = 0, dimsizes(ssp)-1
    res_text@txFontColor = "black"
    plot_Text2(is) = gsn_add_text(wks, plot(is*2), string0(is), 74, 22, res_text)
    plot_Text3(is) = gsn_add_text(wks, plot(is*2+1), string1(is), 74, 22, res_text)
    res_text@txFontColor = 250
    plot_Text4(is) = gsn_add_text(wks, plot(is*2+1), "Urbanization: " + string2(is), 74, 18, res_text)
  end do

  res_text@txFontColor = "black"

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

  nhplot = new(6, graphic)
  plotnh = new(6, graphic)

  do is = 0, dimsizes(ssp)-1
    nhplot(is*2) = gsn_csm_contour_map_ce(wks, pops(is,:,:), nhres)
    nhplot(is*2+1) = gsn_csm_contour_map_ce(wks, upops(is,:,:), nhres)
  end do

  adres = True
  adres@amParallelPosF = 0.5 
  adres@amOrthogonalPosF = 0.5  
  adres@amJust = "BottomRight"
  
  do i = 0, 5
    plotnh(i) = gsn_add_annotation(plot(i), nhplot(i), adres)
  end do

  title = (/"(a1)","(a2)", "(b1)","(b2)", "(c1)","(c2)"/)
  plot_title = new(dimsizes(title), graphic)
  
  res_text = True
  res_text@txJust = "CenterLeft"
  res_text@txFontHeightF = 0.025
  res_text@txFont = 25

  do i = 0, dimsizes(title)-1
    plot_title(i) = gsn_add_text(wks, plot(i), title(i), 73.5, 53, res_text)
  end do

  resdP = True  
  resdP@gsnFrame = False                
  resdP@gsnPanelRowSpec = True
  resdP@gsnPanelCenter = False
  resdP@gsnPanelLabelBar = True
  resdP@gsnPanelXWhiteSpacePercent = 3
  resdP@gsnPanelYWhiteSpacePercent = 2
  resdP@amJust = "TopLeft"  
  resdP@gsnMaximize = True  
  resdP@gsnPanelFigureStringsFontHeightF = 0.013
  resdP@gsnPanelFigureStringsPerimOn = False
  resdP@lbBoxLineThicknessF = 0.5
  resdP@lbBoxSeparatorLinesOn = False
  resdP@lbLabelFont = 25
  resdP@gsnPanelFigureStringsFontHeightF = 0.01
  resdP@pmLabelBarWidthF = 0.7
  resdP@pmLabelBarHeightF = 0.06
  resdP@lbLabelFontHeightF = 0.012

  gsn_panel(wks, plot, (/2,2,2/), resdP) 

  res_text@txFontHeightF = 0.012
  gsn_text_ndc(wks, "units: million", 0.86, 0.065, res_text)

  frame(wks)
end