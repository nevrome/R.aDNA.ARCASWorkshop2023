library(magrittr)

anno_pca <- readr::read_csv("data/Europe_PCA.anno", guess_max = 2000)

anno_ancient <- anno_pca %>%
  dplyr::filter(Sample_Type == "ancient")

anno_coords <- anno_ancient %>%
  sf::st_as_sf(coords = c("Lon", "Lat"), crs = 4326) %>%
  sf::st_transform(crs = 3035) %>%
  dplyr::mutate(
    .,
    x = sf::st_coordinates(.)[,1],
    y = sf::st_coordinates(.)[,2]
  ) %>%
  sf::st_drop_geometry()

anno_ref <- anno_coords

prediction_grid <- rnaturalearthdata::countries50 %>%
  sf::st_as_sf() %>%
  sf::st_make_valid() %>%
  sf::st_transform(crs = 3035) %>%
  sf::st_crop(
    xmin = min(anno_coords$x),
    ymin = min(anno_coords$y),
    xmax = max(anno_coords$x),
    ymax = max(anno_coords$y)
  ) %>%
  mobest::create_prediction_grid(100000)
  
prediction_grid %>% ggplot() +
  geom_raster(aes(x, y)) +
  geom_text(aes(x,y,label = id), colour = "white", size = 2.5) +
  coord_fixed()

anno_ref %>%
  ggplot() + geom_point(aes(x = x, y = y))

anno_search <- anno_ref %>%
  dplyr::filter(ID == "Stuttgart_published.DG")

search_comic <- mobest::locate(
  independent = mobest::create_spatpos(
    id = anno_coords$ID,
    x = anno_coords$x,
    y = anno_coords$y,
    z = anno_coords$Age_Mean
  ),
  dependent = mobest::create_obs(
    PC1 = anno_coords$PC1,
    PC2 = anno_coords$PC2
  ),
  kernel = mobest::create_kernset(
    PC1 = mobest::create_kernel(800000, 800000, 800, 0.1),
    PC2 = mobest::create_kernel(800000, 800000, 800, 0.1)
  ),
  search_independent = mobest::create_spatpos(
    id = anno_search$ID,
    x = anno_search$x,
    y = anno_search$y,
    z = anno_search$Age_Mean
  ),
  search_dependent = mobest::create_obs(
    PC1 = anno_search$PC1,
    PC2 = anno_search$PC2
  ),
  search_space_grid = prediction_grid,
  search_time = seq(-7500, -5000, 500),
  search_time_mode = "absolute"
)

search_comic_prod <- mobest::multiply_dependent_probabilities(search_comic)

search_comic_prod %>%
  ggplot() +
  facet_wrap(~field_z) +
  geom_raster(aes(field_x, field_y, fill = probability)) +
  geom_point(data = anno_search, mapping = aes(x = x, y = y), color = "red") +
  coord_fixed() +
  scale_fill_viridis_c() +
  theme(axis.text = element_blank(), axis.title = element_blank(), axis.ticks = element_blank())
