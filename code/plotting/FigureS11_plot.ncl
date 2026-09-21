load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
begin
  fout = addfile("FigureS11_plot_data.nc", "r")
  urban_share = fout->urban_share
  urban_rate_ratio = fout->urban_rate_ratio

  subregion = (/"CN","NE","NC","NW","EC","CC","SC"/)

  wks = gsn_open_wks("eps", "FigureS11")

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
  res@gsnYRefLineThicknessF = 1.0
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
  res@tmBorderThicknessF = res@gsnYRefLineThicknessF
  res@tmXBMajorThicknessF = res@gsnYRefLineThicknessF
  res@tmYLMajorThicknessF = res@gsnYRefLineThicknessF
  res@tmGridDrawOrder = "PreDraw"
  res@tiYAxisFontHeightF = 0.015

  plot0 = new(dimsizes(subregion)+1, graphic)
  plot1 = new(dimsizes(subregion)+1, graphic)

  color1 = (/"darkseagreen2","lightskyblue2","pink"/)
  color0 = (/"darkseagreen2","lightskyblue2","pink"/)

  time0 = fspan(0.8, 5.8, 6)
  time1 = fspan(1.0, 6.0, 6)
  time2 = fspan(1.2, 6.2, 6)

  share_values = (/50.,60.,70.,80.,90.,100./)
  share_labels = tostring(toint(share_values))+"%"
  ratio_values = (/98.,100.,102.,104.,106.,108./)
  ratio_labels = tostring(toint(ratio_values))+"%"

  ds0 = new(6,float)
  ds1 = new(6,float)
  ds0 = 0.
  ds1 = 100.

  do ir = 0, dimsizes(subregion)-1
    res@tmYLMode = "Explicit"

    res@trYMinF = 50.
    res@trYMaxF = 100.
    res@tmYLValues = share_values
    res@tmYLLabels = share_labels
    res@gsnYRefLine = 0.
    plot0(ir+1) = gsn_csm_xy(wks, time0, ds0, res)

    delete(res@tmYLValues)
    delete(res@tmYLLabels)

    res@trYMinF = 98.
    res@trYMaxF = 108.
    res@tmYLValues = ratio_values
    res@tmYLLabels = ratio_labels
    res@gsnYRefLine = 100.
    plot1(ir+1) = gsn_csm_xy(wks, time0, ds1, res)

    delete(res@tmYLValues)
    delete(res@tmYLLabels)
  end do

  nbars = dimsizes(subregion)*6
  barw = 0.14

  bar0 = new(nbars, graphic)
  bar1 = new(nbars, graphic)
  bar2 = new(nbars, graphic)
  bar00 = new(nbars, graphic)
  bar01 = new(nbars, graphic)
  bar02 = new(nbars, graphic)

  fillres = True
  fillres@gsEdgesOn = False

  do ir = 0, dimsizes(subregion)-1
    do i = 0, 5
      k = ir*6+i

      xc = time0(i)
      xpoly = (/xc-barw/2.,xc+barw/2.,xc+barw/2.,xc-barw/2./)
      ypoly = (/0.,0.,urban_share(ir,0,i),urban_share(ir,0,i)/)
      fillres@gsFillColor = color1(0)
      bar0(k) = gsn_add_polygon(wks, plot0(ir+1), xpoly, ypoly, fillres)

      xc = time1(i)
      xpoly = (/xc-barw/2.,xc+barw/2.,xc+barw/2.,xc-barw/2./)
      ypoly = (/0.,0.,urban_share(ir,1,i),urban_share(ir,1,i)/)
      fillres@gsFillColor = color1(1)
      bar1(k) = gsn_add_polygon(wks, plot0(ir+1), xpoly, ypoly, fillres)

      xc = time2(i)
      xpoly = (/xc-barw/2.,xc+barw/2.,xc+barw/2.,xc-barw/2./)
      ypoly = (/0.,0.,urban_share(ir,2,i),urban_share(ir,2,i)/)
      fillres@gsFillColor = color1(2)
      bar2(k) = gsn_add_polygon(wks, plot0(ir+1), xpoly, ypoly, fillres)

      xc = time0(i)
      xpoly = (/xc-barw/2.,xc+barw/2.,xc+barw/2.,xc-barw/2./)
      ypoly = (/100.,100.,urban_rate_ratio(ir,0,i),urban_rate_ratio(ir,0,i)/)
      fillres@gsFillColor = color0(0)
      bar00(k) = gsn_add_polygon(wks, plot1(ir+1), xpoly, ypoly, fillres)

      xc = time1(i)
      xpoly = (/xc-barw/2.,xc+barw/2.,xc+barw/2.,xc-barw/2./)
      ypoly = (/100.,100.,urban_rate_ratio(ir,1,i),urban_rate_ratio(ir,1,i)/)
      fillres@gsFillColor = color0(1)
      bar01(k) = gsn_add_polygon(wks, plot1(ir+1), xpoly, ypoly, fillres)

      xc = time2(i)
      xpoly = (/xc-barw/2.,xc+barw/2.,xc+barw/2.,xc-barw/2./)
      ypoly = (/100.,100.,urban_rate_ratio(ir,2,i),urban_rate_ratio(ir,2,i)/)
      fillres@gsFillColor = color0(2)
      bar02(k) = gsn_add_polygon(wks, plot1(ir+1), xpoly, ypoly, fillres)
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
    text0(ir) = gsn_add_text(wks, plot0(ir+1), subregion_labels(ir), 0.5, 98., tes)
    text1(ir) = gsn_add_text(wks, plot1(ir+1), subregion_labels(ir), 0.5, 107.4, tes)
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

  res_text@txFontHeightF = 0.012
  res_text@txFont = 25
  gsn_text_ndc(wks, "Urban Mortality Share", 0.05, 0.86, res_text)
  gsn_text_ndc(wks, "Urban-to-Total Rate Ratio", 0.57, 0.86, res_text)

res_text@txFontHeightF = 0.01
  gsn_text_ndc(wks, "SSP1-2.6", 0.11+xd, 0.83-0.015, res_text)
  gsn_text_ndc(wks, "SSP2-4.5", 0.11+xd, 0.81-0.015, res_text)
  gsn_text_ndc(wks, "SSP5-8.5", 0.11+xd, 0.79-0.015, res_text)

  gsn_text_ndc(wks, "SSP1-2.6", 0.63+xd, 0.83-0.015, res_text)
  gsn_text_ndc(wks, "SSP2-4.5", 0.63+xd, 0.81-0.015, res_text)
  gsn_text_ndc(wks, "SSP5-8.5", 0.63+xd, 0.79-0.015, res_text)

  frame(wks)
end
