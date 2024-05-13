# Diretório de trabalho
setwd("./maps/")

# Instalação e carregamento dos pacotes
packages <- c("tidyverse", "terra", "geobr", "sf", "rayshader", "magick")
package_installed <- packages %in% rownames(installed.packages())
if (any(package_installed == FALSE))
  install.packages(packages[!package_installed])
invisible(lapply(packages, library, character.only = TRUE))


# Sistema de Referências de Coordenadas
crs <- "+proj=longlat +datum=WGS84 +no_defs"

# Obter informações e fronteira dos municípios
map_borders <- sf::st_transform(geobr::read_immediate_region(code_immediate = "310024"), crs) #nolint
plot(map_borders)

# Cria um SpatRaster a partir dos dados baixados
raster_files <- c(
    "C:/Users/ryanr/Code/R/Maps/minicurso/data/W060N00_PROBAV_LC100_global_v3.0.1_2019-nrt_Tree-CoverFraction-layer_EPSG-4326.tif", #nolint
    "C:/Users/ryanr/Code/R/Maps/minicurso/data/W060S20_PROBAV_LC100_global_v3.0.1_2019-nrt_Tree-CoverFraction-layer_EPSG-4326.tif"  #nolint
)
forest_cover <- lapply(raster_files, terra::rast)
forest_cover <- do.call(terra::mosaic, forest_cover)

# Converte o objeto sf para um objeto SparVector
map_vect <- terra::vect(map_borders)
forest_cover_map <- terra::crop(forest_cover, map_vect, snap = "in", mask = TRUE, overwrite = TRUE) #nolint

# forest_cover_map <- terra::aggregate(forest_cover_map, fact = 2) #nolint
plot(forest_cover_map)

# Raster to Dataframe
forest_cover_df <- forest_cover_map |> as.data.frame(xy = TRUE)
names(forest_cover_df)[3] <- "percent_cover"

# Breaks
summary(forest_cover_df$percent_cover)
min_val <- min(forest_cover_df$percent_cover)
max_val <- max(forest_cover_df$percent_cover)
limits <- c(min_val, max_val)
breaks <- seq(from = min_val, to = max_val, by = 20)

# Colors
cols <- rev(c("#276604", "#ddb746", "#ffd3af", "#ffeadb"))
texture <- colorRampPalette(cols)(256)

# GGPLOT2
p <- ggplot(forest_cover_df) +
  geom_tile(aes(x = x, y = y, fill = percent_cover)) +
#   geom_sf(data = country_borders, fill = "transparent",
#     color = "black", size = .2)
  scale_fill_gradientn(
    name = "% of area",
    colours = texture,
    breaks = breaks,
    limits = limits
  ) +
  coord_sf(crs = crs_longlat) +
  guides(
    fill = guide_legend(
        direction = "horizontal",
        keyheight = unit(1.25, units = "mm"),
        keywidth = unit(5, units = "mm"),
        title.position = "top",
        label.positionn = "bottom",
        nrow = 1,
        byrow = TRUE
    )
  ) +
  theme_minimal() +
  theme(
  axis.line = element_blank(),
  axis.title.x = element_blank(),
  axis.title.y = element_blank(),
  axis.text.x = element_blank(),
  axis.text.y = element_blank(),
  legend.position = "top",
  legend.title = element_text(size = 7, color = "grey10"),
  legend.text = element_text(size = 5, color = "grey10"),
  panel.grid.minor = element_blank(),
  panel.grid.major = element_line(color = "white", linewidth = 0),
  plot.background = element_rect(fill = "white", color = NA),
  panel.background = element_rect(fill = "white", color = NA),
  legend.background = element_rect(fill = "white", color = NA),
  plot.margin = unit(c(t = 0, r = 0, b = 0, l = 0), "lines")
) + 
labs(
  title = "",
  subtitle = "",
  caption = "",
  x = "",
  y = ""
)

## Rayshader
w <- ncol(forest_cover_map)
h <- nrow(forest_cover_map)

rayshader::plot_gg(
  ggobj = p,
  multicore = TRUE,
  width = 1,
  height = 1,
  windowsize = c(1400, 900),
  offset_edges = TRUE,
  shadow_intensity = .99,
  sunangle = 135,
  phi = 85,
  theta = 0,
  zoom = .5,
)

# 10. RENDER
#------------
rayshader::render_highquality(
  filename = "default.png",
  preview = TRUE,
  width = 1366,
  height = 768,
  parallel = TRUE,
  interactive = FALSE
)


# Regiões Geográficas Imediatas Minas Gerais

# Ipatinga                      310024
# Caratinga                     310025
# João Monlevade                310026

# Belo Horizonte                310001
# Sete Lagoas                   310002
# Santa Bárbara - Ouro Preto    310003
# Curvelo                       310004
# Itabira                       310005

# Governador Valadares          310020
# Guanhães                      310021

# Juiz de Fora                  310027
# Manhuaçu                      310028
# Viçosa                        310033

# Barbacena                     310037
# São João del-Rei              310039
