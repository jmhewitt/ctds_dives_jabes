interanimal_variability_plots = function(samples, nburn, nim_pkg, tag_sex,
                                         validation_statistics) {

  # load posterior samples from file passed as argument
  load(samples)

  # posterior samples to discard
  burn = 1:nburn
  
  # clean up tag labels
  levels(tag_sex$deployid) = gsub('Tag', '', levels(tag_sex$deployid))
  
  # construct long-format df for plotting
  df = do.call(rbind, lapply(1:nim_pkg$consts$N_tags, function(tagId) {
    data.frame(tag = tag_sex$deployid[tagId], 
               lambda1 = samples[-burn, paste('lambda[', tagId, ', 1]', 
                                              sep = '')],
               lambda3 = samples[-burn, paste('lambda[', tagId, ', 3]', 
                                              sep = '')])
  }))
  
  # construct bivariate density plot for all tags
  pl = ggplot(df, aes(x = lambda1, y = lambda3, col = tag)) + 
    geom_density2d() + 
    scale_color_brewer('Whale', type = 'qual', palette = 'Dark2') + 
    xlab(expression(lambda^(1))) + 
    ylab(expression(lambda^(3))) + 
    geom_abline(slope = 1, intercept = 0, lty = 3) + 
    coord_equal() + 
    theme_few() + 
    theme(panel.border = element_blank(), 
          axis.title.y = element_text(angle = 0, vjust = 0.5))
  
  # save plot
  out.dir = file.path('plots', 'posteriors')
  dir.create(out.dir, showWarnings = FALSE, recursive = TRUE)
  ggsave(pl, filename = file.path(out.dir, 'bivariate_speeds.png'), 
         dpi = 'print')
  
  
  #
  # predictive duration distributions
  #
  
  # merge predictive distributions for overall duration
  df = do.call(rbind, lapply(1:nim_pkg$consts$N_tags, function(tagId) {
    cbind(
      readd(target = paste('validation_statistics_', tagId, sep = ''), 
            character_only = TRUE),
      tag = tag_sex$deployid[tagId]
    )
  })) %>% filter(stage == 'Overall dive')
  
  # comparative boxplot
  pl = ggplot(df, aes(y = stage.duration/60, x = tag)) + 
    geom_boxplot() + 
    xlab('Whale') + 
    ylab('Overall dive duration (min)') + 
    theme_few() + 
    theme(panel.border = element_blank())
  
  # save plot
  ggsave(pl, filename = file.path(out.dir, 'predictive_durations.png'), 
         dpi = 'print')
  
  0
}