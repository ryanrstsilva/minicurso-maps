setwd("./maps/mg")

devtools::install_github("h-a-graham/rayvista", dependencies = TRUE)

packages <- c("rayvista", "elevatr", "rayshader", "sf", "geobr")
invisible(lapply(packages, library, character.only = TRUE))

crs <- "+proj=longlat +datum=WGS84 +no_defs"

mg_sf <- sf::st_transform(geobr::read_state(code_state = 31), crs)

map_elevation <- elevatr::get_elev_raster(locations = mg_sf, z = 7, clip = "locations")
names(map_elevation) <- "elevation"

mg_demo <- rayvista::plot_3d_vista(
  dem = map_elevation$elevation,
  overlay_detail = 11,
  zscale = 10,
  zoom = .8,
  phi = 85,
  theta = 0,
  solid = FALSE,
  windowsize = c(800, 800)
)

rayshader::render_camera(theta = 0, phi = 60, zoom = .7)

rayshader::render_highquality(
  filename = "relief_mg.png",
  interactive = FALSE,
  light = TRUE,
  lightdirection = 225,
  lightintensity = c(600, 1200),
  lightaltitude = c(80, 20),
  lightcolor = c("#ebe293", "white"),
  width = 3000,
  height = 3000,
  parallel = TRUE,
)