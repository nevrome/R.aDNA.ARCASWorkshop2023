# can't open .geno file in gedit
# but I can look at it with less: What's going on here?

ind_file <- "/home/schmid/agora/mobest.analysis.2022/data/genotype_data/snp_subsets/unfiltered_snp_selection_with_modern_reference_pops/unfiltered_snp_selection_with_modern_reference_pops.ind"
geno_file <- "/home/schmid/agora/mobest.analysis.2022/data/genotype_data/snp_subsets/unfiltered_snp_selection_with_modern_reference_pops/unfiltered_snp_selection_with_modern_reference_pops.geno"

#### prepare data ####

# read small ind file to extract the individual names
inds <- readr::read_tsv(ind_file, col_names = c("id", "sex", "group"))

# create an LaF connection (https://github.com/djvanderlaan/LaF) to the large .geno file
laf_geno <- LaF::laf_open_fwf(
  geno_file, 
  column_types = rep("integer", nrow(inds)),
  column_widths = rep(1, nrow(inds)), 
  column_names = inds$id
)

class(laf_geno)
str(laf_geno)

#### examples of stream processing ####

# subset columns
chunked::read_laf_chunkwise(laf_geno, chunk_size = 10000) |>
  dplyr::select(1:100) |>
  chunked::write_table_chunkwise(file = "data/prep_first100.geno", sep = "", col.names = F, row.names = F)
# watch the file grow on the command line: watch wc -l data/prep_first100.geno
# ignore error at the end: write_table_chunkwise tries to read the file after writing (T pipe!) and fails

laf_geno <- LaF::laf_open_fwf(
  "data/prep_first100.geno", 
  column_types = rep("integer", 100),
  column_widths = rep(1, 100), 
  column_names = inds$id[1:100]
)

# change values
chunked::read_laf_chunkwise(laf_geno, chunk_size = 10000) |>
  dplyr::mutate(dplyr::across(.fns = \(x) ifelse(x == 1, 3, x) )) |>
  chunked::write_table_chunkwise(file = "data/nine2eight.geno", sep = "", col.names = F, row.names = F)

# summary statistics
# read .geno file in chunks of 5000 lines
result1 <- chunked::read_laf_chunkwise(laf_geno, chunk_size = 10000) |>
  # fold chunk-wise to count non-missing SNPs (!=9)
  # dplyr::summarise is actually overwritten by chunked:::summarise.chunkwise
  dplyr::summarise(
    dplyr::across(.fns = \(x) sum(x != 9))
  ) |>
  # transform intermediate result to tibble
  # (chunked is lazy, so the calculation starts only here)
  tibble::as_tibble() |>
  # complete the chunk-wise fold to a total sum
  dplyr::summarise(
    dplyr::across(.fns = \(x) sum(x))
  )

#### adding a progress indicator ####

progresso <- function(x, chunk_size) {
  print_progress <- \(x) { paste("Nr of SNPs aggregated:", x) |> message() }
  count <- 0
  x$first_chunk()
  count <- count + chunk_size
  print_progress(count)
  while (NROW(x$next_chunk())) { # while treats 0 as FALSE and everything > 0 as TRUE
    count <- count + chunk_size
    print_progress(count)
  }
  return(x)
}

chunk_size <- 20000
result2 <- chunked::read_laf_chunkwise(laf_geno, chunk_size = chunk_size) |>
  progresso(chunk_size) |>
  dplyr::summarise(
    dplyr::across(.fns = \(x) sum(x != 9))
  ) |>
  tibble::as_tibble() |>
  dplyr::summarise(
    dplyr::across(.fns = \(x) sum(x))
  )
