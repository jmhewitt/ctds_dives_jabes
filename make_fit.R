## Load your packages, e.g. library(drake).
source("./packages.R")

## Load your R files and subplans
invisible(lapply(list.files("./R", full.names = TRUE, recursive = TRUE), source))

source('R/plan.R')

make(the_plan, targets = 'mcmc_samples_nim_pkg_0', lock_envir = FALSE)