fit = function(nim_pkg, mcmc_sample_dir, niter, ncheckpoints, .id_chr,
               default_ranef_samplers = FALSE) {

  dir.create(mcmc_sample_dir, recursive = TRUE, showWarnings = FALSE)
  
  dive_model = nimbleModel(code = modelCode, constants = nim_pkg$consts,
                           data = nim_pkg$data, inits = nim_pkg$inits,
                           name = .id_chr)
  
  dive_model$initializeInfo()

  cmodel = compileNimble(dive_model)

  if(!is.finite(cmodel$calculate())) {
    cmodel.names = cmodel$getNodeNames()
    ll.nodes = sapply(cmodel.names, function(x) cmodel$calculate(x))
    names.oops = cmodel.names[which(!is.finite(ll.nodes))]
    print(names.oops)
    stop('Model does not have a finite likelihood')
  }

  cfg_mcmc = configureMCMC(cmodel, print = TRUE)

  # monitor dive-specific random effects
  cfg_mcmc$addMonitors(c('pi', 'lambda'))

  ##
  ## semi-warm start for model parameters, and use covariances for RW proposals
  ##

  #
  # movement parameter samplers
  #

  
  cfg_mcmc$removeSamplers(c('logit_pi'))
  
  lapply(c(1,3), function(s) {
    
    # status update
    message(paste('pi, stage:', s, sep = ' '))
    
    # specify target nodes, and extract dependencies
    tgt = paste(c('logit_pi['), s, ']', sep = '')
    deps = cmodel$getDependencies(tgt)
    
    # find posterior mode and hessian
    o = optim(par = cmodel$logit_pi[s],
              fn = function(theta) {
                cmodel$logit_pi[s] = theta
                cmodel$calculate(deps)
              }, method = 'BFGS', control = list(fnscale = -1), 
              hessian = TRUE)
    
    cov = as.numeric(solve(-o$hessian))
    if(any(!is.finite(cov), cov <= 0)) {
      cov = 1
    }
    
    # add sampler
    cfg_mcmc$addSampler(target = tgt, type = 'RW', silent = TRUE,
                        control = list(scale = sqrt(cov))
    )
    
  })
  
  
  cfg_mcmc$removeSamplers(c('log_lambda'))

  o_joint = lapply(1:nim_pkg$consts$N_tags, function(tagId) {

    # stage 1 and 3 parameters
    lapply(c(1,3), function(s) {

      # status update
      message(paste('tag:', tagId, 'stage:', s, sep = ' '))

      # specify target nodes, and extract dependencies
      tgt = paste(c('log_lambda['), tagId, ', ', s, ']', sep = '')
      deps = cmodel$getDependencies(tgt)

      # find posterior mode and hessian
      o = optim(par = cmodel$log_lambda[tagId, s],
                fn = function(theta) {
                  cmodel$log_lambda[tagId, s] = theta[1]
                  cmodel$calculate(deps)
                }, method = 'BFGS', control = list(fnscale = -1), 
                hessian = TRUE)

      cov = as.numeric(solve(-o$hessian))
      if(any(!is.finite(cov), cov <= 0)) {
        cov = 1
      }

      # add sampler
      cfg_mcmc$addSampler(target = tgt, type = 'RW', silent = TRUE,
                          control = list(scale = sqrt(cov))
      )
      
    })

    message(paste('tag:', tagId, 'stage:', 2, sep = ' '))

    # stage 2 parameter
    tgt = paste('log_lambda[', tagId, ', ', 2, ']', sep = '')
    deps = cmodel$getDependencies(tgt)

    o = optim(par = cmodel$log_lambda[tagId, 2],
              fn = function(theta) {
                cmodel$log_lambda[tagId, 2] = theta
                cmodel$calculate(deps)
              }, method = 'BFGS', control = list(fnscale = -1), hessian = TRUE)

    cfg_mcmc$addSampler(target = tgt, type = 'RW', silent = TRUE,
                        control = list(scale = as.numeric(sqrt(-1/o$hessian)))
    )

    o

  })


  if(!default_ranef_samplers) {
    #
    # dive endpoint samplers
    #
    
    cfg_mcmc$removeSamplers('endpoints')
    
    for(i in 1:nim_pkg$consts$N_endpoints) {
      
      tgt = paste('endpoints[', i, ']', sep = '')
      deps = cmodel$getDependencies(tgt)
      
      o = optim(par = cmodel[[tgt]], fn = function(theta) {
        cmodel[[tgt]] = theta
        cmodel$calculate(deps)
      }, method = 'Brent', control = list(fnscale = -1), hessian = TRUE,
      lower = nim_pkg$consts$endpoint_priors[i, 't_lwr'],
      upper = nim_pkg$consts$endpoint_priors[i, 't_upr'])
      
      sd = as.numeric(sqrt(-1/o$hessian))
      
      sd = ifelse(is.finite(sd), sd,
                  diff(nim_pkg$consts$endpoint_priors[i,]) / sqrt(12) / 3)
      
      cfg_mcmc$addSampler(target = tgt, type = 'RW', silent = TRUE,
                          control = list(scale = sd))
      
    }
    
    
    #
    # stage duration samplers
    #
    
    cfg_mcmc$removeSamplers('log_xi')
    
    for(i in 1:nim_pkg$consts$N_dives) {
      
      if(i %% 50 == 0) {
        message(paste('dive:', i))
      }
      
      tgt = paste('log_xi[', i, ', 1:2]', sep = '')
      deps = cmodel$getDependencies(tgt)
      
      o = optim(par = cmodel[[tgt]], fn = function(theta) {
        cmodel[[tgt]] = theta
        cmodel$calculate(deps)
      }, method = 'BFGS', control = list(fnscale = -1), hessian = TRUE)
      
      cov = solve(-o$hessian)
      if(any(eigen(cov)$values < 0)) {
        cov = diag(2)
      }
      
      cfg_mcmc$addSampler(target = tgt, type = 'RW_block', silent = TRUE,
                          control = list(propCov = cov))
      
    }
  }
  
  
  #
  # construct sampler
  #

  model_mcmc = buildMCMC(cfg_mcmc)

  cmcmc = compileNimble(model_mcmc, projectName = .id_chr)


  #
  # posterior samples
  #

  sample_file = file.path(mcmc_sample_dir, paste(.id_chr, '.RData', sep = ''))
  
  for(i in 1:ncheckpoints) {
    chunk_iter = ceiling(niter/ncheckpoints)
    cmcmc$run(niter = chunk_iter, reset = FALSE, progressBar = TRUE)
    samples = as.matrix(cmcmc$mvSamples)
    save.time = Sys.time()
    save(samples, save.time, file = sample_file)
  }
  
  sample_file

}
  