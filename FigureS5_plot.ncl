

begin
  f = addfile("FigureS5_plot_data.nc", "r")
  pops = f->pops
  upops = f->upops
  prop = f->prop

  wks = gsn_open_wks("eps", "FigureS5")
  plot = new(3, graphic)

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
  res@mpProvincialLineColor = "gray"
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
  res@pmLabelBarWidthF = 0.7
  res@cnFillOn = True
  res@cnFillDrawOrder = "PreDraw"
  res@cnLinesOn = False    
  res@cnLineLabelsOn = False          
  res@lbLabelAutoStride = True

  res@tmXTOn = False
  res@tmYROn = False
  res@lbLabelFont = 25
  res@tmXBLabelFont = 25
  res@tmYLLabelFont = 25
  res@cnFillMode = "RasterFill"

  res@cnLevels = fspan(0.1, 1., 10)
  res@cnFillPalette = "MPL_viridis"
  res@lbLabelStrings = tostring_with_format(res@cnLevels, "%2.1f")
  
  plot(0) = gsn_csm_contour_map(wks, pops, res)
  plot(1) = gsn_csm_contour_map(wks, upops, res)

  ress = res
  delete(ress@cnLevels)
  delete(ress@lbLabelStrings)
  
  ress@cnLevels = ispan(10, 90, 10)
  ress@lbLabelStrings = tostring_with_format(ress@cnLevels, "%2.2d")
  ress@cnFillPalette = "amwg256"
  
  plot(2) = gsn_csm_contour_map(wks, prop, ress)

  res_text = True
  res_text@txFontHeightF = 0.025
  res_text@txJust = "CenterLeft"
  res_text@txFont = 25

  plot_Text0 = new(6, graphic)
  plot_Text0(0) = gsn_add_text(wks, plot(0), "(a) Total population", 73.5, 53, res_text)
  plot_Text0(1) = gsn_add_text(wks, plot(1), "(b) Urban population", 73.5, 53, res_text)
  plot_Text0(2) = gsn_add_text(wks, plot(2), "(c) Urbanization", 73.5, 53, res_text)

  aa0=sum(pops)
  aa1=sum(upops)

  string0 = toint(aa0)+" million"
  string1 = toint(aa1)+" million"
  string2 = toint(aa1/aa0*100)+" %"

  plot_Text0(3) = gsn_add_text(wks, plot(0), string0, 74, 18, res_text)
  plot_Text0(4) = gsn_add_text(wks, plot(1), string1, 74, 18, res_text)
  plot_Text0(5) = gsn_add_text(wks, plot(2), string2, 74, 18, res_text)

  nhres = True
  nhres = ress
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

  nhplot(2) = gsn_csm_contour_map_ce(wks, prop, nhres)
  
  delete(nhres@cnLevels)
  if (isatt(nhres, "lbLabelStrings")) then
    delete(nhres@lbLabelStrings)
  end if
  
  nhres@cnLevels = fspan(0.1, 1., 10)
  nhres@cnFillPalette = "MPL_viridis"
  
  nhplot(0) = gsn_csm_contour_map_ce(wks, pops, nhres)
  nhplot(1) = gsn_csm_contour_map_ce(wks, upops, nhres)

  adres = True
  adres@amParallelPosF = 0.5 
  adres@amOrthogonalPosF = 0.5  
  adres@amJust = "BottomRight"
  
  do i = 0, 2
    plotnh(i) = gsn_add_annotation(plot(i), nhplot(i), adres)
  end do

  resdP = True  
  resdP@gsnFrame = False                
  resdP@gsnPanelRowSpec = True
  resdP@gsnPanelCenter = True
  resdP@gsnPanelLabelBar = True
  resdP@gsnPanelXWhiteSpacePercent = 3
  resdP@gsnPanelYWhiteSpacePercent = 2
  resdP@gsnPanelFigureStringsFontHeightF = 0.013
  resdP@gsnPanelFigureStringsPerimOn = False
  resdP@lbBoxLineThicknessF = 0.5
  resdP@lbBoxSeparatorLinesOn = False
  resdP@lbLabelFont = 25
  resdP@gsnPanelFigureStringsFontHeightF = 0.01
  resdP@pmLabelBarWidthF = 0.55
  resdP@pmLabelBarHeightF = 0.06
  resdP@lbLabelFontHeightF = 0.01
  resdP@gsnMaximize = True
  resdP@gsnPanelTop = 0.95
  resdP@gsnPanelBottom = 0.65

  gsn_panel(wks, plot(0:1), (/2/), resdP) 
  
  resdP@pmLabelBarWidthF = 0.22
  resdP@gsnPanelTop = 0.65
  resdP@gsnPanelBottom = 0.35
  gsn_panel(wks, plot(2), (/1/), resdP) 

  res_text@txFontHeightF = 0.01
  gsn_text_ndc(wks, "units: million", 0.79, 0.685, res_text)
  gsn_text_ndc(wks, "units: %", 0.63, 0.385, res_text)

  frame(wks)
end