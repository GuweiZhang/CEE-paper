

begin


  wks = gsn_open_wks("eps","FigureS13")

subregion=(/"NE","NC","NW","EC","CC","SC"/)
RR0=(/1.147,1.211,1.021,1.021,1.295,1.254,0,1.051,1.151/)
RR1=(/0.647,0.770,0.436,0.746,0.825,0.590,0,0.834,0.958/)
RR2=(/2.034,1.906,2.389,1.396,2.034,2.665,0,1.324,1.384/)

;---------------------------------------------------------------------------------------------------------------------
res3                   = True              ; plot mods desired
  res3@gsnDraw            = False           ; don't draw yet
  res3@gsnFrame           = False             ; don't advance frame yet
  res3@vpXF=0.2
  res3@vpHeightF      = 0.35              ; rcange aspect ratio of plot
  res3@vpWidthF           = 0.7

  res3@tmXTOn=False
  res3@tmYROn=False
  res3@gsnMaximize=True

  res3@xyMonoLineColor    = False 
  res3@trXMinF            = 0.3           ; set x-axis minimum
  res3@trXMaxF            = 9.7
  res3@tmXBMode="Explicit"
  res3@tmXBValues=(/1,2,3,4,5,6,8,9/)

  res3@tmXBLabels=(/"NE","NC","NW","EC","CC","SC","CC","SC"/)

   res3@gsnLeftStringOrthogonalPosF=0.04
   res3@gsnRightStringOrthogonalPosF=0.04
   res3@gsnLeftStringFontHeightF=0.01
   res3@gsnRightStringFontHeightF=0.01
   res3@tmYLLabelFontHeightF=0.015
   res3@tmXBLabelFontHeightF=0.015

  res3@tmXTOn=False
  res3@tmYROn=False

  res3@gsnYRefLine=0.
  res3@tmXBMajorOutwardLengthF=0.01
  res3@tmYLMajorOutwardLengthF=0.01
  res3@tmXBMajorLengthF=0.01
  res3@tmYLMajorLengthF=0.01

   res3@tmYLMinorOn=False
   res3@tmXBMinorLengthF=0.005
   res3@tmYLMinorLengthF=0.005

   
 res3@gsnXYBarChart=True
 res3@gsnXYBarChartBarWidth=0.4
res3@xyLineThicknessF=1.0
res3@xyLineColor="black"
res3@gsnXYBarChartColors="gray50"



res3@gsnYRefLineColor="black"

res3@tmXBLabelFont=25
res3@tmYLLabelFont=  res3@tmXBLabelFont

res3@tmYLMode="Explicit"
YMIN=0.0
YMAX=3.0
res3@trYMaxF =YMAX
res3@trYMinF =YMIN           
res3@tmYLValues=fspan(YMIN, YMAX, 4)
res3@tmYLLabels=(tostring_with_format(res3@tmYLValues, "%3.1f"))

res3@tiYAxisString="Relative Risk (RR)"

res3@tiXAxisFont=25
res3@tiYAxisFont=25
res3@tiYAxisFontHeightF=0.015
res3@tiXAxisFontHeightF=res3@tiYAxisFontHeightF
time=ispan(1, 9, 1)

plot=new(1,graphic)
plot=gsn_csm_xy (wks,time,RR0,res3)

res3_text=True
res3_text@txFontHeightF=0.025


   plotl0=new(dimsizes(time),graphic)
   plotl1=new(dimsizes(time),graphic)
   plotl2=new(dimsizes(time),graphic)

res22l=True
res22l@gsLineThicknessF=2.5

do j=0,5
plotl0(j)=gsn_add_polyline(wks, plot, (/time(j),time(j)/), (/RR1(j),RR2(j)/), res22l)
xa=0.1
plotl1(j)=gsn_add_polyline(wks, plot, (/time(j)-xa,time(j)+xa/), (/RR2(j),RR2(j)/), res22l)
plotl2(j)=gsn_add_polyline(wks, plot, (/time(j)-xa,time(j)+xa/), (/RR1(j),RR1(j)/), res22l)
end do

do j=7,8
plotl0(j)=gsn_add_polyline(wks, plot, (/time(j),time(j)/), (/RR1(j),RR2(j)/), res22l)
xa=0.1
plotl1(j)=gsn_add_polyline(wks, plot, (/time(j)-xa,time(j)+xa/), (/RR2(j),RR2(j)/), res22l)
plotl2(j)=gsn_add_polyline(wks, plot, (/time(j)-xa,time(j)+xa/), (/RR1(j),RR1(j)/), res22l)
end do

plotll=gsn_add_polyline(wks, plot, (/7,7/), (/0,4/), res22l)
res22l@gsLineThicknessF=2.0
res22l@gsLineDashPattern=2.0
plotlll=gsn_add_polyline(wks, plot, (/0,10/), (/1,1/), res22l)

res3_text=True
res3_text@txJust="CenterLeft"
res3_text@txFontHeightF=0.018
res3_text@txFont = 25

plot_title0=new(2,graphic)
plot_title0(0)=gsn_add_text(wks, plot, "Storm rain", 0.5,  (YMAX(0)-YMIN(0))*0.93+YMIN(0), res3_text)
plot_title0(1)=gsn_add_text(wks, plot, "Heavy rain", 7.2,  (YMAX(0)-YMIN(0))*0.93+YMIN(0), res3_text)


draw(plot)
    frame(wks)

end 
