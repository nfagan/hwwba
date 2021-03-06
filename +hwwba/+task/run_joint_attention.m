
function run_joint_attention(opts)

%   RUN -- Run the task based on the saved config file options.
%
%     IN:
%       - `opts` (struct)

INTERFACE =   opts.INTERFACE;
TIMER =       opts.TIMER;
STIMULI =     opts.STIMULI;
TRACKER =     opts.TRACKER;
WINDOW =      opts.WINDOW;
STRUCTURE =   opts.STRUCTURE;
comm =        opts.SERIAL.comm;
textures =    opts.TEXTURES;

%   begin in this state
cstate = 'ja_task_identity';
first_entry = true;

DATA = struct();
PERFORMANCE = struct();
PERFORMANCE.by_image_type = containers.Map();

events = struct();
errors = struct();

TRIAL_NUMBER = 0;

TIMER.add_timer( 'task', Inf );

tracker_sync = hwwba.util.make_tracker_sync();

stim_handles = rmfield( STIMULI, 'setup' );

% reset task timer
TASK_TIMER_NAME = 'ja_task';
TIMER.reset_timers( TASK_TIMER_NAME );

task_timer_id = TIMER.get_underlying_id( TASK_TIMER_NAME );
task_time_limit = opts.TIMINGS.time_in.ja_task;
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
  if ( strcmp(cstate, 'ja_task_identity') )
    if ( first_entry )
      TIMER.reset_timers( cstate );
      drew_identity_cue = false;
      first_entry = false;
    end
    
    if ( ~drew_identity_cue )
      cue = STIMULI.ja_task_identity_cue;
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
    
    LOG_DEBUG(['Entered ', cstate], 'entry');
    
    if ( TRIAL_NUMBER > 0 )
      tn = TRIAL_NUMBER;
      
      DATA(tn).events = events;
      DATA(tn).errors = errors;
      DATA(tn).response_direction = ja_response_direction;
      DATA(tn).image_look_direction = current_look_direction;
      DATA(tn).image_filename = image_filename;
      
      clc;
      print_performance( DATA(tn), PERFORMANCE, tn );
    end
    
    no_errors = ~any( structfun(@(x) x, errors) );
    
    if ( rand() > STRUCTURE.ja_p_right )
      current_look_direction = 'left';
      correct_stimulus = STIMULI.ja_response1;
    else
      current_look_direction = 'right';
      correct_stimulus = STIMULI.ja_response2;
    end

    img = STIMULI.ja_image1;
    img_info = STIMULI.setup.image_info.ja;
    image_filename = configure_images( img, img_info, current_look_direction, textures );

    LOG_DEBUG( sprintf('Look direction: %s', current_look_direction), 'param' );
    
    events = structfun( @(x) nan, events, 'un', 0 );
    errors = structfun( @(x) false, errors, 'un', 0 );
    ja_response_direction = '';
    
    TRIAL_NUMBER = TRIAL_NUMBER + 1;
    
    cstate = 'ja_fixation';
    first_entry = true;
  end

  %   STATE ja_fixation
  if ( strcmp(cstate, 'ja_fixation') )
    if ( first_entry )
      LOG_DEBUG(['Entered ', cstate], 'entry');
      Screen( 'flip', WINDOW.index );
      TIMER.reset_timers( cstate );
      fix_square = STIMULI.fix_square;
      fix_square.reset_targets();
      acquired_target = false;
      looked_to_target = false;
      drew_stimulus = false;
      errors.broke_fixation = false;
      errors.fixation_not_met = false;
      first_entry = false;
    end

    fix_square.update_targets();

    if ( ~drew_stimulus )
      fix_square.color = STIMULI.ja_task_identity_cue.color;
      fix_square.draw();
      Screen( 'flip', WINDOW.index );
      events.fixation_onset = TIMER.get_time( TASK_TIMER_NAME );
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
      events.fixation_acquired = TIMER.get_time( TASK_TIMER_NAME );
      acquired_target = true;
      cstate = 'ja_response';
      first_entry = true;
    end

    if ( TIMER.duration_met(cstate) && ~acquired_target )
      errors.fixation_not_met = true;
      cstate = 'new_trial';
      first_entry = true;
    end
  end
  
  %   STATE ja_present_image
  if ( strcmp(cstate, 'ja_present_image') )
    if ( first_entry )
      LOG_DEBUG(['Entered ', cstate], 'entry');
      Screen( 'flip', WINDOW.index );
      TIMER.reset_timers( cstate );
      
      image_stims = { STIMULI.ja_image1 };
      
      cellfun( @(x) x.reset_targets(), image_stims );
      drew_stimulus = false;
      first_entry = false;
    end
    
    if ( ~drew_stimulus )
      cellfun( @(x) x.draw(), image_stims );
      Screen( 'flip', WINDOW.index );
      events.images_on = TIMER.get_time( TASK_TIMER_NAME );
      drew_stimulus = true;
    end
    
    if ( TIMER.duration_met(cstate) )
      cstate = 'ja_response';
      first_entry = true;
    end
  end
  
  %   STATE ja_response
  if ( strcmp(cstate, 'ja_response') )
    if ( first_entry )
      LOG_DEBUG(['Entered ', cstate], 'entry');
      Screen( 'flip', WINDOW.index );
      TIMER.reset_timers( cstate );
      
      ja_response1 = STIMULI.ja_response1;
      left_shift = opts.STIMULI.setup.ja_response1.shift;
      ja_response1.put( 'center-left' );
      ja_response1.shift( left_shift(1), left_shift(2) );
      
      ja_response2 = STIMULI.ja_response2;
      right_shift = opts.STIMULI.setup.ja_response2.shift;
      ja_response2.put( 'center-right' );
      ja_response2.shift( right_shift(1), right_shift(2) );
      
      stims = { STIMULI.ja_response1, STIMULI.ja_response2, STIMULI.ja_image1 };
      
      ja_response_direction = '';
      looked_to = '';
      
      errors.no_response = false;
      errors.broke_target_fixation = false;
      
      cellfun( @(x) x.reset_targets(), stims );
      drew_stimulus = false;
      first_entry = false;
    end
    
    if ( ~drew_stimulus )
      cellfun( @(x) x.draw(), stims );
      Screen( 'flip', WINDOW.index );
      events.response_targets_on = TIMER.get_time( TASK_TIMER_NAME );
      drew_stimulus = true;
    end
    
    for i = 1:2
      if ( ~stims{i}.in_bounds() )
        if ( ~isempty(looked_to) && strcmp(looked_to, stims{i}.placement) )
          ja_response_direction = '';
          errors.broke_target_fixation = true;
          cstate = 'ja_response_error';
          continue;
        end
      else
        looked_to = stims{i}.placement;
      end
    end
    
    if ( stims{1}.duration_met() )
      ja_response_direction = stims{1}.placement;
    elseif ( stims{2}.duration_met() )
      ja_response_direction = stims{2}.placement;
    end
    
    if ( ~isempty(ja_response_direction) )
      LOG_DEBUG( ['Chose: ', ja_response_direction, 'Correct: ', current_look_direction], 'response' );
      
      if ( ~isempty(strfind(ja_response_direction, current_look_direction)) )
        cstate = 'ja_reward';
        errors.incorrect_look_direction = false;
      else
        errors.incorrect_look_direction = true;
        cstate = 'ja_response_error';
      end
      
      first_entry = true;
      continue;
    end
    
    if ( TIMER.duration_met(cstate) )
      errors.no_response = true;
      cstate = 'ja_response_error';
      first_entry = true;
    end
  end
  
  %   STATE ja_reward
  if ( strcmp(cstate, 'ja_reward') )
    if ( first_entry )
      LOG_DEBUG(['Entered ', cstate], 'entry');
      events.reward_on = TIMER.get_time( TASK_TIMER_NAME );
      TIMER.reset_timers( cstate );
      Screen( 'flip', WINDOW.index );
      
      comm.reward( 1, opts.REWARDS.ja_main );
      
      drew_stimuli = false;
      first_entry = false;
    end
    
    if ( STRUCTURE.ja_persist_correct_option && ~drew_stimuli )
      correct_stimulus.draw();
      STIMULI.ja_image1.draw();
      Screen( 'flip', WINDOW.index );
      
      drew_stimuli = true;
    end
    
    if ( TIMER.duration_met(cstate) )
      cstate = 'new_trial';
      first_entry = true;
    end
  end
  
  %   STATE ja_response_error
  if ( strcmp(cstate, 'ja_response_error') )
    if ( first_entry )
      LOG_DEBUG(['Entered ', cstate], 'entry');
      events.ja_response_error = TIMER.get_time( TASK_TIMER_NAME );
      TIMER.reset_timers( cstate );
      Screen( 'flip', WINDOW.index );
      response_frame = STIMULI.ja_response_frame;
      first_entry = false;
      drew_stimuli = false;
      triggered_bridge_reward = false;
    end
    
    if ( STRUCTURE.ja_persist_correct_option && ~drew_stimuli )
      configure_response_frame( response_frame, correct_stimulus, 1.5 );
      
      response_frame.draw_frame();
      
      correct_stimulus.draw();
      STIMULI.ja_image1.draw();
      Screen( 'flip', WINDOW.index );
      
      drew_stimuli = true;
    end
    
    if ( STRUCTURE.ja_persist_correct_option )
      if ( correct_stimulus.in_bounds() && ~triggered_bridge_reward )
        comm.reward( 1, opts.REWARDS.ja_bridge );
        triggered_bridge_reward = true;
      end
    end
    
    if ( TIMER.duration_met(cstate) )
      cstate = 'new_trial';
      first_entry = true;
    end
  end
  
end

if ( opts.INTERFACE.save_data )
  fname = sprintf( '%s.mat', strrep(datestr(now), ':', '_') );
  save_p = fullfile( opts.PATHS.data, 'ja' );
  
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

function configure_response_frame(response_frame, correct_stim, scale)

correct_verts = correct_stim.vertices;

cx = mean( correct_verts([1, 3]) );
cy = mean( correct_verts([2, 4]) );

w = correct_verts(3) - correct_verts(1);
h = correct_verts(4) - correct_verts(2);

new_w = w * scale;
new_h = h * scale;

response_frame.vertices = [ cx-new_w/2, cy-new_h/2, cx+new_w/2, cy+new_h/2 ];
response_frame.pen_width = 16;

end

function name = configure_images(img1, image_info, look_direction, textures)

name = '';

images = image_info(:, end);
directions = image_info(:, 1);
filenames = image_info(:, end-1);

if ( ~isa(img1, 'Image') )
  disp( 'WARN: Image 1 is not an image.' );
  return  
end

dir_ind = strcmp( directions, look_direction );

assert( sum(dir_ind) == 1, 'More or fewer than 1 direction matched "%s".', look_direction );

matching_images = images{dir_ind};
matching_files = filenames{dir_ind};

img_ind = randi( numel(matching_files) );

img1.image = matching_images{img_ind};
img1.set_texture_handle(textures(matching_files{img_ind}));

name = matching_files{img_ind};

end

function print_performance(data, perf, total_trials)

image_type = data.image_look_direction;

initiated_func = @(data) ~data.errors.broke_fixation && ~data.errors.fixation_not_met;

hwwba.util.print_performance( data, perf.by_image_type, total_trials ...
  , image_type, true, initiated_func );

end
	