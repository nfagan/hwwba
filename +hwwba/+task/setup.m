
function opts = setup(opts, stimuli_subdirectory)

%   SETUP -- Prepare to run the task based on the saved config file.
%
%     Opens windows, starts EyeTracker, initializes Arduino, etc.
%
%     OUT:
%       - `opts` (struct) -- Config file, with additional parameters
%         appended.

if ( nargin < 1 || isempty(opts) )
  opts = hwwba.config.load();
else
  hwwba.util.assertions.assert__is_config( opts );
end

%   add missing fields to `opts` as necessary
opts = hwwba.config.reconcile( opts );

is_debug = opts.INTERFACE.is_debug;

try
  hwwba.util.add_depends( opts );
  hwwba.util.try_add_ptoolbox();
catch err
  warning( err.message );
end

if ( opts.INTERFACE.skip_sync_tests )
  Screen( 'Preference', 'SkipSyncTests', 1 );
end

STIMULI = opts.STIMULI;
SCREEN = opts.SCREEN;
SERIAL = opts.SERIAL;
PATHS = opts.PATHS;

%   SCREEN
[windex, wrect] = Screen( 'OpenWindow', SCREEN.index, SCREEN.background_color, SCREEN.rect );

%   WINDOW
WINDOW.center = round( [mean(wrect([1 3])), mean(wrect([2 4]))] );
WINDOW.index = windex;
WINDOW.rect = wrect;

%   TRACKER
data_path = opts.PATHS.data;
TRACKER = EyeTracker( hwwba.util.get_edf_filename(data_path), data_path, WINDOW.index );
TRACKER.bypass = opts.INTERFACE.use_mouse;
TRACKER.init();

%   TIMER
TIMER = Timer();
TIMER.register( opts.TIMINGS.time_in );

%   IMAGES
max_number_of_images = 20;
stimuli_subdirs = { stimuli_subdirectory };

image_info = get_images( PATHS.stimuli, is_debug, max_number_of_images, stimuli_subdirs );

%   STIMULI
stim_fs = fieldnames( STIMULI.setup );
for i = 1:numel(stim_fs)
  stim = STIMULI.setup.(stim_fs{i});
  if ( ~isstruct(stim) ), continue; end
  if ( ~isfield(stim, 'class') ), continue; end
  switch ( stim.class )
    case 'Rectangle'
      stim_ = Rectangle( windex, wrect, stim.size );
    case 'Image'
      if ( isfield(stim, 'image_file') )
        load_p = fullfile( opts.PATHS.stimuli, stim.image_file );
        try
          im = imread( load_p );
        catch err
          warning( err.message );
          im = [];
        end
      else
        im = stim.image_matrix;
      end
      stim_ = Image( windex, wrect, stim.size, im );
  end
  
  stim_.color = stim.color;
  stim_.put( stim.placement );
  
  if ( isfield(stim, 'shift') )
%     stim_.shift( stim.shift(1), stim.shift(2) );
  end
  
  if ( stim.has_target )
    duration = stim.target_duration;
    padding = stim.target_padding;
    stim_.make_target( TRACKER, duration );
    stim_.targets{1}.padding = padding;
  end
  STIMULI.(stim_fs{i}) = stim_;
end

STIMULI.setup.image_info = image_info;

%   SERIAL
comm = hwwba.util.get_serial_comm( opts );
comm.start();
SERIAL.comm = comm;

%   EXPORT
opts.STIMULI = STIMULI;
opts.WINDOW = WINDOW;
opts.TRACKER = TRACKER;
opts.TIMER = TIMER;
opts.SERIAL = SERIAL;

end

function image_info = get_images(image_path, is_debug, max_n, subfolders)

import shared_utils.io.dirnames;
percell = @(varargin) cellfun( varargin{:}, 'un', 0 );

% walk setup
fmts = { '.png', '.jpg', '.jpeg' };
max_depth = 3;
%   exclude files that have __archive__ in them
condition_func = @(p) isempty(strfind(p, '__archive__'));
%   find files that end in any of `fmts`
find_func = @(p) percell(@(x) shared_utils.io.find(p, x), fmts);
%   include files if more than 0 files match, and condition_func returns
%   false.
include_func = @(p) condition_func(p) && numel(horzcat_mult(find_func(p))) > 0;

if ( nargin < 4 )
  subfolders = shared_utils.io.dirnames( image_path, 'folders' );
end

image_info = struct();

for i = 1:numel(subfolders)
  
  walk_func = @(p, level) ...
    deal( ...
        {horzcat_mult(percell(@(x) shared_utils.io.find(p, x), fmts))} ...
      , include_func(p) ...
    );

  [image_fullfiles, image_components] = shared_utils.io.walk( ...
      fullfile(image_path, subfolders{i}), walk_func ...
    , 'outputs', true ...
    , 'max_depth', max_depth ...
  );

  images = cell( size(image_fullfiles) );
  image_filenames = cell( size(image_fullfiles) );

  for j = 1:numel(image_fullfiles)
    if ( is_debug )
      fprintf( '\n Image set %d of %d', j, numel(image_fullfiles) );
    end
    
    fullfiles = image_fullfiles{j};
    
    use_n = min( numel(fullfiles), max_n );
    imgs = cell( use_n, 1 );
    
    for k = 1:use_n
      if ( is_debug )
        [~, filename] = fileparts( fullfiles{k} );
        fprintf( '\n\t Image "%s": %d of %d', filename, k, numel(imgs) );
      end
      imgs{k} = imread( fullfiles{k} );
    end
    
    images{j} = imgs;
    image_filenames{j} = cellfun( @fname, image_fullfiles{j}, 'un', 0 );
  end

  image_info.(subfolders{i}) = [ image_components, image_fullfiles, image_filenames, images ];

end

end

function y = fname(x)
[~, y, ext] = fileparts( x );
y = [ y, ext ];
end

function y = horzcat_mult(x)
y = horzcat( x{:} );
end

function y = horzcat_imread(x)
y = { cellfun(@(z) imread(z), horzcat_mult(x), 'un', 0) };
end

