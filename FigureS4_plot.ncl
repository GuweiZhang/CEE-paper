

begin
  f = addfile("FigureS4_plot_data.nc", "r")
  cwrf1 = f->cwrf1

  wks = gsn_open_wks("eps", "FigureS4")
  
  plot = new(9, graphic)
  plot_Text0 = new(9, graphic)
  plot_Text1 = new(9, graphic)
  plot_title = new(9, graphic)

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

  res@cnFillOn = True
  res@cnFillDrawOrder = "PreDraw"
  res@cnLinesOn = False              
  res@lbLabelBarOn = False
  res@lbLabelAutoStride = True
  res@pmTickMarkDisplayMode = "Always"

  res@cnLevelSelectionMode = "ExplicitLevels" 
  res@lbBoxSeparatorLinesOn = False
  res@cnFillPalette = "hotcold_18lev"
  res@cnLineLabelsOn = False          
  res@tmXTOn = False
  res@tmYROn = False

  res@cnLevels = (/-5,-3,-2,-1,-0.5,-0.1,0,0.1,0.5,1,2,3,5/)

  res@tmXBLabelFont = 25
  res@tmYLLabelFont = 25

  num1 = (/"SSP1-2.6","SSP1-2.6","SSP1-2.6", "SSP2-4.5","SSP2-4.5","SSP2-4.5", "SSP5-8.5","SSP5-8.5","SSP5-8.5"/)
  num2 = (/"CWRF_MPI","CWRF_CESM","CWRF_IPSL", "CWRF_MPI","CWRF_CESM","CWRF_IPSL", "CWRF_MPI","CWRF_CESM","CWRF_IPSL"/)

  res_text = True
  res_text@txFontHeightF = 0.025
  res_text@txFont = 25

  do i = 0, 2
    do j = 0, 2
      ia = i * 3 + j
      plot(ia) = gsn_csm_contour_map_ce(wks, cwrf1(i,j,:,:), res)
      plot_Text0(ia) = gsn_add_text(wks, plot(ia), num2(ia), 103.5, 53, res_text)
      plot_Text1(ia) = gsn_add_text(wks, plot(ia), num1(ia), 103.5, 48, res_text)
    end do
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

  nhplot = new(9, graphic)
  plotnh = new(9, graphic)

  do i = 0, 2
    do j = 0, 2
      ia = i * 3 + j
      nhplot(ia) = gsn_csm_contour_map_ce(wks, cwrf1(i,j,:,:), nhres)
    end do
  end do

  adres = True
  adres@amParallelPosF = 0.5 
  adres@amOrthogonalPosF = 0.5  
  adres@amJust = "BottomRight"
  
  do i = 0, 8
    plotnh(i) = gsn_add_annotation(plot(i), nhplot(i), adres)
  end do

  title = (/"(a1)","(a2)","(a3)", "(b1)","(b2)","(b3)", "(c1)","(c2)","(c3)"/)

  res_text@txJust = "CenterLeft"
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
  resdP@lbLabelFont = 25
  resdP@lbBoxLineThicknessF = 0.5
  resdP@lbBoxSeparatorLinesOn = False
  resdP@gsnPanelFigureStringsFontHeightF = 0.01
  resdP@pmLabelBarWidthF = 0.7
  resdP@pmLabelBarHeightF = 0.06
  resdP@lbLabelFontHeightF = 0.01

  gsn_panel(wks, plot, (/3,3,3/), resdP) 

  res_text@txFontHeightF = 0.01
  gsn_text_ndc(wks, "units: d/yr", 0.86, 0.205, res_text)

  frame(wks)
end