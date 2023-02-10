#### load data ####

anno_pca <- readr::read_csv("data/prep_Europe_PCA.anno", guess_max = 2000)

#### prepare mobest input ####

anno_ancient <- anno_pca |>
  dplyr::filter(Sample_Type == "ancient") |>
  sf::st_as_sf(coords = c("Lon", "Lat"), crs = 4326) |>
  sf::st_transform(crs = 3035) |>
  (\(.) {
    dplyr::mutate(
      .,
      x = sf::st_coordinates(.)[,1],
      y = sf::st_coordinates(.)[,2]
    )
  } )() |>
  sf::st_drop_geometry()

# anno_ancient |> ggplot() + geom_point(aes(x = x, y = y))

prediction_grid <- rnaturalearthdata::countries50 |>
  sf::st_as_sf() |>
  sf::st_make_valid() |>
  sf::st_transform(crs = 3035) |>
  sf::st_crop(
    xmin = min(anno_ancient$x),
    ymin = min(anno_ancient$y),
    xmax = max(anno_ancient$x),
    ymax = max(anno_ancient$y)
  ) |>
  mobest::create_prediction_grid(100000)
  
# prediction_grid |>
#   ggplot() +
#   geom_tile(aes(x, y), color = "white") +
#   coord_fixed()

# prediction_grid |>
#   ggplot() +
#   geom_tile(aes(x, y), color = "white") +
#   geom_point(data = anno_ancient, mapping = aes(x = x, y = y), color = "red")
#   coord_fixed()

#### select search sample ####

anno_search <- anno_ancient |> dplyr::filter(ID == "Stuttgart_published.DG")

#### run search ####
  
search_comic <- mobest::locate(
  # Spatiotemporal coordinates of reference samples
  independent = mobest::create_spatpos(
    id = anno_ancient$ID,
    x = anno_ancient$x,
    y = anno_ancient$y,
    z = anno_ancient$Age_Mean
  ),
  # Genetic "coordinates" of reference samples
  dependent = mobest::create_obs(
    PC1 = anno_ancient$PC1,
    PC2 = anno_ancient$PC2
  ),
  # Kernel parameters for GPR field interpolation
  kernel = mobest::create_kernset(
    PC1 = mobest::create_kernel(800000, 800000, 800, 0.1),
    PC2 = mobest::create_kernel(800000, 800000, 800, 0.1)
  ),
  # Spatiotemporal coordinates of search samples
  search_independent = mobest::create_spatpos(
    id = anno_search$ID,
    x = anno_search$x,
    y = anno_search$y,
    z = anno_search$Age_Mean
  ),
  # Genetic “coordinates” of search samples
  search_dependent = mobest::create_obs(
    PC1 = anno_search$PC1,
    PC2 = anno_search$PC2
  ),
  # Spatial search raster
  search_space_grid = prediction_grid,
  # Temporal search time slices
  search_time = seq(-7500, -5000, 500),
  search_time_mode = "absolute"
)

# calculate final probability as the product of the independent results for PC1 and PC2
search_comic_prod <- mobest::multiply_dependent_probabilities(search_comic)

#### explore the result ####

search_comic_prod |>
  ggplot() +
  facet_wrap(~field_z) +
  geom_raster(aes(field_x, field_y, fill = probability)) +
  geom_point(data = anno_search, mapping = aes(x = x, y = y), color = "red") +
  coord_fixed() +
  scale_fill_viridis_c() +
  theme(axis.text = element_blank(), axis.title = element_blank(), axis.ticks = element_blank())
