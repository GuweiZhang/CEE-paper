
begin
  subregion = (/"CN","NE","NC","NW","EC","CC","SC"/)
  

  fout = addfile("Figure3_plot_data.nc", "r")
  dh0 = fout->dh0
  dh1 = fout->dh1
  dh2 = fout->dh2
  dr0 = fout->dr0
  dr1 = fout->dr1
  dr2 = fout->dr2

  wks = gsn_open_wks("eps", "Figure3")


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
  res@tmXBValues = ispan(1,6,1)
  res@tmXBLabels = (/"2031-2035","2036-2040","2041-2045","2046-2050","2051-2055","2056-2060"/)
  res@tmXBLabelAngleF = 30
  res@tmXBLabelJust = "CenterRight"
  res@tmXBMinorOn = False

  res@txFontHeightF = 0.012
  res@tmYLLabelFontHeightF = 0.023
  res@tmXBLabelFontHeightF = 0.023
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
  res@gsnXYBarChart = False
  res@gsnXYBarChartBarWidth = 0.29

  dhmax = (/100, 4, 4, 0.8, 12, 20, 80/)
  dhmin = (/0, 0, 0, 0, 0, 0, 0/)
  drmax = (/80, 40, 20, 8, 40, 100, 200/)
  drmin = (/0, 0, 0, 0, 0, 0, 0/)

  dhvalue0 = (/0, 25, 50, 75, 100/)
  dhvalue1 = (/0, 1, 2, 3, 4/)
  dhvalue2 = (/0, 1, 2, 3, 4/)
  dhvalue3 = (/0, 0.2, 0.4, 0.6, 0.8/)
  dhvalue4 = (/0, 3, 6, 9, 12/)
  dhvalue5 = (/0, 5, 10, 15, 20/)
  dhvalue6 = (/0, 20, 40, 60, 80/)

  dhlabel0 = (/"0", "25", "50", "75", "100"/)
  dhlabel1 = (/"0", "1", "2", "3", "4"/)
  dhlabel2 = (/"0", "1", "2", "3", "4"/)
  dhlabel3 = (/"0", "0.2", "0.4", "0.6", "0.8"/)
  dhlabel4 = (/"0", "3", "6", "9", "12"/)
  dhlabel5 = (/"0", "5", "10", "15", "20"/)
  dhlabel6 = (/"0", "20", "40", "60", "80"/)

  drvalue0 = (/0, 20, 40, 60, 80/)
  drvalue1 = (/0, 10, 20, 30, 40/)
  drvalue2 = (/0, 5, 10, 15, 20/)
  drvalue3 = (/0, 2, 4, 6, 8/)
  drvalue4 = (/0, 10, 20, 30, 40/)
  drvalue5 = (/0, 25, 50, 75, 100/)
  drvalue6 = (/0, 50, 100, 150, 200/)

  drlabel0 = (/"0", "20", "40", "65", "80"/)
  drlabel1 = (/"0", "10", "20", "30", "40"/)
  drlabel2 = (/"0", "5", "10", "15", "20"/)
  drlabel3 = (/"0", "2", "4", "6", "8"/)
  drlabel4 = (/"0", "10", "20", "30", "40"/)
  drlabel5 = (/"0", "25", "50", "75", "100"/)
  drlabel6 = (/"0", "50", "100", "150", "200"/)

  plot0 = new(dimsizes(subregion)+1, graphic)
  plot1 = new(dimsizes(subregion)+1, graphic)
  time0 = fspan(0.8, 5.8, 6)
  time1 = fspan(1.0, 6.0, 6)
  time2 = fspan(1.2, 6.2, 6)
  ds = new(6, float)
  ds = 0


  do ir = 0, dimsizes(subregion)-1
    res@tmYLMode = "Explicit"
    

    res@trYMaxF = dhmax(ir)*1.0
    res@trYMinF = dhmin(ir)*1.0
    
    if (ir.eq.0) then 
      res@tmYLValues = dhvalue0*1.0 
      res@tmYLLabels = dhlabel0 
    end if
    if (ir.eq.1) then 
      res@tmYLValues = dhvalue1*1.0 
      res@tmYLLabels = dhlabel1 
    end if
    if (ir.eq.2) then 
      res@tmYLValues = dhvalue2*1.0 
      res@tmYLLabels = dhlabel2 
    end if
    if (ir.eq.3) then 
      res@tmYLValues = dhvalue3*1.0 
      res@tmYLLabels = dhlabel3 
    end if
    if (ir.eq.4) then 
      res@tmYLValues = dhvalue4*1.0 
      res@tmYLLabels = dhlabel4 
    end if
    if (ir.eq.5) then 
      res@tmYLValues = dhvalue5*1.0 
      res@tmYLLabels = dhlabel5 
    end if
    if (ir.eq.6) then 
      res@tmYLValues = dhvalue6*1.0 
      res@tmYLLabels = dhlabel6 
    end if
    
    plot0(ir+1) = gsn_csm_xy(wks, time0, ds, res)


    res@trYMaxF = drmax(ir)*1.0
    res@trYMinF = drmin(ir)*1.0
    
    if (ir.eq.0) then 
      res@tmYLValues = drvalue0*1.0 
      res@tmYLLabels = drlabel0 
    end if
    if (ir.eq.1) then 
      res@tmYLValues = drvalue1*1.0 
      res@tmYLLabels = drlabel1 
    end if
    if (ir.eq.2) then 
      res@tmYLValues = drvalue2*1.0 
      res@tmYLLabels = drlabel2 
    end if
    if (ir.eq.3) then 
      res@tmYLValues = drvalue3*1.0 
      res@tmYLLabels = drlabel3 
    end if
    if (ir.eq.4) then 
      res@tmYLValues = drvalue4*1.0 
      res@tmYLLabels = drlabel4 
    end if
    if (ir.eq.5) then 
      res@tmYLValues = drvalue5*1.0 
      res@tmYLLabels = drlabel5 
    end if
    if (ir.eq.6) then 
      res@tmYLValues = drvalue6*1.0 
      res@tmYLLabels = drlabel6 
    end if
    
    plot1(ir+1) = gsn_csm_xy(wks, time0, ds, res)
  end do


  color1 = (/"forestgreen","dodgerblue3","red3"/)
  color0 = (/"forestgreen","dodgerblue3","red3"/)

  dum0 = new(dimsizes(subregion)*6, graphic)
  dum1 = new(dimsizes(subregion)*6, graphic)
  dum2 = new(dimsizes(subregion)*6, graphic)
  dum00 = new(dimsizes(subregion)*6, graphic)
  dum01 = new(dimsizes(subregion)*6, graphic)
  dum02 = new(dimsizes(subregion)*6, graphic)

  lsres = True
  lsres@gsLineThicknessF = 8.

  do ir = 0, dimsizes(subregion)-1
    do i = 0, 5
      lsres@gsLineColor = color1(0)
      dum0(ir*6+i) = gsn_add_polyline(wks, plot0(ir+1), (/time0(i),time0(i)/), (/dh1(ir,0,i),dh2(ir,0,i)/), lsres)
      lsres@gsLineColor = color1(1)
      dum1(ir*6+i) = gsn_add_polyline(wks, plot0(ir+1), (/time1(i),time1(i)/), (/dh1(ir,1,i),dh2(ir,1,i)/), lsres)
      lsres@gsLineColor = color1(2)
      dum2(ir*6+i) = gsn_add_polyline(wks, plot0(ir+1), (/time2(i),time2(i)/), (/dh1(ir,2,i),dh2(ir,2,i)/), lsres)

      lsres@gsLineColor = color0(0)
      dum00(ir*6+i) = gsn_add_polyline(wks, plot1(ir+1), (/time0(i),time0(i)/), (/dr1(ir,0,i),dr2(ir,0,i)/), lsres)
      lsres@gsLineColor = color0(1)
      dum01(ir*6+i) = gsn_add_polyline(wks, plot1(ir+1), (/time1(i),time1(i)/), (/dr1(ir,1,i),dr2(ir,1,i)/), lsres)
      lsres@gsLineColor = color0(2)
      dum02(ir*6+i) = gsn_add_polyline(wks, plot1(ir+1), (/time2(i),time2(i)/), (/dr1(ir,2,i),dr2(ir,2,i)/), lsres)
    end do
  end do

  gsres = True
  gsres@gsMarkerIndex = 16
  
  cdum0 = new(dimsizes(subregion)*6, graphic)
  cdum1 = new(dimsizes(subregion)*6, graphic)
  cdum2 = new(dimsizes(subregion)*6, graphic)
  cdum00 = new(dimsizes(subregion)*6, graphic)
  cdum01 = new(dimsizes(subregion)*6, graphic)
  cdum02 = new(dimsizes(subregion)*6, graphic)

  do ir = 0, dimsizes(subregion)-1
    do i = 0, 5
      gsres@gsMarkerColor = "black"
      gsres@gsMarkerSizeF = 0.006
      gsres@gsMarkerThicknessF = 2.0
      
      cdum0(ir*6+i) = gsn_add_polymarker(wks, plot0(ir+1), time0(i), dh0(ir,0,i), gsres)
      cdum1(ir*6+i) = gsn_add_polymarker(wks, plot0(ir+1), time1(i), dh0(ir,1,i), gsres)
      cdum2(ir*6+i) = gsn_add_polymarker(wks, plot0(ir+1), time2(i), dh0(ir,2,i), gsres)
      
      cdum00(ir*6+i) = gsn_add_polymarker(wks, plot1(ir+1), time0(i), dr0(ir,0,i), gsres)
      cdum01(ir*6+i) = gsn_add_polymarker(wks, plot1(ir+1), time1(i), dr0(ir,1,i), gsres)
      cdum02(ir*6+i) = gsn_add_polymarker(wks, plot1(ir+1), time2(i), dr0(ir,2,i), gsres)
    end do
  end do

  ccdum0 = new(dimsizes(subregion)*6, graphic)
  ccdum1 = new(dimsizes(subregion)*6, graphic)
  ccdum2 = new(dimsizes(subregion)*6, graphic)
  ccdum00 = new(dimsizes(subregion)*6, graphic)
  ccdum01 = new(dimsizes(subregion)*6, graphic)
  ccdum02 = new(dimsizes(subregion)*6, graphic)

  gsres@gsMarkerColor = "white"
  gsres@gsMarkerIndex = 16 
  gsres@gsMarkerSizeF = 0.002
  gsres@gsMarkerThicknessF = 3.0

  do ir = 0, dimsizes(subregion)-1
    do i = 0, 5
      ccdum0(ir*6+i) = gsn_add_polymarker(wks, plot0(ir+1), time0(i), dh0(ir,0,i), gsres)
      ccdum1(ir*6+i) = gsn_add_polymarker(wks, plot0(ir+1), time1(i), dh0(ir,1,i), gsres)
      ccdum2(ir*6+i) = gsn_add_polymarker(wks, plot0(ir+1), time2(i), dh0(ir,2,i), gsres)
      
      ccdum00(ir*6+i) = gsn_add_polymarker(wks, plot1(ir+1), time0(i), dr0(ir,0,i), gsres)
      ccdum01(ir*6+i) = gsn_add_polymarker(wks, plot1(ir+1), time1(i), dr0(ir,1,i), gsres)
      ccdum02(ir*6+i) = gsn_add_polymarker(wks, plot1(ir+1), time2(i), dr0(ir,2,i), gsres)
    end do
  end do


  tes = True
  tes@txFontHeightF = 0.04
  tes@txFont = 26.
  tes@txJust = "CenterLeft"
  subregion_labels = (/"China","NE","NC","NW","EC","CC","SC"/)
  
  text0 = new(dimsizes(subregion_labels), graphic)
  text1 = new(dimsizes(subregion_labels), graphic)

  do ir = 0, dimsizes(subregion_labels)-1
    ya = dhmax(ir)*0.95
    text0(ir) = gsn_add_text(wks, plot0(ir+1), subregion_labels(ir), 0.5, ya, tes)
    ya = drmax(ir)*0.95
    text1(ir) = gsn_add_text(wks, plot1(ir+1), subregion_labels(ir), 0.5, ya, tes)
  end do


  resdP = True
  resdP@gsnFrame = False                
  resdP@gsnPanelRowSpec = True   
  resdP@gsnPanelCenter = False
  resdP@gsnPanelLabelBar = False
  resdP@gsnPanelXWhiteSpacePercent = 5
  resdP@gsnPanelYWhiteSpacePercent = 5
  resdP@gsnPanelMainString = ""
  resdP@amJust = "TopLeft"  
  resdP@gsnMaximize = True  
  resdP@gsnPanelFigureStringsPerimOn = False

  resdP@gsnPanelLeft = 0.0
  resdP@gsnPanelRight = 0.47
  gsn_panel(wks, plot0, (/2,2,2,2/), resdP) 

  resdP@gsnPanelLeft = 0.52
  resdP@gsnPanelRight = 0.99
  gsn_panel(wks, plot1, (/2,2,2,2/), resdP) 


  les = True
  les@gsLineColor = "black"
  les@gsLineThicknessF = 2.0
  gsn_polyline_ndc(wks, (/0.01,0.49,0.49,0.01,0.01/), (/0.12,0.12,0.89,0.89,0.12/), les)
  gsn_polyline_ndc(wks, (/0.53,0.99,0.99,0.53,0.53/), (/0.12,0.12,0.89,0.89,0.12/), les)

  xd = 0.05
  les@gsLineThicknessF = 6.0
  les@gsLineColor = color1(0)
  gsn_polyline_ndc(wks, (/0.05,0.1/)+xd, (/0.83,0.83/)-0.015, les)
  les@gsLineColor = color1(1)
  gsn_polyline_ndc(wks, (/0.05,0.1/)+xd, (/0.81,0.81/)-0.015, les)
  les@gsLineColor = color1(2)
  gsn_polyline_ndc(wks, (/0.05,0.1/)+xd, (/0.79,0.79/)-0.015, les)

  les@gsLineColor = color0(0)
  gsn_polyline_ndc(wks, (/0.57,0.62/)+xd, (/0.83,0.83/)-0.015, les)
  les@gsLineColor = color0(1)
  gsn_polyline_ndc(wks, (/0.57,0.62/)+xd, (/0.81,0.81/)-0.015, les)
  les@gsLineColor = color0(2)
  gsn_polyline_ndc(wks, (/0.57,0.62/)+xd, (/0.79,0.79/)-0.015, les)

  res_text = True
  res_text@txJust = "CenterLeft"
  res_text@txFontHeightF = 0.02
  res_text@txFont = 26
  gsn_text_ndc(wks, "a ", 0.02, 0.863, res_text)
  gsn_text_ndc(wks, "b ", 0.54, 0.863, res_text)

  res_text@txFontHeightF = 0.014
  res_text@txFont = 25
  gsn_text_ndc(wks, "Attributable Mortality", 0.00+xd, 0.845, res_text)
  gsn_text_ndc(wks, "Mortality Rate", 0.55+xd, 0.845, res_text)

  res_text@txFontHeightF = 0.01
  gsn_text_ndc(wks, "10~S~3~N~ per year", 0.05+xd, 0.76-0.015, res_text)
  gsn_text_ndc(wks, "per 10~S~6~N", 0.57+xd, 0.76-0.015, res_text)

  gsn_text_ndc(wks, "SSP1-2.6", 0.11+xd, 0.83-0.015, res_text)
  gsn_text_ndc(wks, "SSP2-4.5", 0.11+xd, 0.81-0.015, res_text)
  gsn_text_ndc(wks, "SSP5-8.5", 0.11+xd, 0.79-0.015, res_text)

  gsn_text_ndc(wks, "SSP1-2.6", 0.63+xd, 0.83-0.015, res_text)
  gsn_text_ndc(wks, "SSP2-4.5", 0.63+xd, 0.81-0.015, res_text)
  gsn_text_ndc(wks, "SSP5-8.5", 0.63+xd, 0.79-0.015, res_text)

  frame(wks)
end