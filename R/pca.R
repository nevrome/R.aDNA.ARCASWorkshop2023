#### load data ####

# read annotation file with context information
anno <- readr::read_csv("data/Europe.anno", guess_max = 2000)

#### run pca ####

pca_out <- smartsnp::smart_pca(
  snp_data = "data/Europe.geno", # genotype data file
  sample_group = anno$ID, # individual IDs
  # we project the ancient samples into a space established by modern samples
  sample_project = which(anno$Sample_Type == "ancient"),
  # ancient data lacks information for many SNPs, but (this implementation) of
  # PCA needs complete data, so missing values are imputed
  missing_impute = "mean",
  # we want to recover only two output dimensions
  pc_axes = 2,
  pc_project = 1:2
)

str(pca_out)
pca_out$pca.eigenvalues
head(pca_out$pca.snp_loadings)
head(pca_out$pca.sample_coordinates)
pca_out$pca.sample_coordinates$Class |> table()

#### compile output dataset ####

anno_pca <- dplyr::left_join(anno, pca_out$pca.sample_coordinates, by = c("ID" = "Group"))
readr::write_csv(anno_pca, file = "data/Europe_PCA.anno")

#### explore pca ####

library(ggplot2)
`-.gg` <- function(e1, e2) e2(e1)

ggplot() +
  geom_point(
    data = anno_pca |> dplyr::filter(Sample_Type == "modern"),
    mapping = aes(x = PC1, y = PC2, text = Group)
  ) -
  plotly::ggplotly

ggplot() +
  geom_point(
    data = anno_pca |> dplyr::filter(Sample_Type == "modern"),
    mapping = aes(x = PC1, y = PC2, text = Group)
  ) +
  geom_point(
    data = anno_pca |> dplyr::filter(Age_Mean < -5000),
    mapping = aes(x = PC1, y = PC2, text = Group),
    color = "red"
  ) -
  plotly::ggplotly

#### one area through time ####

saxony_anhalt <- anno_pca |> 
  dplyr::filter(Lon >= 10 & Lon <= 13 & Lat >= 51 & Lat <= 53)

saxony_anhalt |>
  sf::st_as_sf(coords = c("Lon", "Lat"), crs = 4326) |>
  mapview::mapview()

ggplot() +
  geom_point(
    data = anno_pca |> dplyr::filter(Sample_Type == "modern"),
    mapping = aes(x = PC1, y = PC2, text = Group)
  ) +
  geom_point(
    data = saxony_anhalt |> dplyr::filter(Age_Mean < -6000),
    mapping = aes(x = PC1, y = PC2, text = Group),
    color = "red"
  ) -
  plotly::ggplotly

