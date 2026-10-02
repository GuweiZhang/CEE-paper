load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "cnmap/cnmap.ncl"
begin

  f = addfile("Figure2_plot_data.nc", "r")
  death = f->death_plot
  mortality = f->mortality_plot
  c_ratio0 = f->c_ratio0_plot
  c_ratio1 = f->c_ratio1_plot
  c_change0 = c_ratio0 - 100.
  c_change1 = c_ratio1 - 100.

  region = (/"Heilongjiang","Jilin","Liaoning",\
             "Beijing Shi","Tianjin Shi","Hebei","Shanxi","Nei Mongol",\
             "Ningxia Huizu","Shaanxi","Gansu","Qinghai","Xinjiang Uygur",\
             "Shandong","Jiangsu","Shanghai Shi","Zhejiang","Anhui","Jiangxi","Fujian",\
             "Henan","Hubei","Hunan",\
             "Chongqing Shi","Sichuan","Yunnan","Guizhou","Xizang",\
             "Guangxi","Guandong","Hainan","Hong kong","Taiwan"/)
  subregion = (/"CN","NE","NC","NW","EC","CC","SC"/)

  states = "China :" + region

  levels0 = (/0,10,50,100,200,500,1000,1500,2500,5000,8000/)
  labels0 = tostring_with_format(levels0, "%3d")

  levels1 = (/0,1,2,5,10,20,30,50,60,70,80/)
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
  resl@gsnYRefLineColor = "black"
  resl@gsnYRefLineThicknessF = 1.2
  resl@tmXBMajorOutwardLengthF = 0.01
  resl@tmYLMajorOutwardLengthF = 0.01
  resl@tmXBMajorLengthF = 0.01
  resl@tmYLMajorLengthF = 0.01
  resl@tmYLMinorOn = False
  resl@tmXBMinorLengthF = 0.005
  resl@tmYLMinorLengthF = 0.005
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
  resl@tmYLValues = ispan(-150, 150, 50)
  resl@tmYLLabels = tostring(resl@tmYLValues)+" %"

  color = (/"forestgreen","dodgerblue3","red3"/)

  resl@trYMinF = -160.
  resl@trYMaxF = 160.

  plot0(3) = gsn_csm_xy(wks, time0, c_change0(0,0,:), resl)
  plot1(3) = gsn_csm_xy(wks, time0, c_change1(0,0,:), resl)

  ci00 = new(7, graphic)
  ci01 = new(7, graphic)
  ci02 = new(7, graphic)
  ci10 = new(7, graphic)
  ci11 = new(7, graphic)
  ci12 = new(7, graphic)

  lsres = True
  lsres@gsLineThicknessF = 6.

  do j = 0, dimsizes(subregion)-1
    lsres@gsLineColor = color(0)
    ci00(j) = gsn_add_polyline(wks, plot0(3), (/time0(j),time0(j)/), (/c_change0(0,1,j),c_change0(0,2,j)/), lsres)
    ci10(j) = gsn_add_polyline(wks, plot1(3), (/time0(j),time0(j)/), (/c_change1(0,1,j),c_change1(0,2,j)/), lsres)

    lsres@gsLineColor = color(1)
    ci01(j) = gsn_add_polyline(wks, plot0(3), (/time1(j),time1(j)/), (/c_change0(1,1,j),c_change0(1,2,j)/), lsres)
    ci11(j) = gsn_add_polyline(wks, plot1(3), (/time1(j),time1(j)/), (/c_change1(1,1,j),c_change1(1,2,j)/), lsres)

    lsres@gsLineColor = color(2)
    ci02(j) = gsn_add_polyline(wks, plot0(3), (/time2(j),time2(j)/), (/c_change0(2,1,j),c_change0(2,2,j)/), lsres)
    ci12(j) = gsn_add_polyline(wks, plot1(3), (/time2(j),time2(j)/), (/c_change1(2,1,j),c_change1(2,2,j)/), lsres)
  end do

  m00 = new(7, graphic)
  m01 = new(7, graphic)
  m02 = new(7, graphic)
  m10 = new(7, graphic)
  m11 = new(7, graphic)
  m12 = new(7, graphic)

  gsres = True
  gsres@gsMarkerIndex = 16
  gsres@gsMarkerColor = "black"
  gsres@gsMarkerSizeF = 0.008
  gsres@gsMarkerThicknessF = 2.0

  do j = 0, dimsizes(subregion)-1
    m00(j) = gsn_add_polymarker(wks, plot0(3), time0(j), c_change0(0,0,j), gsres)
    m01(j) = gsn_add_polymarker(wks, plot0(3), time1(j), c_change0(1,0,j), gsres)
    m02(j) = gsn_add_polymarker(wks, plot0(3), time2(j), c_change0(2,0,j), gsres)

    m10(j) = gsn_add_polymarker(wks, plot1(3), time0(j), c_change1(0,0,j), gsres)
    m11(j) = gsn_add_polymarker(wks, plot1(3), time1(j), c_change1(1,0,j), gsres)
    m12(j) = gsn_add_polymarker(wks, plot1(3), time2(j), c_change1(2,0,j), gsres)
  end do

  mw00 = new(7, graphic)
  mw01 = new(7, graphic)
  mw02 = new(7, graphic)
  mw10 = new(7, graphic)
  mw11 = new(7, graphic)
  mw12 = new(7, graphic)

  gsres@gsMarkerColor = "white"
  gsres@gsMarkerSizeF = 0.003
  gsres@gsMarkerThicknessF = 2.0

  do j = 0, dimsizes(subregion)-1
    mw00(j) = gsn_add_polymarker(wks, plot0(3), time0(j), c_change0(0,0,j), gsres)
    mw01(j) = gsn_add_polymarker(wks, plot0(3), time1(j), c_change0(1,0,j), gsres)
    mw02(j) = gsn_add_polymarker(wks, plot0(3), time2(j), c_change0(2,0,j), gsres)

    mw10(j) = gsn_add_polymarker(wks, plot1(3), time0(j), c_change1(0,0,j), gsres)
    mw11(j) = gsn_add_polymarker(wks, plot1(3), time1(j), c_change1(1,0,j), gsres)
    mw12(j) = gsn_add_polymarker(wks, plot1(3), time2(j), c_change1(2,0,j), gsres)
  end do

  res_text@txJust = "CenterLeft"
  res_text@txFontHeightF = 0.025
  res_text@txFont = 25
  plot_title00 = gsn_add_text(wks, plot0(3), "Relative Change", 0.45, 130, res_text)
  plot_title11 = gsn_add_text(wks, plot1(3), "Relative Change", 0.45, 130, res_text)

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

  legline = True
  legline@gsLineThicknessF = 6.0

  legtext = True
  legtext@txJust = "CenterLeft"
  legtext@txFont = res@tmXBLabelFont
  legtext@txFontHeightF = 0.010

  legline@gsLineColor = color(0)
  yd=0.07
  gsn_polyline_ndc(wks, (/0.79,0.84/), (/0.76-yd,0.76-yd/), legline)
  gsn_text_ndc(wks, "SSP1-2.6", 0.85, 0.76-yd, legtext)

  legline@gsLineColor = color(1)
  gsn_polyline_ndc(wks, (/0.79,0.84/), (/0.71-yd,0.71-yd/), legline)
  gsn_text_ndc(wks, "SSP2-4.5", 0.85, 0.71-yd, legtext)

  legline@gsLineColor = color(2)
  gsn_polyline_ndc(wks, (/0.79,0.84/), (/0.66-yd,0.66-yd/), legline)
  gsn_text_ndc(wks, "SSP5-8.5", 0.85, 0.66-yd, legtext)

  legline@gsLineColor = color(0)
  gsn_polyline_ndc(wks, (/0.79,0.84/), (/0.25-yd,0.25-yd/), legline)
  gsn_text_ndc(wks, "SSP1-2.6", 0.85, 0.25-yd, legtext)

  legline@gsLineColor = color(1)
  gsn_polyline_ndc(wks, (/0.79,0.84/), (/0.20-yd,0.20-yd/), legline)
  gsn_text_ndc(wks, "SSP2-4.5", 0.85, 0.20-yd, legtext)

  legline@gsLineColor = color(2)
  gsn_polyline_ndc(wks, (/0.79,0.84/), (/0.15-yd,0.15-yd/), legline)
  gsn_text_ndc(wks, "SSP5-8.5", 0.85, 0.15-yd, legtext)

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
