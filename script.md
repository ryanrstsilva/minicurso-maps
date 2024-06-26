# Elaboração do Script
[Voltar](./readme.md)

## Configurações Iniciais e Carregamento de Dados

O primeiro passo é definir o diretório de trabalho. Comumente, o diretório raiz do projeto é escolhido para essa função. Em seguida, realizamos o carregamento dos pacotes que serão utilizados.

```r
# Diretório de Trabalho
setwd("./")

# Carregamento dos pacotes
packages <- c("tidyverse", "terra", "geobr", "sf", "rayshader", "magick")
invisible(lapply(packages, library, character.only = TRUE))
```
![R Packages](./tutorial/minicurso_mapsr_packages.png)

Podemos então carregar os arquivos da nossa fonte de dados, lebrando que podemos passar o caminho completo, ou a partir do nosso diretório de trabalho.

```r
# Carrega os arquivos do Dataset
raster_files <- c(
    "./data/W060N00_PROBAV_LC100_global_v3.0.1_2019-nrt_Tree-CoverFraction-layer_EPSG-4326.tif", #nolint
    "./data/W060S20_PROBAV_LC100_global_v3.0.1_2019-nrt_Tree-CoverFraction-layer_EPSG-4326.tif"  #nolint
)
forest_cover <- lapply(raster_files, terra::rast)
forest_cover <- do.call(terra::mosaic, forest_cover)
```

Agora precisamos obter os dados de fronteira da região à qual estaremos criando o mapa. O pacote para realizar essa tarefa varia de acordo com o local, no nosso caso, como estaremos criando mapas de regiões do brasil, usamos o pacote geobr. Outra coisa que vale mencionar é o Sistema de Refêrencia de Coordenadas. O geobr usa o SIRGAS2000 que é formato padrão utilizado no Brasil, mas nossa fonte de dados usa o WGS84, por isso é necessário realizar a conversão.

```r
# Sistema de Referências de Coordenadas
crs <- "+proj=longlat +datum=WGS84 +no_defs"

# Informações de Fronteira e Metadados
borders <- sf::st_transform(geobr::read_immediate_region(code_immediate = "310024"), crs) #nolint
borders |> ggplot() + geom_sf

``` 

Transformamos os dados de fronteira em um SpatVector, que é um tipo para representar dados espaciais vetoriais, para então realizar a operação de filtro.
```r
# Converte os dados de fronteira de sf para SpatVector
borders_vect <- terra::vect(borders)

# Filtra a região do Mapa definido pelo objeto anterior
forest_cover_map <- terra::crop(forest_cover, borders_vect, snap = "in", mask = TRUE, overwrite = TRUE)
```

Usando o pacote terra, filtramos a região de interrese usando a função crop.
```r
forest_cover_map <- terra::crop(forest_cover, borders_vect, snap = "in", mask = TRUE, overwrite = TRUE)
```

## GGPLOT2
O ggplot2 é um pacote de visualização de dados para a linguagem R. Ele permite criar gráficos estatísticos elegantes e personalizáveis, seguindo a filosofia da “gramática dos gráficos”.

### De Raster para Dataframe
Antes de utilizarmos o pacote ggplot2 precisamos fazer algumas coisas. A primeira é converter o resultado da última etapa para um Dataframe, que é tido de dados que armazena as informações em formato tabular.
```r
forest_cover_df <- forest_cover_map |> as.data.frame(xy = TRUE)
names(forest_cover_df)[3] <- "percent_cover"
```

### Escala da Legenda
Depois realizamos da configuração da escala da legenda:
```r
min_val <- min(forest_cover_df$percent_cover)
max_val <- max(forest_cover_df$percent_cover)
limits <- c(min_val, max_val)
breaks <- seq(from = min_val, to = max_val, by = 20)
```

### Paleta de Cores

O último passo antes de realizar o plote é definir uma paleta de cores para nosso mapa. Existem diversos sites e serviços online que auxiliam na criação de paleta de cores. Os que utilizei nesse tutorial foram [ColorDesigner](https://colordesigner.io/) para criação da paleta em si, e o [Chroma.js Color Palette Helper](https://gka.github.io/palettes/#/9|s|00429d,96ffea,ffffe0|ffffe0,ff005e,93003a|1|1) para verificar se a paleta é segura para daltônicos.

```r
# Criamos uma vetor com as quatro cores que irão definir nossa paleta
cols <- c("#ffeadb", "#ffd3af", "#ddb746", "#276604")

# Usando a função abaixo criamos uma paleta de 256 cores baseadas no que definimos anteriormente
texture <- colorRampPalette(cols)(256)
```

### Plote

Iniciamos o Plot chamando a função ggplot passando nosso Dataframe como parâmetro. Em seguida, chamamos a função geom_raster para especificar como devem ser interpretados os dados do nosso Dataframe. Na função scale_fill_gradientn, definimos informações da legenda como nome, cores e escala. Na função coord_sf definimos o CRS que deve ser utilizado. E nas funções theme_minimal() e theme, definimos as configurações de formatação do mapa.
``` r
p <- ggplot2::ggplot(forest_cover_df) +
  ggplot2::geom_raster(ggplot2::aes(x = x, y = y, fill = percent_cover)) +
  ggplot2::scale_fill_gradientn(
    name = "% of area",
    colours = texture,
    breaks = breaks,
    limits = limits
  ) +
  ggplot2::coord_sf(crs = crs) +
  ggplot2::theme_minimal() +
  ggplot2::theme(
    axis.line = element_blank(),
    axis.title.x = element_blank(),
    axis.title.y = element_blank(),
    axis.text.x = element_blank(),
    axis.text.y = element_blank(),
    panel.grid.minor = element_blank(),
    panel.grid.major = element_blank(),
    legend.position = "right",
    legend.title.position = "bottom",
    legend.title = element_text(size = 7, color = "grey10"),
    legend.text = element_text(size = 5, color = "grey10"),
    plot.background = element_rect(fill = "white", color = NA),
    panel.background = element_rect(fill = "white", color = NA),
    legend.background = element_rect(fill = "white", color = NA),
  )
```





## Rayshader

O Rayshader é um pacote de código aberto para produzir visualizações de dados 2D e 3D em R. Ele utiliza matrizes de dados de elevação e uma combinação de traçado de raios, algoritmos de hillshading e sobreposições para gerar mapas 2D e 3D impressionantes.

 
A primeira função do pacote rayshader que vamos usar é a plot_gg(). Alguns dos parâmetros 


```r
w <- ncol(forest_cover_map)
h <- nrow(forest_cover_map)

# Plota um objeto ggplot2 em 3D
rayshader::plot_gg(
  ggobj = p,
  multicore = TRUE,
  width = w * 7 / h,
  height = 7,
  windowsize = c(1280, 720),
  offset_edges = TRUE,
  shadow_intensity = .99,
  phi = 85,
  theta = 0,
  zoom = .5,
)

# Posiciona a Câmera
rayshader::render_camera(theta = 0, phi = 85, zoom = .5)
```

```r
# Realiza a rendenrização de uma imagem de alta qualidade com efeitos de iluminação.
rayshader::render_highquality(
  filename = "Ipatinga.png",
  lightintensity = 600,
  lightdirection = 225,
  lightaltitude = 30,
  preview = TRUE,
  width = 1280,
  height = 720,
  parallel = TRUE,
  interactive = FALSE
)
```

## Anotações no Mapa
A fase final do tutorial consiste em adicionar marcadores e anotações ao mapa. Normalmente, o que se deseja adicionar é um título para o mapa, o nome do autor e a fonte de dados utilizada. O magick é um pacote do R para processamento de imagens que podemos utilizar para essa finalidade.

Primeiro, fazemos a leitura da imagem:
```r
map <- magick::image_read("forest_cover.png")
```

Em seguida, podemos realizar as anotações usando a função image_annotate(). Nela, podemos definir, além do texto, a cor, o tamanho, a posição, a fonte, etc. Por fim, usamos a função image_write() para salvar a imagem final.
```r
map |>
  magick::image_annotate(
    "Relevo",
    color = alpha(texture[224], .7),
    size = 100,
    gravity = "northwest",
    location = "+175+150",
    font = "Book Antiqua"
  ) |>
  magick::image_annotate(
    "Minas Gerais",
    color = texture[224],
    size = 200,
    gravity = "northwest",
    location = "+175+235",
    font = "Book Antiqua"
  ) |>
  magick::image_annotate(
    "©2024 Ryan R. S. Silva",
    font = "Georgia",
    color = alpha("black", .75),
    size = 40,
    gravity = "southwest",
    location = "+50+225",
  ) |>
  magick::image_annotate(
    "rgl",
    font = "Georgia",
    color = alpha("black", .75),
    size = 40,
    gravity = "southwest",
    location = "+50+30",
  ) |>
  image_write("annotated_forest_cover.png")
```

