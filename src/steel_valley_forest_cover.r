# Diretório de Trabalho
setwd("./maps")

# Carrega os Pacotes
packages <- c("tidyverse", "terra", "geobr", "sf", "rayshader", "magick")
invisible(lapply(packages, library, character.only = TRUE))

# Sistema de Referência de Coordenadas
crs <- "+proj=longlat +datum=WGS84 +no_defs"

# Obtendo informações da região de interesse
code_cities <- c(3119401, 3131307, 3168705, 3158953)
list_cities <- lapply(code_cities, function(code) {
  sf::st_transform(geobr::read_municipality(code_muni = code), crs)
})
map_borders <- do.call(rbind, list_cities)
plot(map_borders)