
function opts = setup(opts)

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

try
  hwwba.util.add_depends( opts );
  hwwba.util.try_add_ptoolbox();
catch err
  warning( err.message );
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
TRACKER = EyeTracker( '', cd, WINDOW.index );
TRACKER.bypass = opts.INTERFACE.use_mouse;
TRACKER.init();

%   TIMER
TIMER = Timer();
TIMER.register( opts.TIMINGS.time_in );

%   IMAGES
image_info = get_images( PATHS.stimuli );

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
      im = stim.image_matrix;
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
comm = serial_comm.SerialManager( SERIAL.port, struct(), SERIAL.channels );
comm.bypass = ~opts.INTERFACE.use_reward;
comm.start();
SERIAL.comm = comm;

%   EXPORT
opts.STIMULI = STIMULI;
opts.WINDOW = WINDOW;
opts.TRACKER = TRACKER;
opts.TIMER = TIMER;
opts.SERIAL = SERIAL;

end

function image_info = get_images(image_path)

import shared_utils.io.dirnames;
percell = @(varargin) cellfun( varargin{:}, 'un', 0 );

fmts = { '.png', '.jpg', '.jpeg' };

max_depth = 3;

subfolders = shared_utils.io.dirnames( image_path, 'folders' );

image_info = struct();

for i = 1:numel(subfolders)

  walk_func = @(p, level) ...
    deal( ...
        {horzcat_mult(percell(@(x) shared_utils.io.find(p, x), fmts))} ...
      , numel(horzcat_mult(percell(@(x) shared_utils.io.find(p, x), fmts))) > 0 ...
    );

  [image_fullfiles, image_components] = shared_utils.io.walk( ...
      fullfile(image_path, subfolders{i}), walk_func ...
    , 'outputs', true ...
    , 'max_depth', max_depth ...
  );

  images = cell( size(image_fullfiles) );
  image_filenames = cell( size(image_fullfiles) );

  for j = 1:numel(image_fullfiles)
    images{j} = cellfun( @imread, image_fullfiles{j}, 'un', 0 );
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

