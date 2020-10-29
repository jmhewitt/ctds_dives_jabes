#
# integreated mean square error model fit/selection criteria
#

imse.gof = function(df, var, verbose = TRUE) {
  
  # extract estimate of posterior predictive distribution
  prob = df %>% filter(series=='Post. Predictive') %>% ungroup()
  prob = prob[order(prob[var] %>% unlist()),]
  
  # extract validation samples
  obs = df %>% filter(series=='Empirical Validation') %>% ungroup()
  
  # compute support, and merge data; replace missing items with 0
  df.ks = data.frame(support = sort(unique(c(prob[var] %>% unlist(),
                                             obs[var] %>% unlist())))) %>%
    left_join(prob %>% select(var, prob), by = c('support' = var)) %>%
    left_join(obs %>% select(var, prob), by = c('support' = var)) %>%
    mutate_all(~replace(., which(is.na(.)), 0))
  
  colnames(df.ks)[2:3] = c('prob.posterior', 'prob.observed')
  
  # expand validation samples to raw counts
  samples = rep(obs[var] %>% unlist(), obs$n)
  
  # compute squared differences between CDFs
  imse = sum((cumsum(df.ks$prob.posterior) - cumsum(df.ks$prob.observed))^2)
  
  if(verbose) {
    
    cat("==================================================\n")
    cat("Integrated mean square error model fit criteria\n")
    cat("==================================================\n")
    
    cat("\n")
    
    print(c(imse = imse))
    
    cat("\n")
    
    print(c(n=length(samples)))
  }
  
  imse
}