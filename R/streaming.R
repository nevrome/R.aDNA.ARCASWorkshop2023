# I can't open the .geno file in RStudio - it's too big.
# I can try to open it with gedit, but it takes forever to load.
# But I can easily look at it with less: What's going on here?
# less "streams" the data, so it only loads into memory what it currently needs.
# R generally does not stream information. It loads everything into memory.
# This script introduce two packages that allow (very basic) stream processing in R.

#### prepare data ####

# read small ind file to extract the individual names
inds <- readr::read_tsv("data/Europe.ind", col_names = c("id", "sex", "group"))

# create a streaming connection to the large .geno file with LaF
# (https://github.com/djvanderlaan/LaF)
laf_geno_europe <- LaF::laf_open_fwf(
  "data/Europe.geno", 
  column_widths = rep(1, nrow(inds)), 
  column_types = rep("integer", nrow(inds)),
  column_names = inds$id
)

class(laf_geno_europe)
str(laf_geno_europe)

#### examples of stream processing ####

## example 1: subset columns ##

# read .geno file in chunks of 10000 lines
chunked::read_laf_chunkwise(laf_geno_europe, chunk_size = 10000) |>
  # extract the first 50 cols (individuals)
  dplyr::select(1:50) |> # dplyr::select is replaced by chunked:::select.chunkwise
  # write the modified result back to the file system
  chunked::write_table_chunkwise(file = "data/first50.geno", sep = "", col.names = F, row.names = F)

# watch the file grow on the command line: watch wc -l first50.geno
# ignore error at the end: write_table_chunkwise tries to read the file after writing (like a T pipe!) and fails

## example 2: modify values ##

# establish another LaF connection to the new, smaller file
laf_geno <- LaF::laf_open_fwf(
  "data/prep_first50.geno", 
  column_types = rep("integer", 50),
  column_widths = rep(1, 50), 
  column_names = inds$id[1:50]
)

chunked::read_laf_chunkwise(laf_geno, chunk_size = 10000) |>
  # heterozygous -> 1, missing and homozygous -> 0
  dplyr::mutate(
    dplyr::across(.fns = \(x) dplyr::case_when(x == 1 ~ 1, TRUE ~ 0))
  ) |>
  chunked::write_table_chunkwise(file = "data/binary.geno", sep = "", col.names = F, row.names = F)

## example 3: calculate summary statistics ##

result1 <- chunked::read_laf_chunkwise(laf_geno, chunk_size = 10000) |>
  # fold chunk-wise to count non-missing SNPs (!=9)
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

print_progress <- function(x) {
  pretty_x <- format(x, big.mark = ",", scientific = FALSE)
  paste("Nr of SNPs aggregated:", pretty_x) |> message()
}

chunk_progress <- function(x, chunk_size) {
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
  chunk_progress(chunk_size) |>
  dplyr::summarise(
    dplyr::across(.fns = \(x) sum(x != 9))
  ) |>
  tibble::as_tibble() |>
  dplyr::summarise(
    dplyr::across(.fns = \(x) sum(x))
  )
