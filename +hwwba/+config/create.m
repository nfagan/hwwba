
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

% META
META = struct();
META.subject = '';
META.date = '';

% PATHS
PATHS = struct();
PATHS.repositories = fileparts( hwwba.util.get_project_folder() );
PATHS.stimuli = fullfile( hwwba.util.get_project_folder(), 'stimuli' );
PATHS.data = fullfile( hwwba.util.get_project_folder(), 'data' );

% DEPENDENCIES
DEPENDS = struct();
DEPENDS.repositories = { 'ptb_helpers', 'serial_comm', 'shared_utils' };

esc_key = try_get_escape_key();

%	INTERFACE
INTERFACE = struct();
INTERFACE.skip_sync_tests = false;
INTERFACE.stop_key = esc_key;
INTERFACE.use_mouse = true;
INTERFACE.use_reward = false;
INTERFACE.save_data = true;
INTERFACE.is_debug = false;
INTERFACE.debug_tags = { 'all' };
INTERFACE.gui_fields.exclude = { 'stop_key', 'debug_tags' };

%	SCREEN
SCREEN = struct();

SCREEN.full_size = get( 0, 'screensize' );
SCREEN.index = 0;
SCREEN.background_color = [ 0 0 0 ];
SCREEN.rect = [ 0, 0, 400, 400 ];

%	TIMINGS
TIMINGS = struct();

% ba
time_in = struct();
time_in.ba_task = Inf;
time_in.ba_fixation = 1;
time_in.ba_present_images = 1;
time_in.ba_reward = 0;
time_in.ba_task_identity = 3;
% ja
time_in.ja_task = Inf;
time_in.ja_fixation = 1;
time_in.ja_present_image = 1;
time_in.ja_response = 1;
time_in.ja_reward = 0;
time_in.ja_response_error = 1;
time_in.ja_task_identity = 3;
% ac
time_in.ac_task = Inf;
time_in.ac_fixation = 1;
time_in.ac_present_images = 1;
time_in.ac_reward = 0;
time_in.ac_response_error = 0;
time_in.ac_task_identity = 3;
% gf
time_in.gf_task = Inf;
time_in.gf_fixation = 1;
time_in.gf_present_image = 1;
time_in.gf_pre_target_delay = 1;
time_in.gf_response = 1;
time_in.gf_reward = 1;
time_in.gf_target_error = 1;
time_in.gf_task_identity = 3;
% sm
time_in.sm_task = Inf;
time_in.sm_fixation = 1;
time_in.sm_present_cue = 1;
time_in.sm_present_image = 1;
time_in.sm_reward = 1;
time_in.sm_cue_error = 1;
time_in.sm_task_identity = 3;

delays = struct();
delays.gf_pre_target_delay = 0.1:0.1:1;
delays.sm_cue_delay = 0.1:0.1:1;

TIMINGS.time_in = time_in;
TIMINGS.delays = delays;

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

STIMULI.setup.generic_error = struct( ...
    'class',            'Rectangle' ...
  , 'size',             [ 50, 50 ] ...
  , 'color',            [ 255, 0, 0 ] ...
  , 'placement',        'center' ...
  , 'has_target',       false ...
  , 'non_editable',     non_editable_properties ...
);

STIMULI.setup.ba_task_identity_cue = struct( ...
    'class',            'Rectangle' ...
  , 'size',             [ 50, 50 ] ...
  , 'color',            [ 255, 0, 0 ] ...
  , 'placement',        'center-right' ...
  , 'has_target',       false ...
  , 'non_editable',     non_editable_properties ...
);

STIMULI.setup.ba_image1 = struct( ...
    'class',            'Image' ...
  , 'image_matrix',     [] ...
  , 'size',             [ 50, 50 ] ...
  , 'color',            [ 255, 255, 255 ] ...
  , 'placement',        'center-left' ...
  , 'has_target',       false ...
  , 'non_editable',     non_editable_properties ...
);

STIMULI.setup.ba_image2 = struct( ...
    'class',            'Image' ...
  , 'image_matrix',     [] ...
  , 'size',             [ 50, 50 ] ...
  , 'color',            [ 255, 255, 255 ] ...
  , 'placement',        'center-right' ...
  , 'has_target',       false ...
  , 'non_editable',     non_editable_properties ...
);

%
%   JA
%

STIMULI.setup.ja_task_identity_cue = struct( ...
    'class',            'Rectangle' ...
  , 'size',             [ 50, 50 ] ...
  , 'color',            [ 255, 0, 0 ] ...
  , 'placement',        'center-right' ...
  , 'has_target',       false ...
  , 'non_editable',     non_editable_properties ...
);

STIMULI.setup.ja_image1 = struct( ...
    'class',            'Image' ...
  , 'image_matrix',     [] ...
  , 'size',             [ 50, 50 ] ...
  , 'color',            [ 255, 255, 255 ] ...
  , 'placement',        'center' ...
  , 'has_target',       false ...
  , 'non_editable',     non_editable_properties ...
);

STIMULI.setup.ja_response1 = struct( ...
    'class',            'Rectangle' ...
  , 'size',             [ 50, 50 ] ...
  , 'color',            [ 255, 255, 255 ] ...
  , 'shift',            [ 0, 0 ] ...
  , 'placement',        'center-left' ...
  , 'has_target',       true ...
  , 'target_duration',  0.3 ...
  , 'target_padding',   0 ...
  , 'non_editable',     non_editable_properties ...
);

STIMULI.setup.ja_response2 = struct( ...
    'class',            'Rectangle' ...
  , 'size',             [ 50, 50 ] ...
  , 'color',            [ 255, 255, 255 ] ...
  , 'shift',            [ 0, 0 ] ...
  , 'placement',        'center-right' ...
  , 'has_target',       true ...
  , 'target_duration',  0.3 ...
  , 'target_padding',   0 ...
  , 'non_editable',     non_editable_properties ...
);

STIMULI.setup.ja_response_frame = struct( ...
    'class',            'Rectangle' ...
  , 'size',             [ 50, 50 ] ...
  , 'color',            [ 255, 0, 0 ] ...
  , 'shift',            [ 0, 0 ] ...
  , 'placement',        'center-right' ...
  , 'has_target',       false ...
  , 'non_editable',     non_editable_properties ...
);

%
%   AC
%

STIMULI.setup.ac_task_identity_cue = struct( ...
    'class',            'Rectangle' ...
  , 'size',             [ 50, 50 ] ...
  , 'color',            [ 255, 0, 0 ] ...
  , 'placement',        'center-right' ...
  , 'has_target',       false ...
  , 'non_editable',     non_editable_properties ...
);

STIMULI.setup.ac_image1 = struct( ...
    'class',            'Image' ...
  , 'image_matrix',     [] ...
  , 'size',             [ 50, 50 ] ...
  , 'color',            [ 255, 255, 255 ] ...
  , 'shift',            [ 0, 0 ] ...
  , 'placement',        'center' ...
  , 'has_target',       false ...
  , 'non_editable',     non_editable_properties ...
);

STIMULI.setup.ac_response1 = struct( ...
    'class',            'Rectangle' ...
  , 'image_matrix',     [] ...
  , 'size',             [ 50, 50 ] ...
  , 'color',            [ 255, 255, 255 ] ...
  , 'placement',        'center-right' ...
  , 'shift',            [ 100, 0 ] ...
  , 'has_target',       true ...
  , 'target_duration',  0.3 ...
  , 'target_padding',   50 ...
  , 'non_editable',     non_editable_properties ...
);

%
%   GF
%

STIMULI.setup.gf_task_identity_cue = struct( ...
    'class',            'Rectangle' ...
  , 'size',             [ 50, 50 ] ...
  , 'color',            [ 255, 0, 0 ] ...
  , 'placement',        'center-right' ...
  , 'has_target',       false ...
  , 'non_editable',     non_editable_properties ...
);

STIMULI.setup.gf_image1 = struct( ...
    'class',            'Image' ...
  , 'image_matrix',     [] ...
  , 'size',             [ 50, 50 ] ...
  , 'color',            [ 255, 255, 255 ] ...
  , 'placement',        'center' ...
  , 'has_target',       false ...
  , 'non_editable',     non_editable_properties ...
);

STIMULI.setup.gf_response1 = struct( ...
    'class',            'Rectangle' ...
  , 'size',             [ 50, 50 ] ...
  , 'color',            [ 255, 255, 255 ] ...
  , 'placement',        'center-right' ...
  , 'shift',            [ 0, 0 ] ...
  , 'has_target',       true ...
  , 'target_duration',  0.3 ...
  , 'target_padding',   50 ...
  , 'non_editable',     non_editable_properties ...
);

%
%   SM
%

STIMULI.setup.sm_cue1 = struct( ...
    'class',            'Image' ...
  , 'image_matrix',     [] ...
  , 'size',             [ 50, 50 ] ...
  , 'color',            [ 255, 255, 255 ] ...
  , 'placement',        'center' ...
  , 'has_target',       true ...
  , 'target_duration',  0.3 ...
  , 'target_padding',   50 ...
  , 'non_editable',     non_editable_properties ...
);

STIMULI.setup.sm_image1 = struct( ...
    'class',            'Image' ...
  , 'image_matrix',     [] ...
  , 'size',             [ 50, 50 ] ...
  , 'color',            [ 255, 255, 255 ] ...
  , 'placement',        'center' ...
  , 'has_target',       false ...
  , 'non_editable',     non_editable_properties ...
);

STIMULI.setup.sm_task_identity_cue = struct( ...
    'class',            'Rectangle' ...
  , 'size',             [ 50, 50 ] ...
  , 'color',            [ 255, 0, 0 ] ...
  , 'placement',        'center-right' ...
  , 'has_target',       false ...
  , 'non_editable',     non_editable_properties ...
);

% REWARDS
REWARDS = struct();
REWARDS.key_press = 100;
REWARDS.main = 100;
REWARDS.sm_main = 100;
REWARDS.ac_main = 100;
REWARDS.ba_main = 100;
REWARDS.ja_main = 100;
REWARDS.gf_main = 100;

%	SERIAL
SERIAL = struct();
SERIAL.port = 'COM3';
SERIAL.channels = { 'A' };

% TASK_ORDER
TASK_ORDER = struct();
TASK_ORDER.ac = 1;
TASK_ORDER.ba = 2;
TASK_ORDER.gf = 3;
TASK_ORDER.ja = 4;
TASK_ORDER.sm = 5;

% STRUCTURE
STRUCTURE = struct();
STRUCTURE.gf_p_consistent = 0.7;
STRUCTURE.ja_p_right = 0.5;
STRUCTURE.ja_persist_correct_option = false;

% EXPORT
conf.META = META;
conf.PATHS = PATHS;
conf.DEPENDS = DEPENDS;
conf.TIMINGS = TIMINGS;
conf.STIMULI = STIMULI;
conf.SCREEN = SCREEN;
conf.INTERFACE = INTERFACE;
conf.SERIAL = SERIAL;
conf.REWARDS = REWARDS;
conf.TASK_ORDER = TASK_ORDER;
conf.STRUCTURE = STRUCTURE;

if ( do_save )
  hwwba.config.save( conf );
end

end

function esc_key = try_get_escape_key()

try
  esc_key = KbName( 'escape' );
catch err1
  try
    KbName( 'UnifyKeyNames' );
    esc_key = KbName( 'escape' );
  catch err2
    warning( err2.message );
    esc_key = 27;
  end
end

end