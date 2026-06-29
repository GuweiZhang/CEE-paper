load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

begin
  f1 = addfile("FigureS11_plot_data_part1.nc", "r")
  f2 = addfile("FigureS11_plot_data_part2.nc", "r")
  
  obs = f1->obs_plot
  cmipa = f1->cmipa_plot
  cwrfa = f1->cwrfa_plot
  pcc = f1->pcc
  abias = f1->abias
  bin_centers = f1->bin_centers
  plot_data = f1->plot_data
  plot_data_hist = f1->plot_data_hist
  
  cwrf_pattern = f2->cwrf_pattern
  tt = f2->tt

  eps = 1e-12
  wks = gsn_open_wks("eps", "FigureS11")
  
  plota = new(3, graphic)
  plotb = new(2, graphic)
  plotc = new(3, graphic)

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
  res@mpProvincialLineColor = "Gray50"
  res@mpGeophysicalLineColor = "black"
  res@mpNationalLineThicknessF = 2.
  res@mpProvincialLineThicknessF = 1.0
  res@mpGeophysicalLineThicknessF = 1.0

  res@cnFillOn = True
  res@cnFillDrawOrder = "PreDraw"
  res@cnLinesOn = False              
  res@lbLabelBarOn = False
  res@lbLabelAutoStride = True
  res@pmTickMarkDisplayMode = "Always"
  res@lbOrientation = "Horizontal"
  res@pmLabelBarHeightF = 0.1
  res@pmLabelBarWidthF = 0.6
  res@pmLabelBarOrthogonalPosF = 0.15
  res@lbLabelFont = 25
  res@lbBoxSeparatorLinesOn = False
  res@tmXTOn = False
  res@tmYROn = False
  res@tmYLLabelFontHeightF = 0.02
  res@tmXBLabelFontHeightF = 0.02
  res@cnLineLabelsOn = False
  res@gsnLeftString = ""
  res@gsnRightString = ""
  res@tmBorderThicknessF = 1.5
  res@tmXBMajorThicknessF = res@tmBorderThicknessF
  res@tmYLMajorThicknessF = res@tmXBMajorThicknessF
  res@tmXBLabelFont = 25
  res@tmYLLabelFont = 25

  res@cnFillPalette = "precip2_17lev"
  res@cnLevelSelectionMode = "ExplicitLevels"
  res@cnLevels = fspan(0, 20, 11)

  plota(0) = gsn_csm_contour_map_ce(wks, obs, res)
  plota(1) = gsn_csm_contour_map_ce(wks, cmipa, res)
  plota(2) = gsn_csm_contour_map_ce(wks, cwrfa, res)

  tes = True
  tes@txFontHeightF = 0.022
  tes@txJust = "CenterLeft"
  tes@txFont = 25

  a1 = gsn_add_text(wks, plota(1), "PCC: " + tostring_with_format(pcc(0), "%3.2f"), 74, 23, tes)
  a0 = gsn_add_text(wks, plota(1), "ABIAS: " + tostring_with_format(abias(0), "%3.2f d/yr"), 74, 18, tes)
  b1 = gsn_add_text(wks, plota(2), "PCC: " + tostring_with_format(pcc(1), "%3.2f"), 74, 23, tes)
  b0 = gsn_add_text(wks, plota(2), "ABIAS: " + tostring_with_format(abias(1), "%3.2f d/yr"), 74, 18, tes)

  nhres = True
  nhres = res
  nhres@gsnMaximize = False
  nhres@gsnFrame = False
  nhres@gsnDraw = False  
  nhres@gsnAddCyclic = False    
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
  nhres@mpNationalLineThicknessF = 1.0
  nhres@mpProvincialLineThicknessF = 0.5
  nhres@mpGeophysicalLineThicknessF = 0.5
  nhres@tmBorderThicknessF = 1.0
  nhres@tmXBMajorThicknessF = res@tmBorderThicknessF
  nhres@tmYLMajorThicknessF = res@tmXBMajorThicknessF
  
  delete(nhres@cnLevels)
  nhres@cnLevelSelectionMode = "ExplicitLevels"

  nhplot = new(6, graphic)
  plotnh = new(6, graphic)
  nhplot(0) = gsn_csm_contour_map_ce(wks, obs, nhres)
  nhplot(1) = gsn_csm_contour_map_ce(wks, cmipa, nhres)
  nhplot(2) = gsn_csm_contour_map_ce(wks, cwrfa, nhres)

  adres = True
  adres@amParallelPosF = 0.5 
  adres@amOrthogonalPosF = 0.5  
  adres@amJust = "BottomRight"
  
  do i = 0, 2
    plotnh(i) = gsn_add_annotation(plota(i), nhplot(i), adres)
  end do

  title = (/"OBS","NEX-GDDP-CMIP6","CWRF"/)
  plot_text = new(6, graphic)
  res_text = True
  res_text@txJust = "CenterLeft"
  res_text@txFontHeightF = 0.025
  res_text@txFont = 25
  
  do i = 0, 2
    plot_text(i) = gsn_add_text(wks, plota(i), title(i), 73.5, 53, res_text)
  end do

  resb = True
  resb@gsnDraw = False
  resb@gsnFrame = False
  resb@trYLog = True            
  resb@trXMinF = 25.0            
  resb@trXMaxF = 300.0
  resb@trYMinF = 1e-8            
  resb@trYMaxF = 1e-1
  resb@tmXTOn = False          
  resb@tmYROn = False    
  resb@tmYLMinorOn = False
  resb@tiYAxisFont = 25
  resb@tiXAxisFont = 25    
  resb@tmYLLabelFont = 25
  resb@tmXBLabelFont = 25    
  resb@tiXAxisString = "Precipitation Intensity (mm/d)"
  
  resb_nasa = resb

  col_idx = 1
  y_upper = plot_data_hist(:,col_idx) + plot_data_hist(:,col_idx+1)
  y_lower = plot_data_hist(:,col_idx) - plot_data_hist(:,col_idx+1)
  y_lower = where(y_lower .le. 0, eps, y_lower)

  y_upper_F = plot_data(:,col_idx) + plot_data(:,col_idx+1)
  y_lower_F = plot_data(:,col_idx) - plot_data(:,col_idx+1)
  y_lower_F = where(y_lower_F .le. 0, eps, y_lower_F)

  resb@tiYAxisString = "Probability Density Function (PDF)"
  resb@gsnXYFillColors = "gray70"
  resb@xyLineColor = -1
  plotb(0) = gsn_csm_xy(wks, bin_centers, (/y_upper, y_lower/), resb)
  
  resb@gsnXYFillColors = "pink"
  resb@tiYAxisString = ""
  plotb(1) = gsn_csm_xy(wks, bin_centers, (/y_upper_F, y_lower_F/), resb)

  resb_nasa@gsnXYFillColors = "pink"
  resb_nasa@xyLineColor = -1
  y_upper_n = plot_data_hist(:,col_idx+4) + plot_data_hist(:,col_idx+5)
  y_lower_n = plot_data_hist(:,col_idx+4) - plot_data_hist(:,col_idx+5)
  y_lower_n = where(y_lower_n .le. 0, eps, y_lower_n)
  hist_cwrf = gsn_csm_xy(wks, bin_centers, (/y_upper_n, y_lower_n/), resb_nasa)

  resb_nasa@gsnXYFillColors = "lightblue"
  resb_nasa@xyLineColor = -1
  y_upper_n = plot_data_hist(:,col_idx+6) + plot_data_hist(:,col_idx+7)
  y_lower_n = plot_data_hist(:,col_idx+6) - plot_data_hist(:,col_idx+7)
  y_lower_n = where(y_lower_n .le. 0, eps, y_lower_n)
  hist_nasa = gsn_csm_xy(wks, bin_centers, (/y_upper_n, y_lower_n/), resb_nasa)

  resb_nasa@gsnXYFillColors = "darkseagreen1"
  resb_nasa@xyLineColor = -1
  y_upper_n = plot_data_hist(:,col_idx+2) + plot_data_hist(:,col_idx+3)
  y_lower_n = plot_data_hist(:,col_idx+2) - plot_data_hist(:,col_idx+3)
  y_lower_n = where(y_lower_n .le. 0, eps, y_lower_n)
  hist_cmip = gsn_csm_xy(wks, bin_centers, (/y_upper_n, y_lower_n/), resb_nasa)

  resb_nasa@gsnXYFillColors = "lightblue"
  resb_nasa@xyLineColor = -1
  y_upper_F = plot_data(:,col_idx+2) + plot_data(:,col_idx+3)
  y_lower_F = plot_data(:,col_idx+2) - plot_data(:,col_idx+3)
  y_lower_F = where(y_lower_F .le. 0, eps, y_lower_F)
  ssp_nasa = gsn_csm_xy(wks, bin_centers, (/y_upper_F, y_lower_F/), resb_nasa)

  resb_nasa@gsnXYFillColors = "darkseagreen1"
  resb_nasa@xyLineColor = -1
  y_upper_F = plot_data(:,col_idx+4) + plot_data(:,col_idx+5)
  y_lower_F = plot_data(:,col_idx+4) - plot_data(:,col_idx+5)
  y_lower_F = where(y_lower_F .le. 0, eps, y_lower_F)
  ssp_cmip = gsn_csm_xy(wks, bin_centers, (/y_upper_F, y_lower_F/), resb_nasa)

  resb_l = True
  resb_l@gsnDraw = False
  resb_l@gsnFrame = False
  resb_l@xyLineThicknesses = (/2.0,2.0,2.0,2.0/)        
  resb_l@xyLineColors = (/"black","red3","blue3","forestgreen"/)
  resb_l@xyDashPatterns = 0.

  hist_line = (/plot_data_hist(:,col_idx),plot_data_hist(:,col_idx+4),plot_data_hist(:,col_idx+6),plot_data_hist(:,col_idx+2)/)
  c1_0 = gsn_csm_xy(wks, bin_centers, hist_line, resb_l)
  delete(resb_l@xyLineThicknesses)
  delete(resb_l@xyLineColors)
  resb_l@xyLineThicknesses = (/2.0,2.0,2.0/)
  resb_l@xyLineColors = (/"red3","blue3","forestgreen"/)
  ssp_line = (/plot_data(:,col_idx),plot_data(:,col_idx+2),plot_data(:,col_idx+4)/)
  c1_1 = gsn_csm_xy(wks, bin_centers, ssp_line, resb_l)

  overlay(plotb(0), hist_cwrf)
  overlay(plotb(0), hist_nasa)  
  overlay(plotb(0), hist_cmip)      
  overlay(plotb(1), ssp_nasa)
  overlay(plotb(1), ssp_cmip)
  overlay(plotb(0), c1_0)
  overlay(plotb(1), c1_1)

  titleb = (/"Historical","SSP5-8.5"/)
  plot_titleb = new(2, graphic)
  resb_text = True
  resb_text@txJust = "CenterLeft"
  resb_text@txFontHeightF = 0.03
  resb_text@txFont = 25

  do i = 0, 1
    plot_titleb(i) = gsn_add_text(wks, plotb(i), titleb(i), 35, (1e-1)-(1e-2)*6, resb_text)
  end do

  resbl = True
  resbl@gsLineThicknessF = 2.0
  resbl@gsLineColor = "black"
  lb0 = gsn_add_polyline(wks, plotb(0), (/130,180/), (/1e-2-1e-3*5,1e-2-1e-3*5/), resbl)
  resbl@gsLineColor = "red3"
  lb1 = gsn_add_polyline(wks, plotb(0), (/130,180/), (/1e-3-1e-4*5,1e-3-1e-4*5/), resbl)
  resbl@gsLineColor = "forestgreen"
  lb2 = gsn_add_polyline(wks, plotb(0), (/130,180/), (/1e-4-1e-5*5,1e-4-1e-5*5/), resbl)
  resbl@gsLineColor = "blue3"
  lb3 = gsn_add_polyline(wks, plotb(0), (/130,180/), (/1e-5-1e-6*5,1e-5-1e-6*5/), resbl)

  resb_text@txFontHeightF = 0.018
  tb0 = gsn_add_text(wks, plotb(0), "OBS", 185, 1e-2-1e-3*5, resb_text)
  tb1 = gsn_add_text(wks, plotb(0), "CWRF", 185, 1e-3-1e-4*5, resb_text)
  tb2 = gsn_add_text(wks, plotb(0), "CMIP6", 185, 1e-4-1e-5*5, resb_text)
  tb3 = gsn_add_text(wks, plotb(0), "NEX-GDDP-CMIP6", 185, 1e-5-1e-6*5, resb_text)

  resc = True 
  resc@gsnFrame = False
  resc@gsnDraw = False  
  resc@gsnAddCyclic = False
  resc@mpMinLatF = 15.
  resc@mpMaxLatF = 56.
  resc@mpMinLonF = 72.
  resc@mpMaxLonF = 136.
  resc@gsnMajorLatSpacing = 10. 
  resc@gsnMajorLonSpacing = 20. 
  resc@tmXBMinorOn = False
  resc@tmYLMinorOn = False
  resc@mpFillOn = True
  resc@mpDataSetName = "Earth..4"
  resc@mpDataBaseVersion = "MediumRes"
  resc@mpAreaMaskingOn = True
  resc@mpMaskAreaSpecifiers = (/"China"/)
  resc@mpOutlineSpecifiers = (/"China","China:Provinces"/)
  resc@mpLandFillColor = "white"
  resc@mpInlandWaterFillColor = "white"
  resc@mpOceanFillColor = "white"
  resc@mpFillBoundarySets = "NoBoundaries"
  resc@mpOutlineBoundarySets = "NoBoundaries"
  resc@mpNationalLineColor = "black"
  resc@mpProvincialLineColor = "Gray"
  resc@mpGeophysicalLineColor = "black"
  resc@mpNationalLineThicknessF = 1.
  resc@mpProvincialLineThicknessF = 0.5
  resc@mpGeophysicalLineThicknessF = 0.5
  resc@tmYLLabelFontHeightF = 0.025
  resc@tmXBLabelFontHeightF = 0.025
  resc@pmLabelBarOrthogonalPosF = 0.1
  resc@tmBorderThicknessF = 1.0
  resc@tmXBMajorThicknessF = resc@tmBorderThicknessF
  resc@tmYLMajorThicknessF = resc@tmBorderThicknessF
  resc@cnLevelSelectionMode = "ExplicitLevels"
  resc@lbLabelBarOn = False
  resc@lbBoxSeparatorLinesOn = False
  resc@cnFillOn = True
  resc@cnFillDrawOrder = "PreDraw"
  resc@cnLinesOn = False    
  resc@cnLineLabelsOn = False          
  resc@lbLabelAutoStride = True
  resc@pmTickMarkDisplayMode = "Always"
  resc@tmXTOn = False
  resc@tmYROn = False
  resc@tmXBLabelFont = 25
  resc@tmYLLabelFont = 25
  resc@cnFillPalette = "hotcold_18lev"
  resc@cnLevels = (/-5,-3,-2,-1,-0.5,-0.1,0,0.1,0.5,1,2,3,5/)

  resc2 = True 
  resc2@gsnFrame = False
  resc2@gsnDraw = False 
  resc2@gsnAddCyclic = False
  resc2@cnFillDrawOrder = "PostDraw"
  resc2@cnFillOn = True
  resc2@cnMonoFillPattern = False   
  resc2@cnMonoFillColor = True   
  resc2@cnLineLabelsOn = False  
  resc2@cnInfoLabelOn = False   
  resc2@cnLinesOn = False  
  resc2@cnLevelSelectionMode = "ExplicitLevels"
  resc2@cnLevels = (/0.9/)
  resc2@cnFillPatterns = (/-1,17/)
  resc2@lbPerimOn = False   
  resc2@cnFillScaleF = 0.6
  resc2@cnFillDotSizeF = 0.002

  plotc = new(3, graphic)
  do i = 0, 2
    plotc(i) = gsn_csm_contour_map_overlay(wks, cwrf_pattern(i,:,:), tt(i,:,:), resc, resc2)
  end do

  nhresc = True
  nhresc = resc
  nhresc@gsnMaximize = False
  nhresc@gsnFrame = False
  nhresc@gsnDraw = False  
  nhresc@gsnAddCyclic = False    
  nhresc@vpHeightF = 0.13    
  nhresc@vpWidthF = 0.13   
  nhresc@mpMinLatF = 2.0    
  nhresc@mpMaxLatF = 23.0
  nhresc@mpMinLonF = 105.0
  nhresc@mpMaxLonF = 123.0
  nhresc@lbLabelBarOn = False
  nhresc@tmXBOn = False 
  nhresc@tmYLOn = False
  nhresc@tmYROn = False
  nhresc@tmXTOn = False
  nhresc@mpNationalLineThicknessF = 0.5
  nhresc@mpProvincialLineThicknessF = 0.25
  nhresc@mpGeophysicalLineThicknessF = 0.25
  nhresc@tmBorderThicknessF = 0.75
  nhresc@tmXBMajorThicknessF = resc@tmBorderThicknessF
  nhresc@tmYLMajorThicknessF = resc@tmXBMajorThicknessF

  nhplotc = new(3, graphic)
  plotnhc = new(3, graphic)

  do j = 0, 2
    nhplotc(j) = gsn_csm_contour_map_overlay(wks, cwrf_pattern(j,:,:), tt(j,:,:), nhresc, resc2)
  end do

  adresc = True
  adresc@amParallelPosF = 0.5 
  adresc@amOrthogonalPosF = 0.5  
  adresc@amJust = "BottomRight"

  do i = 0, 2
    plotnhc(i) = gsn_add_annotation(plotc(i), nhplotc(i), adresc)
  end do

  title_c = (/"SSP1-2.6","SSP2-4.5","SSP5-8.5"/)
  plot_titlec = new(3, graphic)
  resc_text = True
  resc_text@txJust = "CenterLeft"
  resc_text@txFontHeightF = 0.03
  resc_text@txFont = 25

  do i = 0, 2
    plot_titlec(i) = gsn_add_text(wks, plotc(i), title_c(i), 73.5, 53, resc_text)
  end do

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

  resdP@gsnPanelLeft = 0.05
  resdP@gsnPanelRight = 0.95

  resdP@gsnPanelLabelBar = False
  resdP@gsnPanelTop = 0.65
  resdP@gsnPanelBottom = 0.35
  gsn_panel(wks, plotb, (/2/), resdP) 

  resdP@gsnPanelLabelBar = True
  resdP@pmLabelBarWidthF = 0.7
  resdP@pmLabelBarHeightF = 0.04
  resdP@lbLabelFontHeightF = 0.008

  resdP@gsnPanelTop = 0.97
  resdP@gsnPanelBottom = 0.62
  gsn_panel(wks, plota, (/3/), resdP) 

  resdP@gsnPanelTop = 0.38
  resdP@gsnPanelBottom = 0.03
  gsn_panel(wks, plotc, (/3/), resdP) 

  res3_text = True
  res3_text@txJust = "CenterLeft"
  res3_text@txFont = 25
  res3_text@txFontHeightF = 0.008
  gsn_text_ndc(wks, "units: mm/yr", 0.86, 0.71, res3_text)
  gsn_text_ndc(wks, "units: d/yr", 0.86, 0.12, res3_text)

  res3_text@txJust = "CenterLeft"
  res3_text@txFontHeightF = 0.018
  res3_text@txFont = 26

  gsn_text_ndc(wks, "a", 0.05, 0.93, res3_text)
  gsn_text_ndc(wks, "b", 0.05, 0.65, res3_text)
  gsn_text_ndc(wks, "c", 0.05, 0.33, res3_text)

  frame(wks)
end