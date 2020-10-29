# Reproducibility for analyzing discretely-observed whale dives

This code repository contains data and workflows required to analyze whale dives
collected via satellite tags, which are often configured to collect
discretized depth measurements once every five minutes.

The repository contains simulation and analysis code, as well as exploratory
analyses.  The rest of this document outlines how to reproduce the principal
analyses.  Currently, all analyses use seeds to generate simulation data and
validation partitions.


# All R packages required

You may need to install additional packages in order to run the scripts in this
repository.  The packages used in this analysis are listed in the
[packages.R](packages.R) script.


# Steps for principal analyses

The code is designed to be run using the `drake` package, by running the code
in the script [make.R](make.R) either via the command line
(i.e., `R CMD BATCH make.R`), or from within an interactive `R` session.
The outline of all project components (i.e., the `drake` plan) is available in
the [R/subplans](R/subplans) directory.
