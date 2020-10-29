#
# chisq gof test formatting
#

chisq.gof = function(df, var, verbose = TRUE, collapse) {
  # Parameters:
  #  collapse - TRUE to merge cells with expected counts less than 5.  The
  #    merging will be done working from the tails toward the center of the
  #    distribution's support.
  
  # extract estimate of posterior predictive distribution
  prob = df %>% filter(series=='Post. Predictive') %>% ungroup()
  
  # extract validation samples
  obs = df %>% filter(series=='Empirical Validation') %>% ungroup()
  
  # compute support, and merge data; replace missing items with 0
  df.chisq = data.frame(support = sort(unique(c(prob[var] %>% unlist(),
                                                obs[var] %>% unlist())))) %>%
    left_join(prob %>% select(var, prob), by = c('support' = var)) %>%
    left_join(obs %>% select(var, n), by = c('support' = var)) %>%
    mutate_all(~replace(., which(is.na(.)), 0))
  
  colnames(df.chisq)[3] = 'observed'
  
  # collapse low-probability states to ensure at least 5 expected observations
  # per group
  if(collapse) {
    
    # minimum probability required per category
    p.min = 5 / sum(df.chisq$observed)
    
    df.chisq$groups = 0
    n = nrow(df.chisq)
    gp = 1
    
    # forward pass
    for(i in 1:nrow(df.chisq)) {
      if(df.chisq$groups[i]==0) {
        mass.exceedance = which(cumsum(df.chisq$prob[i:n]) >= p.min)
        if(length(mass.exceedance)>0) {
          gp.inds = i:(i:n)[min(mass.exceedance)]
          df.chisq$groups[gp.inds] = gp
          gp = gp + 1
        }
      }
    }
    
    # backward pass
    for(i in nrow(df.chisq):1) {
      if(df.chisq$groups[i]==0) {
        mass.exceedance = which(cumsum(df.chisq$prob[i:1]) >= p.min)
        if(length(mass.exceedance)>0) {
          gp.inds = i:(i:1)[min(mass.exceedance)]
          if(any(df.chisq$groups[gp.inds]>0)) {
            gp.tmp =  max(df.chisq$groups[df.chisq$groups[gp.inds]>0])
          } else {
            gp.tmp = gp
            gp = gp + 1
          }
          df.chisq$groups[gp.inds] = gp.tmp
        }
      }
    }
    
    # merge groups
    df.chisq = df.chisq %>%
      group_by(groups) %>%
      summarise(support = paste(c(round(min(support)),
                                  round(max(support))), collapse = '_'),
                prob = sum(prob),
                observed = sum(observed)) %>%
      ungroup() %>%
      select(-groups)
  }
  
  # run chisq test
  res = chisq.test(x = df.chisq$observed, p = df.chisq$prob)
  
  if(verbose) {
    # extract expected counts
    df.chisq$expected = round(res$expected)
    
    cat("==================================\n")
    cat("Chi-squared goodness of fit test\n")
    cat("==================================\n")
    
    cat("\n")
    
    print(c(res$statistic, res$parameter, p=res$p.value))
    
    cat("\n")
    
    print(df.chisq)
  }
  
  res
}
