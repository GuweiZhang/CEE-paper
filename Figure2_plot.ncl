load "cnmap/cnmap.ncl"
begin


  f = addfile("Figure2_plot_data.nc", "r")
  death = f->death_plot
  mortality = f->mortality_plot
  c_ratio0 = f->c_ratio0_plot
  c_ratio1 = f->c_ratio1_plot

  region = (/"Heilongjiang","Jilin","Liaoning",\
             "Beijing Shi","Tianjin Shi","Hebei","Shanxi","Nei Mongol",\
             "Ningxia Huizu","Shaanxi","Gansu","Qinghai","Xinjiang Uygur",\
             "Shandong","Jiangsu","Shanghai Shi","Zhejiang","Anhui","Jiangxi","Fujian",\
             "Henan","Hubei","Hunan",\
             "Chongqing Shi","Sichuan","Yunnan","Guizhou","Xizang",\
             "Guangxi","Guandong","Hainan","Hong kong","Taiwan"/)
  subregion = (/"CN","NE","NC","NW","EC","CC","SC"/)

  states = "China :" + region

  levels0 = (/0,10,25,50,100,200,500,1000,2000,5000,10000/)
  labels0 = tostring_with_format(levels0, "%3d")

  levels1 = (/0,1,2,5,10,20,30,50,75,100,150/)
  labels1 = tostring_with_format(levels1, "%2d")

  wks = gsn_open_wks("eps", "Figure2")
  gsn_define_colormap(wks, "WhiteYellowOrangeRed")           
  
  cmap = gsn_retrieve_colormap(wks)   
  colors0 = (/0, 20, 45, 70, 95, 120, 145, 170, 195, 220, 245, 1/)
  
  statecolors_ssp0 = new((/3, dimsizes(region)/), integer)
  statecolors_ssp1 = new((/3, dimsizes(region)/), integer)

  do i = 0, 2
    do n = 0, dimsizes(region)-1
      if (.not.ismissing(death(i,n))) then
        statecolors_ssp0(i,n) = GetFillColorIndex(levels0, colors0, death(i,n))
        statecolors_ssp1(i,n) = GetFillColorIndex(levels1, colors0, mortality(i,n))
      else
        statecolors_ssp0(i,n) = 0
        statecolors_ssp1(i,n) = 0
      end if
    end do
  end do

  plot0 = new(4, graphic)
  plot1 = new(4, graphic)


  res = True
  res@gsnFrame = False
  res@gsnDraw = False              
  res@mpDataSetName = "Earth..4"
  res@mpDataBaseVersion = "MediumRes" 

  res@gsnMajorLatSpacing = 10. 
  res@gsnMajorLonSpacing = 20. 
  res@tmXBMinorOn = False
  res@tmYLMinorOn = False

  res@mpFillOn = True                
  res@mpPerimOn = False               
  res@mpGridAndLimbOn = False               
  res@mpAreaMaskingOn = True
  res@mpMaskAreaSpecifiers = (/"China"/)

  res@mpOutlineOn = True                
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
  res@gsnMaximize = True   

  res@tmBorderThicknessF = 1.0
  res@tmXBMajorThicknessF = res@tmBorderThicknessF
  res@tmYLMajorThicknessF = res@tmBorderThicknessF

  res@mpMinLatF = 15.
  res@mpMaxLatF = 56.
  res@mpMinLonF = 72.
  res@mpMaxLonF = 136.

  res@mpFillAreaSpecifiers = states              
  res@tmYLMode = "Explicit"
  res@tmYLValues = (/20,30,40,50/)
  res@tmYLLabels = (/"20 ~S~o~N~N","30 ~S~o~N~N","40 ~S~o~N~N","50 ~S~o~N~N"/)

  res@tmXBMode = "Explicit"
  res@tmXBValues = (/75,90,105,120,135/)
  res@tmXBLabels = (/"75 ~S~o~N~E","90 ~S~o~N~E","105 ~S~o~N~E","120 ~S~o~N~E","135 ~S~o~N~E"/)

  res@tmYLLabelFontHeightF = 0.025
  res@tmXBLabelFontHeightF = 0.025
  res@tmXBLabelFont = 25
  res@tmYLLabelFont = 25
  res@tmXTOn = False
  res@tmYROn = False

  do is = 0, 2
    res@mpSpecifiedFillColors = statecolors_ssp0(is,:)
    plot0(is) = gsn_csm_map(wks, res) 
    res@mpSpecifiedFillColors = statecolors_ssp1(is,:)
    plot1(is) = gsn_csm_map(wks, res) 
  end do


  nhres = True
  nhres = res
  nhres@gsnMaximize = False
  nhres@gsnFrame = False
  nhres@gsnDraw = False
  nhres@vpHeightF = 0.17    
  nhres@vpWidthF = 0.17
  nhres@mpMinLatF = 2.0    
  nhres@mpMaxLatF = 23.0
  nhres@mpMinLonF = 105.0
  nhres@mpMaxLonF = 123.0
  nhres@mpNationalLineThicknessF = 0.25
  nhres@mpProvincialLineThicknessF = 0.1
  nhres@mpGeophysicalLineThicknessF = 0.25

  nhres@lbLabelBarOn = False
  nhres@tmXBOn = False 
  nhres@tmYLOn = False
  nhres@tmYROn = False
  nhres@tmXTOn = False
  nhres@gsnLeftString = ""
  nhres@gsnRightString = ""

  adres = True
  adres@amParallelPosF = 0.5 
  adres@amOrthogonalPosF = 0.5  
  adres@amJust = "BottomRight"
  
  nanhai0 = new(16, graphic)
  nanhai1 = new(16, graphic)
  plotnh0 = new(3, graphic)
  plotnh1 = new(3, graphic)

  do is = 0, 2 
    nhres@mpSpecifiedFillColors = statecolors_ssp0(is,:)
    nanhai0(is) = gsn_csm_map(wks, nhres)
    plotnh0(is) = gsn_add_annotation(plot0(is), nanhai0(is), adres)

    nhres@mpSpecifiedFillColors = statecolors_ssp1(is,:)
    nanhai1(is) = gsn_csm_map(wks, nhres)
    plotnh1(is) = gsn_add_annotation(plot1(is), nanhai1(is), adres)
  end do

  title0 = (/"SSP1-2.6","SSP2-4.5","SSP5-8.5"/)
  title1 = (/"SSP1-2.6","SSP2-4.5","SSP5-8.5"/)
  plot_title0 = new(dimsizes(title0), graphic)
  plot_title1 = new(dimsizes(title0), graphic)

  res_text = True
  res_text@txJust = "CenterLeft"
  res_text@txFontHeightF = 0.025
  res_text@txFont = 25

  do i = 0, dimsizes(title0)-1
    plot_title0(i) = gsn_add_text(wks, plot0(i), title0(i), 73.5, 53, res_text)
    plot_title1(i) = gsn_add_text(wks, plot1(i), title1(i), 73.5, 53, res_text)
  end do


  resl = True              
  resl@gsnDraw = False           
  resl@gsnFrame = False             
  resl@vpXF = 0
  resl@vpHeightF = 0.5              
  resl@vpWidthF = 0.8
  resl@tmXTOn = False
  resl@tmYROn = False
  resl@gsnMaximize = True
  resl@xyMonoLineColor = False 
  resl@trXMinF = 0.3           
  resl@trXMaxF = 7.7
  resl@tmXBMode = "Explicit"
  resl@tmXBValues = ispan(1, 7, 1)
  resl@tmXBLabels = (/"China","NE","NC","NW","EC","CC","SC"/)
  
  resl@txFontHeightF = 0.012
  resl@gsnLeftStringOrthogonalPosF = 0.04
  resl@gsnRightStringOrthogonalPosF = 0.04
  resl@gsnLeftStringFontHeightF = 0.01
  resl@gsnRightStringFontHeightF = 0.01
  resl@tmYLLabelFontHeightF = 0.025
  resl@tmXBLabelFontHeightF = resl@tmYLLabelFontHeightF
  
  resl@gsnYRefLine = 0.
  resl@tmXBMajorOutwardLengthF = 0.01
  resl@tmYLMajorOutwardLengthF = 0.01
  resl@tmXBMajorLengthF = 0.01
  resl@tmYLMajorLengthF = 0.01
  resl@tmYLMinorOn = False
  resl@tmXBMinorLengthF = 0.005
  resl@tmYLMinorLengthF = 0.005

  resl@gsnXYBarChart = True
  resl@gsnXYBarChartBarWidth = 0.27
  resl@xyLineThicknessF = 0.01
  resl@xyLineColor = "white"
  resl@tmBorderThicknessF = 1.
  resl@tmXBMajorThicknessF = 1.
  resl@tmYLMajorThicknessF = 1.

  time0 = fspan(0.73, 6.73, 7)
  time1 = fspan(1.0, 7.0, 7)
  time2 = fspan(1.27, 7.27, 7)

  resl@tmXBLabelFont = 25
  resl@tmYLLabelFont = resl@tmXBLabelFont
  resl@tmYLMode = "Explicit"
  resl@tmYLValues = ispan(60, 180, 40)
  resl@tmYLLabels = tostring(resl@tmYLValues-100)+" %"

  color = (/"forestgreen","dodgerblue3","red3"/)

  resl@trYMinF = 60.             
  resl@trYMaxF = 180.

  resl@gsnXYBarChartColors = color(0)
  plot0(3) = gsn_csm_xy(wks, time0, c_ratio0(0,0,:), resl)
  plot1(3) = gsn_csm_xy(wks, time0, c_ratio1(0,0,:), resl)

  resl@gsnXYBarChartColors = color(1)
  plotl01 = gsn_csm_xy(wks, time1, c_ratio0(1,0,:), resl)
  plotl11 = gsn_csm_xy(wks, time1, c_ratio1(1,0,:), resl)

  resl@gsnXYBarChartColors = color(2)
  plotl02 = gsn_csm_xy(wks, time2, c_ratio0(2,0,:), resl)
  plotl12 = gsn_csm_xy(wks, time2, c_ratio1(2,0,:), resl)

  overlay(plot0(3), plotl01)
  overlay(plot0(3), plotl02)
  overlay(plot1(3), plotl11)
  overlay(plot1(3), plotl12)

  ressl = True
  ressl@gsLineThicknessF = 1.0

  lplotl0 = new(7*2, graphic)
  lplotl1 = new(7*2, graphic)
  lplotl2 = new(7*2, graphic)
  lplotl00 = new(7*2, graphic)
  lplotl01 = new(7*2, graphic)
  lplotl02 = new(7*2, graphic)
  lplotl10 = new(7*2, graphic)
  lplotl11 = new(7*2, graphic)
  lplotl12 = new(7*2, graphic)

  xa = 0.03
  do j = 0, dimsizes(subregion)-1
    lplotl0(j) = gsn_add_polyline(wks, plotl02, (/time0(j),time0(j)/), (/c_ratio0(0,1,j),c_ratio0(0,2,j)/), ressl)
    lplotl1(j) = gsn_add_polyline(wks, plotl02, (/time1(j),time1(j)/), (/c_ratio0(1,1,j),c_ratio0(1,2,j)/), ressl)
    lplotl2(j) = gsn_add_polyline(wks, plotl02, (/time2(j),time2(j)/), (/c_ratio0(2,1,j),c_ratio0(2,2,j)/), ressl)

    lplotl0(j+7) = gsn_add_polyline(wks, plotl12, (/time0(j),time0(j)/), (/c_ratio1(0,1,j),c_ratio1(0,2,j)/), ressl)
    lplotl1(j+7) = gsn_add_polyline(wks, plotl12, (/time1(j),time1(j)/), (/c_ratio1(1,1,j),c_ratio1(1,2,j)/), ressl)
    lplotl2(j+7) = gsn_add_polyline(wks, plotl12, (/time2(j),time2(j)/), (/c_ratio1(2,1,j),c_ratio1(2,2,j)/), ressl)

    lplotl00(j) = gsn_add_polyline(wks, plotl02, (/time0(j)-xa,time0(j)+xa/), (/c_ratio0(0,2,j),c_ratio0(0,2,j)/), ressl)
    lplotl01(j) = gsn_add_polyline(wks, plotl02, (/time1(j)-xa,time1(j)+xa/), (/c_ratio0(1,2,j),c_ratio0(1,2,j)/), ressl)
    lplotl02(j) = gsn_add_polyline(wks, plotl02, (/time2(j)-xa,time2(j)+xa/), (/c_ratio0(2,2,j),c_ratio0(2,2,j)/), ressl)

    lplotl10(j) = gsn_add_polyline(wks, plotl02, (/time0(j)-xa,time0(j)+xa/), (/c_ratio0(0,1,j),c_ratio0(0,1,j)/), ressl)
    lplotl11(j) = gsn_add_polyline(wks, plotl02, (/time1(j)-xa,time1(j)+xa/), (/c_ratio0(1,1,j),c_ratio0(1,1,j)/), ressl)
    lplotl12(j) = gsn_add_polyline(wks, plotl02, (/time2(j)-xa,time2(j)+xa/), (/c_ratio0(2,1,j),c_ratio0(2,1,j)/), ressl)

    lplotl00(j+7) = gsn_add_polyline(wks, plotl12, (/time0(j)-xa,time0(j)+xa/), (/c_ratio1(0,2,j),c_ratio1(0,2,j)/), ressl)
    lplotl01(j+7) = gsn_add_polyline(wks, plotl12, (/time1(j)-xa,time1(j)+xa/), (/c_ratio1(1,2,j),c_ratio1(1,2,j)/), ressl)
    lplotl02(j+7) = gsn_add_polyline(wks, plotl12, (/time2(j)-xa,time2(j)+xa/), (/c_ratio1(2,2,j),c_ratio1(2,2,j)/), ressl)

    lplotl10(j+7) = gsn_add_polyline(wks, plotl12, (/time0(j)-xa,time0(j)+xa/), (/c_ratio1(0,1,j),c_ratio1(0,1,j)/), ressl)
    lplotl11(j+7) = gsn_add_polyline(wks, plotl12, (/time1(j)-xa,time1(j)+xa/), (/c_ratio1(1,1,j),c_ratio1(1,1,j)/), ressl)
    lplotl12(j+7) = gsn_add_polyline(wks, plotl12, (/time2(j)-xa,time2(j)+xa/), (/c_ratio1(2,1,j),c_ratio1(2,1,j)/), ressl)
  end do

  res_text@txJust = "CenterLeft"
  res_text@txFontHeightF = 0.025
  res_text@txFont = 25
  plot_title00 = gsn_add_text(wks, plot0(3), "Relative Change", 0.45, 173, res_text)
  plot_title11 = gsn_add_text(wks, plot1(3), "Relative Change", 0.45, 173, res_text)


  resdP = True  
  resdP@gsnFrame = False                
  resdP@gsnPanelRowSpec = True
  resdP@gsnPanelCenter = False
  resdP@gsnPanelYWhiteSpacePercent = 4
  resdP@gsnPanelFigureStringsPerimOn = False
  resdP@amJust = "TopLeft"  
  resdP@gsnMaximize = True  
  resdP@gsnPanelFigureStringsFontHeightF = 0.0115

  resdP@gsnPanelLeft = 0.0
  resdP@gsnPanelRight = 0.76
  resdP@gsnPanelTop = 0.95
  resdP@gsnPanelBottom = 0.51
  gsn_panel(wks, plot0, (/2,2/), resdP) 

  resdP@gsnPanelLeft = 0.0
  resdP@gsnPanelRight = 0.76
  resdP@gsnPanelTop = 0.44
  resdP@gsnPanelBottom = 0.00
  gsn_panel(wks, plot1, (/2,2/), resdP) 


  lbres = True          
  lbres@vpWidthF = 0.06           
  lbres@vpHeightF = 0.14           
  lbres@lbBoxMajorExtentF = 0.08          
  lbres@lbMonoFillPattern = True          
  lbres@lbLabelFont = 25
  lbres@lbLabelFontHeightF = 0.008         
  lbres@lbLabelJust = "CenterLeft"  
  lbres@lbPerimOn = False
  lbres@lgPerimColor = "white"
  lbres@lbBoxLineColor = "black"
  lbres@lbBoxLineThicknessF = 0.5

  yaa = 0.99
  xa = 0.72
  yd = 0.05
  do i = 0, 2
    lbres@lbFillColors = colors0(3*i+1)     
    labels = labels0(3*i) + "-" + labels0(3*i+1)    
    gsn_labelbar_ndc(wks, 1, labels, xa, yaa-yd*i, lbres) 

    lbres@lbFillColors = colors0(3*i+2)     
    labels = labels0(3*i+1) + "-" + labels0(3*i+2)     
    gsn_labelbar_ndc(wks, 1, labels, xa+0.09, yaa-yd*i, lbres) 

    lbres@lbFillColors = colors0(3*i+3)     
    labels = labels0(3*i+2) + "-" + labels0(3*i+3)     
    gsn_labelbar_ndc(wks, 1, labels, xa+0.09*2, yaa-yd*i, lbres) 
  end do

  i = 3
  lbres@lbFillColors = colors0(3*i+1)     
  labels = labels0(3*i) + "-" + labels0(3*i+1)     
  gsn_labelbar_ndc(wks, 1, labels, xa, yaa-yd*i, lbres) 

  lbres@lbFillColors = colors0(3*i+2)     
  labels = labels0(3*i+1) + "+"     
  gsn_labelbar_ndc(wks, 1, labels, xa+0.09, yaa-yd*i, lbres) 

  yaa = 0.49
  xa = 0.725
  yd = 0.05
  do i = 0, 2
    lbres@lbFillColors = colors0(3*i+1)     
    labels = labels1(3*i) + "-" + labels1(3*i+1)    
    gsn_labelbar_ndc(wks, 1, labels, xa, yaa-yd*i, lbres) 

    lbres@lbFillColors = colors0(3*i+2)     
    labels = labels1(3*i+1) + "-" + labels1(3*i+2)     
    gsn_labelbar_ndc(wks, 1, labels, xa+0.09, yaa-yd*i, lbres) 

    lbres@lbFillColors = colors0(3*i+3)     
    labels = labels1(3*i+2) + "-" + labels1(3*i+3)     
    gsn_labelbar_ndc(wks, 1, labels, xa+0.09*2, yaa-yd*i, lbres) 
  end do

  i = 3
  lbres@lbFillColors = colors0(3*i+1)     
  labels = tostring(levels1(3*i)) + "-" + tostring(levels1(3*i+1))     
  gsn_labelbar_ndc(wks, 1, labels, xa, yaa-yd*i, lbres) 

  lbres@lbFillColors = colors0(3*i+2)     
  labels = tostring(levels1(3*i+1)) + "+"     
  gsn_labelbar_ndc(wks, 1, labels, xa+0.09, yaa-yd*i, lbres) 

  llbres = True          
  llbres@vpWidthF = 0.16           
  llbres@vpHeightF = 0.14           
  llbres@lbBoxMajorExtentF = 0.08          
  llbres@lbMonoFillPattern = True          
  llbres@lbLabelFontHeightF = 0.008         
  llbres@lbLabelJust = "CenterLeft"  
  llbres@lbPerimOn = False
  llbres@lgPerimColor = "white"

  yaa = 0.76
  ydd = 0.05
  llbres@lbFillColors = color(0)
  llbres@lbBoxLineThicknessF = 0.01
  llbres@lbBoxLineColor = "black"
  llbres@lbLabelFont = res@tmXBLabelFont

  labels = (/"SSP1-2.6"/)     
  gsn_labelbar_ndc(wks, 1, labels, 0.76, yaa, llbres) 

  llbres@lbFillColors = color(1)
  labels = (/"SSP2-4.5"/)     
  gsn_labelbar_ndc(wks, 1, labels, 0.76, yaa-ydd, llbres) 

  llbres@lbFillColors = color(2)
  labels = (/"SSP5-8.5"/)     
  gsn_labelbar_ndc(wks, 1, labels, 0.76, yaa-ydd*2, llbres)

  yaa = 0.25
  ydd = 0.05
  llbres@lbFillColors = color(0)
  llbres@lbBoxLineThicknessF = 0.01
  llbres@lbBoxLineColor = "white"
  llbres@lbLabelFont = res@tmXBLabelFont

  labels = (/"SSP1-2.6"/)     
  gsn_labelbar_ndc(wks, 1, labels, 0.76, yaa, llbres) 

  llbres@lbFillColors = color(1)
  labels = (/"SSP2-4.5"/)     
  gsn_labelbar_ndc(wks, 1, labels, 0.76, yaa-ydd, llbres) 

  llbres@lbFillColors = color(2)
  labels = (/"SSP5-8.5"/)     
  gsn_labelbar_ndc(wks, 1, labels, 0.76, yaa-ydd*2, llbres)

  les = True
  les@gsLineColor = "black"
  les@gsLineThicknessF = 2.0
  gsn_polyline_ndc(wks, (/0.02,0.985,0.985,0.02,0.02/), (/0.51,0.51,1.0,1.0,0.51/), les)
  gsn_polyline_ndc(wks, (/0.02,0.985,0.985,0.02,0.02/), (/0.0,0.0,0.49,0.49,0.0/), les)

  res_text@txFontHeightF = 0.02
  res_text@txFont = 26
  gsn_text_ndc(wks, "a", 0.03, 0.98, res_text)
  gsn_text_ndc(wks, "b", 0.03, 0.47, res_text)
  res_text@txFont = 25
  res_text@txFontHeightF = 0.015
  gsn_text_ndc(wks, "Attributable Mortality", 0.33, 0.978, res_text)
  gsn_text_ndc(wks, "Mortality Rate (per 10~S~6~N~)", 0.35, 0.468, res_text)
  
  frame(wks)
end