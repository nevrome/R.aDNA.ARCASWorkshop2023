# R.aDNA.ARCASWorkshop2023

This repo stores materials for a 1h intro to aDNA genotype data, stream processing, PCAs and our [mobest](https://github.com/nevrome/mobest) algorithm.

`R/` stores the relevant scripts to compile, interact and produce `data/`. The data is too big to store in this repository, though, so it is omitted here. The input dataset, essentially a simplified subset of the [AADR v.50 dataset](https://reich.hms.harvard.edu/allen-ancient-dna-resource-aadr-downloadable-genotypes-present-day-and-ancient-dna-data), can be prepared from scratch using the code in this [repository](https://github.com/nevrome/mobest.analysis.2022) and compiled with the script in `R/data_prep.R`.

The following didactic scripts are included:

- `R/streaming.R`: Stream processing in R to read, modify and write large datasets in chunks.
- `R/pca.R`: Running PCA with ancient genomic data.
- `R/mobest.R`: Applying the [mobest](https://github.com/nevrome/mobest) algorithm to determine spatio-temporal similarity surfaces for individual samples.
