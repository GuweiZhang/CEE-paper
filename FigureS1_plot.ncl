
begin
  f = addfile("FigureS1_plot_data.nc", "r")
  obs = f->obs
  bias_cmip = f->bias_cmip
  bias_cwrf = f->bias_cwrf
  bias_cmipa = f->bias_cmipa
  bias_cwrfa = f->bias_cwrfa
  pcc = f->pcc
  bias = f->abias

  wks_type = "eps"
  wks = gsn_open_wks(wks_type, "FigureS1")

  plot = new(9, graphic)
  
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

  res@tmYLLabelFontHeightF = 0.02
  res@tmXBLabelFontHeightF = 0.02

  res@cnLineLabelsOn = False
  res@cnFillPalette = "precip2_17lev"
  res@cnLevelSelectionMode = "ExplicitLevels"
  res@cnLevels = ispan(200, 2000, 200)

  res@gsnLeftString = ""
  res@gsnRightString = ""

  res@tmBorderThicknessF = 1.0
  res@tmXBMajorThicknessF = res@tmBorderThicknessF
  res@tmYLMajorThicknessF = res@tmXBMajorThicknessF

  res@tmXBLabelFont = 25
  res@tmYLLabelFont = 25

  plot(0) = gsn_csm_contour_map_ce(wks, obs, res)
  plot(1) = gsn_csm_contour_map_ce(wks, bias_cmipa, res)
  plot(2) = gsn_csm_contour_map_ce(wks, bias_cwrfa, res)

  do j = 0, 2
    plot(j+3) = gsn_csm_contour_map_ce(wks, bias_cmip(j,:,:), res)
    plot(j+6) = gsn_csm_contour_map_ce(wks, bias_cwrf(j,:,:), res) 
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

  nhplot(0) = gsn_csm_contour_map_ce(wks, obs, nhres)
  nhplot(1) = gsn_csm_contour_map_ce(wks, bias_cmipa, nhres)
  nhplot(2) = gsn_csm_contour_map_ce(wks, bias_cwrfa, nhres)

  do j = 0, 2
    nhplot(j+3) = gsn_csm_contour_map_ce(wks, bias_cmip(j,:,:), nhres)
    nhplot(j+6) = gsn_csm_contour_map_ce(wks, bias_cwrf(j,:,:), nhres) 
  end do

  adres = True
  adres@amParallelPosF = 0.5 
  adres@amOrthogonalPosF = 0.5  
  adres@amJust = "BottomRight"
  
  do i = 0, 8
    plotnh(i) = gsn_add_annotation(plot(i), nhplot(i), adres)
  end do

  title = (/"(a1) OBS","(a2) CMIP6","(a3) CWRF", \
             "(b1) MPI-ESM1-HR","(b2) CESM2","(b3) IPSL-CM6A-LR", \
             "(c1) CWRF_MPI","(c2) CWRF_CESM","(c3) CWRF_IPSL"/)
  plot_text = new(9, graphic)

  res_text = True
  res_text@txJust = "CenterLeft"
  res_text@txFontHeightF = 0.025
  res_text@txFont = 26

  do i = 0, 8
    plot_text(i) = gsn_add_text(wks, plot(i), title(i), 73.5, 53, res_text)
  end do

  tes = True
  tes@txFontHeightF = 0.02
  tes@txJust = "CenterLeft"
  tes@txFont = 25
  index0 = new(8, graphic)
  index1 = new(8, graphic)
  
  do j = 0, 7
    index0(j) = gsn_add_text(wks, plot(j+1), "PCC: " + tostring_with_format(pcc(j), "%3.2f"), 74, 22, tes)
    index1(j) = gsn_add_text(wks, plot(j+1), "ABIAS: " + tostring_with_format(bias(j), "%3.2f mm/yr"), 74, 18, tes)
  end do
  
  opts1 = True
  opts1@gsnPanelLabelBar = True        
  opts1@gsnFrame = False       
  opts1@gsnPanelFigureStringsFontHeightF = 0.01
  opts1@pmLabelBarWidthF = 0.7
  opts1@pmLabelBarHeightF = 0.06
  opts1@lbLabelFont = 25
  opts1@lbLabelFontHeightF = 0.01
  opts1@lbBoxLineThicknessF = 0.5
  opts1@lbBoxSeparatorLinesOn = False
  opts1@amJust = "TopLeft"
  opts1@gsnPanelYWhiteSpacePercent = 4
  opts1@gsnPanelFigureStringsPerimOn = False
  opts1@gsnPanelRowSpec = True

  gsn_panel(wks, plot, (/3,3,3/), opts1)

  res_text@txFont = 25
  res_text@txFontHeightF = 0.012
  gsn_text_ndc(wks, "units: mm/yr", 0.87, 0.18, res_text)

  frame(wks)
end