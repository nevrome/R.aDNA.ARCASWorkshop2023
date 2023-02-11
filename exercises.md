# Exercise 1: Streaming

Write streaming code to extract all female individuals from the `Europe.ind` file and create a new file `Europe_female.ind`.

Hints:
- `Europe.ind` is available at https://share.eva.mpg.de/index.php/s/PH3peZyMsSNxo6B
- You don't need to explicitly call `laF` for this. `chunked` includes the convenience function `chunked::read_table_chunkwise()`.

# Excercise 2: PCA

Prepare a plot to trace the general "genomic" history of Rome and the surrounding regions in PCA space.

Hints:
- You don't have to run the PCA: `prep_Europe_PCA.anno` is available in the shared directory

# Exercise 3: mobest

Reconstruct a spatial genetic similarity field of the individual `SI-40.SG` at around 1150AD. Is the result surprising, considering where the individual was buried?

Hints:
- To run mobest you have to install it from GitHub (https://github.com/nevrome/mobest). You can do this with 

```
if(!require('remotes')) install.packages('remotes')
remotes::install_github('nevrome/mobest')
```

- On Windows you will need the RTools (https://cran.r-project.org/bin/windows/Rtools) to install packages from GitHub
