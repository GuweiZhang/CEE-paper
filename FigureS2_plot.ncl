

begin
  f = addfile("FigureS2_plot_data.nc", "r")
  plot_bias_cmip = f->plot_bias_cmip
  plot_bias_cwrf = f->plot_bias_cwrf
  pcc = f->pcc
  abias = f->abias

  wks_type = "eps"
  wks = gsn_open_wks(wks_type, "FigureS2")
  
  plot = new(6, graphic)
  
  res = True 
  res@gsnFrame = False
  res@gsnDraw = False  
  res@gsnAddCyclic = False

  res@mpFillOn = True
  res@mpDataSetName = "Earth..4"
  res@mpDataBaseVersion = "MediumRes" 
  res@mpAreaMaskingOn = True
  res@mpMinLatF = 15.
  res@mpMaxLatF = 56.
  res@mpMinLonF = 72.
  res@mpMaxLonF = 136.
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

  res@cnFillOn = True
  res@cnFillDrawOrder = "PreDraw"
  res@cnLinesOn = False              
  res@lbLabelBarOn = False
  res@lbLabelAutoStride = True
  res@pmTickMarkDisplayMode = "Always"

  res@lbOrientation = "Horizontal"
  res@pmLabelBarHeightF = 0.05
  res@pmLabelBarWidthF = 0.7
  res@pmLabelBarOrthogonalPosF = 0.12
  res@tmXTOn = False
  res@tmYROn = False

  res@tmXBLabelFont = 25
  res@tmYLLabelFont = 25
  res@tmYLLabelFontHeightF = 0.02
  res@tmXBLabelFontHeightF = 0.02

  res@cnLineLabelsOn = False
  res@cnFillPalette = "BlAqGrWh2YeOrReVi22"
  res@cnLevelSelectionMode = "ExplicitLevels"
  res@cnLevels = fspan(-1, 1, 11)

  res@gsnLeftString = ""
  res@gsnRightString = ""

  res@tmBorderThicknessF = 1.0
  res@tmXBMajorThicknessF = res@tmBorderThicknessF
  res@tmYLMajorThicknessF = res@tmXBMajorThicknessF

  do i = 0, 2
    plot(i) = gsn_csm_contour_map_ce(wks, plot_bias_cmip(i,:,:), res)
    plot(i+3) = gsn_csm_contour_map_ce(wks, plot_bias_cwrf(i,:,:), res)
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

  nhplot = new(6, graphic)
  plotnh = new(6, graphic)
  
  do i = 0, 2
    nhplot(i) = gsn_csm_contour_map_ce(wks, plot_bias_cmip(i,:,:), nhres)
    nhplot(i+3) = gsn_csm_contour_map_ce(wks, plot_bias_cwrf(i,:,:), nhres)
  end do

  adres = True
  adres@amParallelPosF = 0.5 
  adres@amOrthogonalPosF = 0.5  
  adres@amJust = "BottomRight"
  
  do i = 0, 5
    plotnh(i) = gsn_add_annotation(plot(i), nhplot(i), adres)
  end do

  plot_text = new(6, graphic)
  res_text = True
  res_text@txJust = "CenterLeft"
  res_text@txFontHeightF = 0.025
  res_text@txFont = 25

  title = (/"(a1) MPI","(a2) CESM","(a3) IPSL", "(b1) CWRF_MPI","(b2) CWRF_CESM","(b3) CWRF_IPSL"/)
  
  do i = 0, 5
    plot_text(i) = gsn_add_text(wks, plot(i), title(i), 73.5, 53, res_text)
  end do

  plot_text0 = new(6, graphic)
  plot_text1 = new(6, graphic)
  res_text@txFontHeightF = 0.02

  do i = 0, 5
    plot_text0(i) = gsn_add_text(wks, plot(i), "PCC: " + tostring_with_format(pcc(i), "%3.2f"), 74, 23, res_text)
    plot_text1(i) = gsn_add_text(wks, plot(i), "ABIAS: " + tostring_with_format(abias(i), "%3.2f d/yr"), 74, 18, res_text)
  end do

  opts1 = True
  opts1@gsnPanelLabelBar = True        
  opts1@gsnFrame = False       
  opts1@gsnPanelFigureStringsFontHeightF = 0.009
  opts1@pmLabelBarWidthF = 0.6
  opts1@pmLabelBarHeightF = 0.06
  opts1@lbLabelFont = 25
  opts1@lbLabelFontHeightF = 0.01
  opts1@lbBoxLineThicknessF = 0.5
  opts1@lbBoxSeparatorLinesOn = False
  opts1@amJust = "TopLeft"
  opts1@gsnPanelFigureStringsPerimOn = False

  gsn_panel(wks, plot, (/2,3/), opts1)

  res3_text = True
  res3_text@txJust = "CenterLeft"
  res3_text@txFont = 25
  res3_text@txFontHeightF = 0.012
gsn_text_ndc(wks, "units: d/yr", 0.82, 0.29, res3_text)


  frame(wks)
end