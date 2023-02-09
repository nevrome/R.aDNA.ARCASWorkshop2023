
anno <- readr::read_csv("data/Europe.anno", guess_max = 2000)

pca_out <- smartsnp::smart_pca(
  snp_data = "data/Europe.geno", # genotype data file
  sample_group = anno$ID, # we don't apply any grouping
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

head(pca_out$pca.sample_coordinates)

pca_out$pca.eigenvalues

pca_out$pca.sample_coordinates$Class |> table()

anno_pca <- dplyr::left_join(anno, pca_out$pca.sample_coordinates, by = c("ID" = "Group"))

library(ggplot2)

p1 <- ggplot() +
  geom_point(
    data = anno_pca |> dplyr::filter(Sample_Type == "modern"),
    mapping = aes(x = PC1, y = PC2, text = Group)
  )

plotly::ggplotly(p1, tooltip="text")

(ggplot() +
  geom_point(
    data = anno_pca |> dplyr::filter(Sample_Type == "modern"),
    mapping = aes(x = PC1, y = PC2, text = Group)
  ) +
  geom_point(
    data = anno_pca |> dplyr::filter(Age_Mean < -1000),
    mapping = aes(x = PC1, y = PC2, text = Group),
    color = "red"
  )) |>
  plotly::ggplotly(tooltip="text")

