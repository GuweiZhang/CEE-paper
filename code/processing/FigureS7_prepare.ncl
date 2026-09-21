load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
begin
  ssp = (/"126","245","585"/)
  sspid = (/0, 1, 4/)

  fpop = addfile("total_pop-new.nc", "r")
  fupop = addfile("urban_pop-new.nc", "r")

  pop_all = fpop->pop
  upop_all = fupop->pop

  popa = dim_avg_n(dim_avg_n(pop_all(:,0:4,:,:), 0), 0)
  upopa = dim_avg_n(dim_avg_n(upop_all(:,0:4,:,:), 0), 0)

  nn = dimsizes(popa)
  pops = new((/dimsizes(ssp), nn(0), nn(1)/), float)
  upops = new((/dimsizes(ssp), nn(0), nn(1)/), float)

  do is = 0, dimsizes(ssp)-1
    pop_sub = fpop->pop(sspid(is), 2031-2010:2060-2010, :, :)
    upop_sub = fupop->pop(sspid(is), 2031-2010:2060-2010, :, :)
    pops(is,:,:) = dim_avg_n(pop_sub, 0) - popa
    upops(is,:,:) = dim_avg_n(upop_sub, 0) - upopa
  end do

  pops = pops / 1000000.
  upops = upops / 1000000.

  pops!0 = "ssp"
  pops!1 = pop_all!2
  pops!2 = pop_all!3
  pops&$pops!1$ = pop_all&$pop_all!2$
  pops&$pops!2$ = pop_all&$pop_all!3$

  upops!0 = "ssp"
  upops!1 = upop_all!2
  upops!2 = upop_all!3
  upops&$upops!1$ = upop_all&$upop_all!2$
  upops&$upops!2$ = upop_all&$upop_all!3$

  out_filename = "FigureS7_plot_data.nc"
  if (isfilepresent(out_filename)) then
    print("Output already exists: " + out_filename)
    exit
  end if
  f_out = addfile(out_filename, "c")

  f_out->pops = pops
  f_out->upops = upops

  print("Success! Data for Figure S7 saved to: " + out_filename)
end
