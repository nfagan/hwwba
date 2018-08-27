
function conf = create(do_save)

%   CREATE -- Create the config file. 
%
%     Define editable properties of the config file here.
%
%     IN:
%       - `do_save` (logical) -- Indicate whether to save the created
%         config file. Default is `false`

if ( nargin < 1 ), do_save = false; end

const = hwwba.config.constants();

conf = struct();

% ID
conf.(const.config_id) = true;

% PATHS
PATHS = struct();
PATHS.repositories = fileparts( hwwba.util.get_project_folder() );
PATHS.stimuli = fullfile( hwwba.util.get_project_folder(), 'stimuli' );

% DEPENDENCIES
DEPENDS = struct();
DEPENDS.repositories = { 'ptb_helpers', 'serial_comm', 'shared_utils' };

%	INTERFACE
INTERFACE = struct();
INTERFACE.stop_key = KbName( 'escape' );
INTERFACE.use_mouse = true;
INTERFACE.use_reward = false;

%	SCREEN
SCREEN = struct();

SCREEN.full_size = get( 0, 'screensize' );
SCREEN.index = 0;
SCREEN.background_color = [ 0 0 0 ];
SCREEN.rect = [ 0, 0, 400, 400 ];

%	TIMINGS
TIMINGS = struct();

time_in = struct();
time_in.new_trial = 0;
time_in.fixation = 1;
time_in.present_images = 1;
time_in.reward = 1;

TIMINGS.time_in = time_in;

%	STIMULI
STIMULI = struct();
STIMULI.setup = struct();

non_editable_properties = {{ 'placement', 'has_target', 'image_matrix' }};

STIMULI.setup.fix_square = struct( ...
    'class',            'Rectangle' ...
  , 'size',             [ 50, 50 ] ...
  , 'color',            [ 255, 255, 255 ] ...
  , 'placement',        'center' ...
  , 'has_target',       true ...
  , 'target_duration',  0.3 ...
  , 'target_padding',   50 ...
  , 'non_editable',     non_editable_properties ...
);

STIMULI.setup.image1 = struct( ...
    'class',            'Image' ...
  , 'image_matrix',     [] ...
  , 'size',             [ 50, 50 ] ...
  , 'color',            [ 255, 255, 255 ] ...
  , 'placement',        'center-left' ...
  , 'has_target',       false ...
  , 'non_editable',     non_editable_properties ...
);

STIMULI.setup.image2 = struct( ...
    'class',            'Image' ...
  , 'image_matrix',     [] ...
  , 'size',             [ 50, 50 ] ...
  , 'color',            [ 255, 255, 255 ] ...
  , 'placement',        'center-right' ...
  , 'has_target',       false ...
  , 'non_editable',     non_editable_properties ...
);

%	SERIAL
SERIAL = struct();
SERIAL.port = 'COM3';
SERIAL.channels = { 'A' };

% EXPORT
conf.PATHS = PATHS;
conf.DEPENDS = DEPENDS;
conf.TIMINGS = TIMINGS;
conf.STIMULI = STIMULI;
conf.SCREEN = SCREEN;
conf.INTERFACE = INTERFACE;
conf.SERIAL = SERIAL;

if ( do_save )
  hwwba.config.save( conf );
end

end