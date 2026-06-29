

begin
  f = addfile("FigureS6_plot_data.nc", "r")
  p = f->p
  up = f->up
  pophist = f->pophist
  upophist = f->upophist

  subregion = (/"China","NE","NC","NW","EC","CC","SC"/)
  
  wks = gsn_open_wks("eps", "FigureS6")

  res = True 
  res@gsnDraw = False            
  res@gsnFrame = False           
  res@vpXF = 0
  res@vpHeightF = 0.4               
  res@vpWidthF = 0.6
  res@tmXTOn = False
  res@tmYROn = False
  res@gsnMaximize = True
  res@xyMonoLineColor = False 
  res@trXMinF = 0.4          
  res@trXMaxF = 6.6
  res@tmXBMode = "Explicit"
  res@tmXBValues = ispan(1, 6, 1)
  res@tmXBLabels = (/"2031-2035","2036-2040","2041-2045","2046-2050","2051-2055","2056-2060"/)
  res@tmXBLabelAngleF = 30
  res@tmXBLabelJust = "CenterRight"
  res@tmXBMinorOn = False
  res@txFontHeightF = 0.012
  res@tmYLLabelFontHeightF = 0.02
  res@tmXBLabelFontHeightF = 0.02
  res@tmXTBorderOn = False
  res@tmYRBorderOn = False
  res@gsnYRefLine = 0.
  res@gsnYRefLineThicknessF = 2.0
  res@tmXBMajorOutwardLengthF = 0.009
  res@tmYLMajorOutwardLengthF = 0.005
  res@tmXBMajorLengthF = 0.009
  res@tmYLMajorLengthF = 0.005
  res@tmYLMinorOn = False
  res@tmXBMinorOutwardLengthF = res@tmXBMajorOutwardLengthF
  res@tmXBMinorLengthF = 0.005
  res@tmYLMinorLengthF = 0.005
  res@tmXBLabelFont = 25
  res@tmYLLabelFont = res@tmXBLabelFont
  res@tmXMajorGrid = False
  res@tmYMajorGrid = False
  res@tmXMajorGridLineColor = "Gray"
  res@tmYMajorGridLineColor = "Gray"
  res@tmBorderThicknessF = res@gsnYRefLineThicknessF
  res@tmXBMajorThicknessF = res@gsnYRefLineThicknessF
  res@tmYLMajorThicknessF = res@gsnYRefLineThicknessF
  res@tmGridDrawOrder = "PreDraw"
  res@tiYAxisFontHeightF = 0.015
  res@tmYLPrecision = 2
  res@tmYLMaxTicks = 4

  res@gsnXYBarChart = True
  res@xyLineColor = "white"
  res@xyLineThicknessF = 0.1

  plot = new(dimsizes(subregion), graphic)
  plot0 = new(dimsizes(subregion), graphic)
  plot1 = new(dimsizes(subregion), graphic)
  plot00 = new(dimsizes(subregion), graphic)
  plot01 = new(dimsizes(subregion), graphic)
  plot02 = new(dimsizes(subregion), graphic)

  color0 = (/"forestgreen","dodgerblue3","red3"/)
  color1 = (/"darkseagreen2","lightskyblue2","pink"/)

  time0 = fspan(0.7, 5.7, 6)
  time1 = fspan(1.0, 6.0, 6)
  time2 = fspan(1.3, 6.3, 6)


  res@gsnXYBarChartBarWidth = 0.29
  do ir = 0, dimsizes(subregion)-1
    xx = (/p(0,:,ir), p(1,:,ir), p(2,:,ir)/)
    res@trYMaxF = max(xx) * 1.2
    res@trYMinF = min(xx) * 0.4

    res@gsnXYBarChartColors = color0(0)
    plot(ir) = gsn_csm_xy(wks, time0, p(0,:,ir), res)
    res@gsnXYBarChartColors = color0(1)
    plot0(ir) = gsn_csm_xy(wks, time1, p(1,:,ir), res)
    res@gsnXYBarChartColors = color0(2)
    plot1(ir) = gsn_csm_xy(wks, time2, p(2,:,ir), res)

    overlay(plot(ir), plot0(ir))
    overlay(plot(ir), plot1(ir))
  end do


  res@gsnXYBarChartBarWidth = 0.2
  do ir = 0, dimsizes(subregion)-1
    res@gsnXYBarChartColors = color1(0)
    plot00(ir) = gsn_csm_xy(wks, time0, up(0,:,ir), res)
    res@gsnXYBarChartColors = color1(1)
    plot01(ir) = gsn_csm_xy(wks, time1, up(1,:,ir), res)
    res@gsnXYBarChartColors = color1(2)
    plot02(ir) = gsn_csm_xy(wks, time2, up(2,:,ir), res)

    overlay(plot(ir), plot00(ir))
    overlay(plot(ir), plot01(ir))
    overlay(plot(ir), plot02(ir))
  end do


  tes = True
  tes@txFontHeightF = 0.04
  tes@txFont = 26.
  tes@txJust = "CenterLeft"
  text = new(dimsizes(subregion), graphic)
  
  do ir = 0, dimsizes(subregion)-1
    xx = (/p(0,:,ir), p(1,:,ir), p(2,:,ir)/)
    ya = max(xx) * 1.16
    text(ir) = gsn_add_text(wks, plot(ir), subregion(ir), 0.6, ya, tes)
  end do

  histline0 = new(dimsizes(subregion), graphic)
  histline1 = new(dimsizes(subregion), graphic)
  resl = True
  resl@gsLineDashPattern = 2.0
  resl@gsLineThicknessF = 4.0

  do ir = 0, dimsizes(subregion)-1
    resl@gsLineColor = "black"
    histline0(ir) = gsn_add_polyline(wks, plot02(ir), (/0,10/), (/pophist(ir),pophist(ir)/), resl)
    resl@gsLineColor = "purple"
    histline1(ir) = gsn_add_polyline(wks, plot02(ir), (/0,10/), (/upophist(ir),upophist(ir)/), resl)
  end do


  resdP = True
  resdP@gsnFrame = False
  resdP@gsnPanelRowSpec = True   
  resdP@gsnPanelCenter = False
  resdP@gsnPanelLabelBar = False
  resdP@gsnPanelXWhiteSpacePercent = 5
  resdP@gsnPanelMainString = ""
  resdP@amJust = "TopLeft"  
  resdP@gsnMaximize = True  
  resdP@gsnPanelFigureStringsPerimOn = False

  gsn_panel(wks, plot, (/1, 3, 3/), resdP) 


  yd = 0.055
  ya = 0.03
  xa = -0.08
  yes = True
  
  yes@gsFillColor = color0(0)
  gsn_polygon_ndc(wks, (/0.45,0.45,0.6,0.6,0.45/)+xa, (/0.83,0.86,0.86,0.83,0.83/)-ya, yes)
  yes@gsFillColor = color0(1)
  gsn_polygon_ndc(wks, (/0.45,0.45,0.6,0.6,0.45/)+xa, (/0.83,0.86,0.86,0.83,0.83/)-yd-ya, yes)
  yes@gsFillColor = color0(2)
  gsn_polygon_ndc(wks, (/0.45,0.45,0.6,0.6,0.45/)+xa, (/0.83,0.86,0.86,0.83,0.83/)-yd*2-ya, yes)

  yes@gsFillColor = color1(0)
  gsn_polygon_ndc(wks, (/0.52,0.52,0.59,0.59,0.52/)+xa, (/0.835,0.855,0.855,0.835,0.835/)-ya, yes)
  yes@gsFillColor = color1(1)
  gsn_polygon_ndc(wks, (/0.52,0.52,0.59,0.59,0.52/)+xa, (/0.835,0.855,0.855,0.835,0.835/)-yd-ya, yes)
  yes@gsFillColor = color1(2)
  gsn_polygon_ndc(wks, (/0.52,0.52,0.59,0.59,0.52/)+xa, (/0.835,0.855,0.855,0.835,0.835/)-yd*2-ya, yes)

  tex = True
  tex@txFont = 26
  tex@txFontHeightF = 0.012
  tex@txJust = "CenterLeft"
  tex@txFontColor = "White"
  
  gsn_text_ndc(wks, "Total", 0.46+xa, 0.845-ya, tex)
  gsn_text_ndc(wks, "Total", 0.46+xa, 0.845-yd-ya, tex)
  gsn_text_ndc(wks, "Total", 0.46+xa, 0.845-yd*2-ya, tex)

  tex@txFontColor = "black"
  gsn_text_ndc(wks, "Urban", 0.53+xa, 0.845-ya, tex)
  gsn_text_ndc(wks, "Urban", 0.53+xa, 0.845-yd-ya, tex)
  gsn_text_ndc(wks, "Urban", 0.53+xa, 0.845-yd*2-ya, tex)

  tex@txFont = 25
  gsn_text_ndc(wks, "SSP1-2.6", 0.61+xa, 0.845-ya, tex)
  gsn_text_ndc(wks, "SSP2-4.5", 0.61+xa, 0.845-yd-ya, tex)
  gsn_text_ndc(wks, "SSP5-8.5", 0.61+xa, 0.845-yd*2-ya, tex)

  gsn_text_ndc(wks, "units: billion", 0.75+xa, 0.845-yd*2-ya, tex)

  resl@gsLineColor = "black"
  gsn_polyline_ndc(wks, (/0.75,0.8/)+xa, (/0.845-ya,0.845-ya/), resl)
  resl@gsLineColor = "purple"
  gsn_polyline_ndc(wks, (/0.75,0.8/)+xa, (/0.845-yd-ya,0.845-yd-ya/), resl)

  gsn_text_ndc(wks, "Historical Total population", 0.81+xa, 0.845-ya, tex)
  gsn_text_ndc(wks, "Historical Urban population", 0.81+xa, 0.845-yd-ya, tex)

  frame(wks)
end