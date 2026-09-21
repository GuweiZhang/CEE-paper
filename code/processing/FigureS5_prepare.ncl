load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
begin

  fpop = addfile("total_pop-new.nc", "r")
  fupop = addfile("urban_pop-new.nc", "r")

  pop = fpop->pop
  upop = fupop->pop

  popa = dim_avg_n_Wrap(dim_avg_n_Wrap(pop(:,0:4,:,:), 0), 0)
  upopa = dim_avg_n_Wrap(dim_avg_n_Wrap(upop(:,0:4,:,:), 0), 0)

  pops = popa / 1000000.
  upops = upopa / 1000000.

  popa = where(popa.eq.0, popa@_FillValue, popa)
  prop = upopa / popa * 100.
  prop = where(popa.eq.0, prop@_FillValue, prop)

  copy_VarCoords(pop(0,0,:,:), pops)
  copy_VarCoords(pop(0,0,:,:), upops)
  copy_VarCoords(pop(0,0,:,:), prop)

  out_filename = "FigureS5_plot_data.nc"
  if (isfilepresent(out_filename)) then
    print("Output already exists: " + out_filename)
    exit
  end if
  fout = addfile(out_filename, "c")

  fout->pops = pops
  fout->upops = upops
  fout->prop = prop

  print("Success! Data for Figure S5 saved to: " + out_filename)
end
