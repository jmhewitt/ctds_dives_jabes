report_plan = drake_plan(
  
  posterior_report_fulldata_fit = target(
    rmarkdown::render(
      knitr_in(!!file.path('reports', 'templates',
                           'posterior_diagnostics.Rmd')),
      output_file = 'mcmc_posteriors_full.html',
      output_dir = 'reports',
      quiet = FALSE,
      params = list(samples = mcmc_samples_nim_pkg_0,
                    nim_pkg_tgt = 'nim_pkg_0',
                    nburn = nburn)
    )
  ),
  
  interanimal_variability = interanimal_variability_plots(
    samples = mcmc_samples_nim_pkg_0, nburn = nburn, nim_pkg = nim_pkg_0,
    tag_sex = tag_sex
  )
  
)

