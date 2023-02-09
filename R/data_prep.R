# the data for this analysis was copied from https://github.com/nevrome/mobest.analysis.2022

load("../mobest.analysis.2022/data/genotype_data/janno_final.RData")

raw_data_path <- "../mobest.analysis.2022/data/genotype_data/snp_subsets/unfiltered_snp_selection_with_modern_reference_pops/unfiltered_snp_selection_with_modern_reference_pops"
ind_file <- paste0(raw_data_path, ".ind")
snp_file <- paste0(raw_data_path, ".snp")
geno_file <- paste0(raw_data_path, ".geno")

file.copy(ind_file, "data/Europe.ind")
file.copy(snp_file, "data/Europe.snp")
file.copy(geno_file, "data/Europe.geno")

anno_minimal <- readr::read_tsv(ind_file, col_names = c("ID", "Sex", "Group"))

anno_ancient <- janno_final |>
  dplyr::transmute(
    ID = Poseidon_ID,
    Lat = Latitude, Lon = Longitude,
    Age_Start = Date_BC_AD_Start_Derived,
    Age_Mean = Date_BC_AD_Median_Derived,
    Age_Stop = Date_BC_AD_Stop_Derived
  )

anno <- dplyr::left_join(anno_minimal, anno_ancient,  by = "ID") |>
  dplyr::mutate(
    Sample_Type = ifelse(is.na(Age_Mean), "modern", "ancient"), .before = "ID"
  )

readr::write_csv(anno, file = "data/Europe.anno")
