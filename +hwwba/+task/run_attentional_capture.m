
function run_attentional_capture(opts)

%   RUN -- Run the task based on the saved config file options.
%
%     IN:
%       - `opts` (struct)

INTERFACE =   opts.INTERFACE;
TIMER =       opts.TIMER;
STIMULI =     opts.STIMULI;
TRACKER =     opts.TRACKER;
WINDOW =      opts.WINDOW;
comm =        opts.SERIAL.comm;
textures =    opts.TEXTURES;

%   begin in this state
cstate = 'ac_task_identity';
first_entry = true;

DATA = struct();
PERFORMANCE = struct();
PERFORMANCE.by_image_type = containers.Map();

events = struct();
errors = struct();

image_info = STIMULI.setup.image_info.ac;
image_types = unique( image_info(:, 1) );

TRIAL_NUMBER = 0;
TRIAL_IN_BLOCK = 1;

TIMER.add_timer( 'task', Inf );

tracker_sync = hwwba.util.make_tracker_sync();

stim_handles = rmfield( STIMULI, 'setup' );

% reset task timer
TASK_TIMER_NAME = 'ac_task';
TIMER.reset_timers( TASK_TIMER_NAME );

task_timer_id = TIMER.get_underlying_id( TASK_TIMER_NAME );
task_time_limit = opts.TIMINGS.time_in.ac_task;
stop_key = INTERFACE.stop_key;

key_press_reward_manager = ...
  hwwba.util.make_key_press_reward_manager( comm, 1, opts.REWARDS.key_press );

while ( hwwba.util.task_should_continue(task_timer_id, task_time_limit, stop_key) )

  [key_pressed, ~, key_code] = KbCheck();

  if ( key_pressed )
    if ( key_code(INTERFACE.stop_key) ), break; end
  end
  
  if ( isnan(tracker_sync.timer) || toc(tracker_sync.timer) >= tracker_sync.interval )
    TRACKER.send( 'RESYNCH' );
    tracker_sync = hwwba.util.update_tracker_sync( tracker_sync, TIMER.get_time(TASK_TIMER_NAME) );
  end

  TRACKER.update_coordinates();
  structfun( @(x) x.update_targets(), stim_handles );
  
  key_press_reward_manager.update();
  
  %   STATE task_identity  
  if ( strcmp(cstate, 'ac_task_identity') )
    if ( first_entry )
      TIMER.reset_timers( cstate );
      drew_identity_cue = false;
      first_entry = false;
    end
    
    if ( ~drew_identity_cue )
      cue = STIMULI.ac_task_identity_cue;
      cue.put( 'center' );
      cue.draw()
      Screen( 'flip', opts.WINDOW.index );
      drew_identity_cue = true;
    end
    
    if ( TIMER.duration_met(cstate) )
      cstate = 'new_trial';
      first_entry = true;
    end
  end

  %   STATE new_trial
  if ( strcmp(cstate, 'new_trial') )    
    Screen( 'FillRect', opts.WINDOW.index, [0, 0, 0], Screen('Rect', opts.WINDOW.index) );
    
    if ( TRIAL_NUMBER > 0 )
      tn = TRIAL_NUMBER;
      
      DATA(tn).events = events;
      DATA(tn).errors = errors;
      DATA(tn).image_type = image_type;
      DATA(tn).image_file = image_file;
      DATA(tn).target_placement = target_placement;
      
      clc;
      print_performance( DATA(tn), PERFORMANCE, tn );
    end
    
    no_errors = ~any( structfun(@(x) x, errors) );
    
    if ( no_errors )
      image_type = image_types{TRIAL_IN_BLOCK};
      image_file = configure_images( STIMULI.ac_image1, image_info, image_type, textures );
    
      TRIAL_IN_BLOCK = TRIAL_IN_BLOCK + 1;

      if ( TRIAL_IN_BLOCK > numel(image_types) )
        TRIAL_IN_BLOCK = 1;
        image_types = image_types( randperm(numel(image_types)) );
      end
      
      if ( rand() > 0.5 )
        target_placement = 'center-left';
        target_x_shift = -abs( STIMULI.setup.ac_response1.shift(1) );
      else
        target_placement = 'center-right';
        target_x_shift = abs( STIMULI.setup.ac_response1.shift(1) );
      end
    end
    
    LOG_DEBUG( sprintf('image type: %s', image_type), 'param' );
    LOG_DEBUG( sprintf('image file: %s', image_file), 'param' );
    
    STIMULI.ac_image1.put( 'center' );
    
    events = structfun( @(x) nan, events, 'un', 0 );
    errors = structfun( @(x) false, errors, 'un', 0 );
    
    TRIAL_NUMBER = TRIAL_NUMBER + 1;
    
    cstate = 'ac_fixation';
    first_entry = true;
  end

  %   STATE ac_fixation
  if ( strcmp(cstate, 'ac_fixation') )
    if ( first_entry )
      LOG_DEBUG(['Entered ', cstate]);
      Screen( 'flip', WINDOW.index );
      TIMER.reset_timers( cstate );
      fix_square = STIMULI.fix_square;
      fix_square.reset_targets();
      acquired_target = false;
      looked_to_target = false;
      drew_stimulus = false;
      
      errors.broke_fixation = false;
      errors.fixation_not_met = false;
      
      events.(cstate) = TIMER.get_time( TASK_TIMER_NAME );
      
      first_entry = false;
    end

    fix_square.update_targets();

    if ( ~drew_stimulus )
      fix_square.color = STIMULI.ac_task_identity_cue.color;
      fix_square.draw();
      Screen( 'flip', WINDOW.index );
      events.ac_fixation_onset = TIMER.get_time( TASK_TIMER_NAME );
      drew_stimulus = true;
    end
    
    if ( fix_square.in_bounds() )
      looked_to_target = true;
    elseif ( looked_to_target )
      errors.broke_fixation = true;
      cstate = 'new_trial';
      first_entry = true;
      continue;
    end

    if ( fix_square.duration_met() )
      events.ac_fixation_acquired = TIMER.get_time( TASK_TIMER_NAME );
      acquired_target = true;
      cstate = 'ac_present_images';
      first_entry = true;
    end

    if ( TIMER.duration_met(cstate) && ~acquired_target )
      errors.fixation_not_met = true;
      cstate = 'new_trial';
      first_entry = true;
    end
  end
  
  %   STATE ac_present_images
  if ( strcmp(cstate, 'ac_present_images') )
    if ( first_entry )
      LOG_DEBUG(['Entered ', cstate]);
      Screen( 'flip', WINDOW.index );
      TIMER.reset_timers( cstate );
      
      events.(cstate) = TIMER.get_time( TASK_TIMER_NAME );
      
      response_stim = STIMULI.ac_response1;
      image_stims = { STIMULI.ac_image1, response_stim };
      
      response_stim.put( target_placement );
      response_stim.shift( target_x_shift, STIMULI.setup.ac_response1.shift(2) );
      
      cellfun( @(x) x.reset_targets(), image_stims );
      drew_stimulus = false;
      looked_to_target = false;
      first_entry = false;
    end
    
    if ( ~drew_stimulus )
      cellfun( @(x) x.draw(), image_stims );
      Screen( 'flip', WINDOW.index );
      events.ac_images_on = TIMER.get_time( TASK_TIMER_NAME );
      drew_stimulus = true;
    end
    
    if ( response_stim.in_bounds() )
      if ( ~looked_to_target )
        events.ac_entered_target = TIMER.get_time( TASK_TIMER_NAME );
      end
      
      looked_to_target = true;
    elseif ( looked_to_target )
      cstate = 'ac_response_error';
      errors.broke_target_fixation = true;
      first_entry = true;
      continue;
    end
    
    if ( response_stim.duration_met() )
      cstate = 'ac_reward';
      first_entry = true;
      continue;
    end
    
    if ( TIMER.duration_met(cstate) && ~looked_to_target )
      cstate = 'ac_response_error';
      first_entry = true;
    end
  end
  
  %   STATE ac_reward
  if ( strcmp(cstate, 'ac_reward') )
    if ( first_entry )
      LOG_DEBUG(['Entered ', cstate]);
      events.ac_reward_on = TIMER.get_time( TASK_TIMER_NAME );
      TIMER.reset_timers( cstate );
      
      comm.reward( 1, opts.REWARDS.ac_main );
            
      Screen( 'flip', WINDOW.index );
      first_entry = false;
    end
    
    if ( TIMER.duration_met(cstate) )
      cstate = 'new_trial';
      first_entry = true;
    end
  end
  
  %   STATE ac_response_error
  if ( strcmp(cstate, 'ac_response_error') )
    if ( first_entry )
      LOG_DEBUG(['Entered ', cstate]);
      events.(cstate) = TIMER.get_time( TASK_TIMER_NAME );
      TIMER.reset_timers( cstate );
            
      Screen( 'flip', WINDOW.index );
      first_entry = false;
    end
    
    if ( TIMER.duration_met(cstate) )
      cstate = 'new_trial';
      first_entry = true;
    end
  end
  
end

if ( opts.INTERFACE.save_data )
  fname = sprintf( '%s.mat', strrep(datestr(now), ':', '_') );
  save_p = fullfile( opts.PATHS.data, 'ac' );
  
  shared_utils.io.require_dir( save_p );
  
  edf_file = TRACKER.edf;
  perf_func = @print_performance;
  
  save( fullfile(save_p, fname), 'DATA', 'opts', 'edf_file' ...
    , 'tracker_sync', 'PERFORMANCE', 'perf_func' );
end

TRACKER.shutdown();

function LOG_DEBUG(msg, tag)
  if ( ~opts.INTERFACE.is_debug )
    return;
  end
  
  if ( nargin < 2 )
    should_display = true;
  else
    tags = opts.INTERFACE.debug_tags;
    is_all = numel(tags) == 1 && strcmp( tags, 'all' );
    should_display =  is_all || ismember( tag, tags );
  end
  
  if ( should_display )
    fprintf( '\n%s', msg );
  end
end

end

function file = configure_images(img1, image_info, image_type, textures)

file = '';

images = image_info(:, end);
image_files = image_info(:, end-1);

if ( ~isa(img1, 'Image') )
  disp( 'WARN: Image 1 is not an image.' );
  return
end

image_types = image_info(:, 1);

ind = strcmp( image_types, image_type );

assert( sum(ind) > 0, 'No image types matched "%s".', image_type );

ind = find( ind );
use_ind = ind( randi(numel(ind)) );

img1.image = images{use_ind}{1};
file = image_files{use_ind}{1};
img1.set_texture_handle( textures(file) );

end
	
function print_performance(data, perf, total_trials)

image_type = data.image_type;

if ( strncmpi(image_type, 'eyes', numel('eyes')) )
  image_type = 'eyes';
elseif ( strncmpi(image_type, 'mouth', numel('mouth')) )
  image_type = 'mouth';
elseif ( strncmpi(image_type, 'scrambled', numel('scrambled')) )
  image_type = 'scrambled';
else
  image_type = 'unknown';
end

image_type = sprintf( '%s / %s', image_type, data.target_placement );

initiated_func = @(data) ~data.errors.broke_fixation && ~data.errors.fixation_not_met;

hwwba.util.print_performance( data, perf.by_image_type, total_trials ...
  , image_type, true, initiated_func );

end