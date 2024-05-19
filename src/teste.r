setwd("./maps/mg")

packages <- c("rayvista", "elevatr", "rayshader", "sf", "geobr")
invisible(lapply(packages, library, character.only = TRUE))

ibituruna_lat <- -18.886329
ibituruna_long <- -41.9209847

ibituruna <- rayvista::plot_3d_vista(
  lat = ibituruna_lat,
  long = ibituruna_long,
  radius = 3600,
  zscale = 4,
  zoom = .8,
  solid = FALSE,
  elevation_detail = 13,
  overlay_detail = 15,
  theta = 0,
  windowsize = 800,
  shadowdepth = 0
)

rayshader::render_camera(theta = 270, phi = 25, zoom = .6)

rayshader::render_highquality(
  filename = "relief_ibituruna.png",
  interactive = FALSE,
  light = TRUE,
  lightdirection = 225,
  lightintensity = c(600, 1200),
  lightaltitude = c(80, 20),
  lightcolor = c("#ebe293", "white"),
  width = 2160,
  height = 2160,
  parallel = TRUE,
)