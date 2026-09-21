load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
begin
  subregion = (/"CN","NE","NC","NW","EC","CC","SC"/)
  ssp = (/"126","245","585"/)

  poph  = new((/16, dimsizes(subregion)/), float)
  upoph = new((/16, dimsizes(subregion)/), float)

  pop  = new((/3, 30, dimsizes(subregion)/), float)
  upop = new((/3, 30, dimsizes(subregion)/), float)

  do ir = 0, dimsizes(subregion)-1
    file0 = "13.Province-future-death-number-motality-yearly/13."+subregion(ir)+"-current-total_population.txt"
    file1 = "13.Province-future-death-number-motality-yearly/13."+subregion(ir)+"-current-urban_population.txt"
    poph(:,ir)  = asciiread(file0, -1, "float")
    upoph(:,ir) = asciiread(file1, -1, "float")

    do is = 0, dimsizes(ssp)-1
      f_pop  = "13.Province-future-death-number-motality-yearly/13."+subregion(ir)+"-ssp"+ssp(is)+"-total_population.txt"
      f_upop = "13.Province-future-death-number-motality-yearly/13."+subregion(ir)+"-ssp"+ssp(is)+"-urban_population.txt"
      pop(is,:,ir)  = asciiread(f_pop, -1, "float")
      upop(is,:,ir) = asciiread(f_upop, -1, "float")
    end do
  end do

  p0 = pop / 100000000.0
  p1 = upop / 100000000.0

  pophist  = dim_avg_n(poph(0:4,:), 0) / 100000000.0
  upophist = dim_avg_n(upoph(0:4,:), 0) / 100000000.0

  p  = new((/3, 6, dimsizes(subregion)/), float)
  up = new((/3, 6, dimsizes(subregion)/), float)

  do i = 0, 5
    p(:,i,:)  = dim_avg_n(p0(:, 0+i*5 : 4+i*5, :), 1)
    up(:,i,:) = dim_avg_n(p1(:, 0+i*5 : 4+i*5, :), 1)
  end do

  p!0 = "ssp"
  p!1 = "time"
  p!2 = "region"

  up!0 = "ssp"
  up!1 = "time"
  up!2 = "region"

  pophist!0 = "region"
  upophist!0 = "region"

  out_filename = "FigureS6_plot_data.nc"
  if (isfilepresent(out_filename)) then
    print("Output already exists: " + out_filename)
    exit
  end if
  f_out = addfile(out_filename, "c")

  f_out->p = p
  f_out->up = up
  f_out->pophist = pophist
  f_out->upophist = upophist

  print("Success! Data for Figure S6 saved to: " + out_filename)
end
