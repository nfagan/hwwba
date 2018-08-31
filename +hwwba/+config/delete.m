function delete()

const = hwwba.config.constants();

config_folder = const.config_folder;
config_file = const.config_filename;

config_filepath = fullfile( config_folder, config_file );

if ( exist(config_filepath, 'file') == 2 )
  delete( config_filepath );
else
  warning( 'File "%s" does not exist.', config_filepath );
end

end