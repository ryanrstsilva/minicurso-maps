# Diretório de Trabalho
setwd("./maps/mg")

# Carregamento dos Pacotes
packages <- c("tidyverse", "sf", "geobr", "stars", "rayshader", "magick")
invisible(lapply(packages, library, character.only = TRUE))

# Carregamento do Dataset
data <- sf::st_read("../../data/kontur_population_BR_20231101.gpkg")

# Obtendo informações da região de interesse
map_borders <- sf::st_transform(geobr::read_state(code_state = 31), sf::st_crs(data))
map_borders |> ggplot() + geom_sf()

# Extrair do Dataset apenas os dados da região de interesse
st_map <- sf::st_intersection(data, map_borders)

# Extrair informações de Proporção do Tela
bb_map <- sf::st_bbox(st_map)

bottom_left <- sf::st_point(c(bb_map[["xmin"]], bb_map[["ymin"]])) |>
  sf::st_sfc(crs = sf::st_crs(data))

bottom_right <- sf::st_point(c(bb_map[["xmax"]], bb_map[["ymin"]])) |>
  sf::st_sfc(crs = sf::st_crs(data))

top_left <- sf::st_point(c(bb_map[["xmin"]], bb_map[["ymax"]])) |>
  sf::st_sfc(crs = sf::st_crs(data))

width <- sf::st_distance(bottom_left, bottom_right)
height <- sf::st_distance(bottom_left, top_left)

if (width > height) {
  w_ratio <- 1
  h_ratio <- height / width
} else {
  h_ratio <- 1
  w_ratio <- width / height
}

# Conversão para Raster
size <- 5000

rast_map <- stars::st_rasterize(
  st_map,
  nx = floor(size * w_ratio),
  ny = floor(size * h_ratio)
)

matrix <- matrix(
  rast_map$population,
  nrow = floor(size * w_ratio),
  ncol = floor(size * h_ratio)
)

# Paleta de Cores
cols <- rev(c("#ef5000", "#ed791b", "#eb9a3c", "#eab661"))
texture <- colorRampPalette(cols)(256)

# RAYSHADER
matrix |>
  rayshader::height_shade(texture = texture) |>
  rayshader::plot_3d(
    heightmap = matrix,
    zscale = 100 / 5,
    solid = FALSE,
    shadowdepth = 0
  )

render_camera(theta = 0, phi = 45, zoom = .7)

rayshader::render_highquality(
  filename = "population_density_mg.png",
  interactive = FALSE,
  lightdirection = 280,
  lightaltitude = c(20, 80),
  lightcolor = c(cols[1], "white"),
  lightintensity = c(500, 100),
  samples = 128,
  width = 3600,
  height = 3600
)

# ANNOTATE MAP
#--------------

map <- magick::image_read("./population_density_mg.png")

map |>
  magick::image_annotate(
    "Densidade Populacional",
    color = alpha(cols[4], .7),
    size = 125,
    gravity = "northwest",
    location = "+235+300",
    font = "Georgia"
  ) |>
  magick::image_annotate(
    "Minas Gerais",
    color = cols[4],
    size = 250,
    gravity = "northwest",
    location = "+200+400",
    font = "Georgia"
  ) |>
  magick::image_annotate(
    "©2024 Ryan R. S. Silva",
    font = "Georgia",
    color = alpha("black", .75),
    size = 40,
    gravity = "southeast",
    location = "+425+675",
  ) |>
  magick::image_annotate(
    "Data: Kontur: Population Density for 400m H3 Hexagons",
    font = "Georgia",
    color = alpha("black", .75),
    size = 40,
    gravity = "southeast",
    location = "+425+625",
  ) |>
  image_write("annotated_population_density_mg.png")
