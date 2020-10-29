raw_data_plan = drake_plan(
  
  # seconds between depth observations
  sattag_timestep = 300,
  
  # location of sattag series data
  depth_files = file_in(!!dir(path = file.path('data', 'raw'), 
                              pattern = 'series_', full.names = TRUE)),
  
  # location of message files associated with sattag series data
  message_files = file_in(!!dir(path = file.path('data', 'raw'), 
                                pattern = 'seriesrange_', full.names = TRUE)),
  
  # sex information for tags
  tag_sex = read.csv(file_in(!!file.path('data', 'raw', 'tag_sex.csv')), 
                     colClasses = 'factor'),
  
  # threshold for deep dives
  deep_dive_depth = 800
  
)