setwd("./maps")

packages <- c("tidyverse", "sf", "geobr", "terra", "rayshader", "classInt")
invisible(lapply(packages, library, character.only = TRUE))

raster_files <- "../data/ETH_GlobalCanopyHeight_10m_2020_S21W045_Map.tif"

crs <- "+proj=longlat +datum=WGS84 +no_defs"
code_cities <- c(3119401, 3131307, 3168705, 3158953)
list_cities <- lapply(code_cities, function(code) {
  sf::st_transform(geobr::read_municipality(code_muni = code), crs)
})
map_borders <- do.call(rbind, list_cities)
map_borders |> ggplot() + geom_sf()

forest_height <- terra::rast(raster_files)

map_vect <- terra::vect(map_borders)
forest_height_map <- terra::crop(
  forest_height,
  map_vect,
  snap = "in",
  mask = TRUE,
  overwrite = TRUE
)
plot(forest_height_map)

forest_height_df <- forest_height_map |> as.data.frame(xy = TRUE)
head(forest_height_df)
names(forest_height_df)[3] <- "height"

#---
summary(forest_height_df$height)
min_val <- min(forest_height_df$height)
max_val <- max(forest_height_df$height)
limits <- c(min_val, max_val)
breaks <- seq(from = min_val, to = max_val, by = 8)

# 6. COLORS
#----------

cols <- c("white", "#ffd3af", "#fbe06e", "#6daa55", "#205544")
texture <- colorRampPalette(cols, bias = 2)(6)

p <- ggplot(forest_height_df) +
  geom_raster(aes(x = x, y = y, fill = height)) +
  scale_fill_gradientn(
    name = "height (m)",
    colors = texture,
    breaks = round(breaks, 0)
) +
coord_sf(crs = 4326) +
guides(
    fill = guide_legend(
        direction = "vertical",
        keyheight = unit(2.5, "mm"),
        keywidth = unit(2.5, "mm"),
        title.position = "top",
        label.position = "right",
        title.hjust = .5,
        label.hjust = .5,
        ncol = 1,
        byrow = F
    )
) +
theme_minimal() +
theme(
    axis.line = element_blank(),
    axis.title.x = element_blank(),
    axis.title.y = element_blank(),
    axis.text.x = element_blank(),
    axis.text.y = element_blank(),
    legend.position = "right",
    legend.title = element_text(
      size = 11, color = "grey10"
    ),
    legend.text = element_text(
        size = 10, color = "grey10"
    ),
    panel.grid.major = element_line(
        color = "white"
    ),
     panel.grid.minor = element_line(
        color = "white"
    ),
    plot.background = element_rect(
        fill = "white", color = NA
    ),
    legend.background = element_rect(
        fill = "white", color = NA
    ),
    panel.border = element_rect(
        fill = NA, color = "white"
    ),
    plot.margin = unit(
        c(
            t = 0, r = 0,
            b = 0, l = 0
        ), "lines"
    )
)

# 8. RENDER SCENE
#----------------

h <- nrow(forest_height_map)
w <- ncol(forest_height_map)

rayshader::plot_gg(
  ggobj = p,
  width = w / 1000,
  height = h / 1000,
  scale = 150,
  solid = FALSE,
  soliddepth = 0,
  shadow = TRUE,
  shadow_intensity = .99,
  offset_edges = FALSE,
  sunangle = 315,
  windowsize = c(1200, 1200),
  zoom = .4,
  phi = 30,
  theta = -30,
  multicore = TRUE,
  shadowdepth = 0
)

rayshader::render_camera(phi = 75, zoom = .7, theta = 0)

# 9. RENDER OBJECT
#-----------------
rayshader::render_highquality(
  filename = "forest-height-vale-2020.png",
  preview = TRUE,
  interactive = FALSE,
  light = TRUE,
  lightdirection = c(315, 310, 315, 310),
  lightintensity = c(1000, 1500, 150, 100),
  lightaltitude = c(15, 15, 80, 80),
  ground_material = rayrender::microfacet(roughness = .6),
  width = 2160,
  height = 2160
)
