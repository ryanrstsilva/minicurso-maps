# Diretório de trabalho
setwd("./maps/")

# Instalação e carregamento dos pacotes
packages <- c("tidyverse", "terra", "geobr", "sf", "rayshader", "magick")
# package_installed <- packages %in% rownames(installed.packages())
# if (any(package_installed == FALSE))
#   install.packages(packages[!package_installed])
invisible(lapply(packages, library, character.only = TRUE))


# Sistema de Referências de Coordenadas
crs <- "+proj=longlat +datum=WGS84 +no_defs"

# Obter informações e fronteira do mapa
map_borders <- sf::st_transform(geobr::read_immediate_region(code_immediate = "310024"), crs) #nolint
plot(map_borders)

# Cria um SpatRaster a partir dos dados baixados
raster_files <- "../data/sdei-global-summer-lst-2013-day-max-americas.tif"
forest_cover <- terra::rast(raster_files)

# Carrega o dataset para trabalho
map_vect <- terra::vect(map_borders)
forest_cover_map <- terra::crop(forest_cover, map_vect, snap = "in", mask = TRUE, overwrite = TRUE) #nolint

# forest_cover_map <- terra::aggregate(forest_cover_map, fact = 2) #nolint
plot(forest_cover_map)

# Raster to Dataframe
forest_cover_df <- forest_cover_map |> as.data.frame(xy = TRUE)
names(forest_cover_df)[3] <- "temperature"

# Breaks
summary(forest_cover_df$temperature)
min_val <- min(forest_cover_df$temperature)
max_val <- max(forest_cover_df$temperature)
limits <- c(min_val, max_val)
breaks <- seq(from = min_val, to = max_val, by = 4)

# Colors
cols <- c("#2400b0", "#690098", "#d40036", "#dd0e0e")
texture <- colorRampPalette(cols)(256)










# 8. GGPLOT2
#-----------
p <- ggplot2::ggplot(forest_cover_df) +
  ggplot2::geom_raster(ggplot2::aes(x = x, y = y, fill = temperature)) +
  ggplot2::scale_fill_gradientn(
    name = "% of area",
    colours = texture,
    breaks = breaks,
    limits = limits
  ) +
  ggplot2::coord_sf(crs = crs) +
  ggplot2::guides(
    fill = guide_legend(
      direction = "horizontal",
      keywidth = unit(7, units = "mm"),
      keyheight = unit(1.8, units = "mm"),
      title.position = "top",
      label.position = "bottom",
      nrow = 1,
      byrow = TRUE
    )
  ) +
  ggplot2::theme_minimal() +
  ggplot2::theme(
    axis.line = element_blank(),
    axis.title.x = element_blank(),
    axis.title.y = element_blank(),
    axis.text.x = element_blank(),
    axis.text.y = element_blank(),
    legend.position = "top",
    legend.title = element_text(size = 7, color = "grey10"),
    legend.text = element_text(size = 5, color = "grey10"),
    panel.grid.minor = element_blank(),
    panel.grid.major = element_blank(),
    plot.background = element_rect(fill = "white", color = NA),
    panel.background = element_rect(fill = "white", color = NA),
    legend.background = element_rect(fill = "white", color = NA),
  ) +
  labs(title = "", subtitle = "", caption = "", x = "", y = "")

## Rayshader
w <- ncol(forest_cover_map)
h <- nrow(forest_cover_map)

rayshader::plot_gg(
  ggobj = p,
  multicore = TRUE,
  width = w * 7 / h,
  height = 7,
  windowsize = c(1280, 720),
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
  filename = "Ipatinga.png",
  preview = TRUE,
  width = 1280,
  height = 720,
  parallel = TRUE,
  interactive = FALSE
)



