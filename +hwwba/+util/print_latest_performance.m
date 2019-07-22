function print_latest_performance(conf)

%%
if ( nargin < 1 || isempty(conf) )
  conf = hwwba.config.load();
else
  hwwba.util.assertions.assert__is_config( conf );
end

try
  data_p = conf.PATHS.data;
  subdirs = shared_utils.io.find( data_p, 'folders' );
  subdir_names = shared_utils.io.filenames( subdirs );
  date_nums = nan( size(subdir_names) );
  
  for i = 1:numel(subdir_names)
    try
      is_valid_dir_name = all( isstrprop(subdir_names{i}, 'digit') ) && numel(subdir_names{i}) == 6;
      if ( is_valid_dir_name )
        date_nums(i) = datenum( subdir_names{i}, 'mmddyy' );
      end
    end    
  end
  
  non_nans = find( ~isnan(date_nums) );
  [~, max_ind] = max( date_nums(non_nans) );

  perf_dir = subdirs{non_nans(max_ind)};
  task_dirs = shared_utils.io.find( perf_dir, 'folders' );
  clc;
  
  for i = 1:numel(task_dirs)
    task_mats = shared_utils.io.findmat( task_dirs{i} );
    task_filenames = shared_utils.io.filenames( task_mats );
    task_date_nums = nan( size(task_filenames) );
    task_dir_name = shared_utils.io.filenames( task_dirs{i} );
    
    for j = 1:numel(task_filenames)
      task_date_nums(j) = datenum( datestr(strrep(task_filenames{j}, '_', ':')) );
    end
    
    [~, max_task_ind] = max( task_date_nums );
    
    task_file = load( task_mats{max_task_ind} );
    
    fprintf( 'TASK: %s', task_dir_name );
    task_file.perf_func( task_file.DATA(end), task_file.PERFORMANCE, numel(task_file.DATA) );
    fprintf( '\n\n' );
  end
  
catch err
  warning( err.message );
end

end