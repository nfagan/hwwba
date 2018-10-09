
function run_gaze_following(opts)

%   RUN -- Run the task based on the saved config file options.
%
%     IN:
%       - `opts` (struct)

INTERFACE =   opts.INTERFACE;
TIMER =       opts.TIMER;
STIMULI =     opts.STIMULI;
TRACKER =     opts.TRACKER;
WINDOW =      opts.WINDOW;
TIMINGS =     opts.TIMINGS;

%   begin in this state
cstate = 'gf_task_identity';
first_entry = true;

DATA = struct();
events = struct();
errors = struct();

P_CONSISTENT = 0.7;
BLOCK_SIZE = 10;

consistent_types = get_trial_types( P_CONSISTENT, BLOCK_SIZE );
TRIAL_IN_BLOCK = 1;

TRIAL_NUMBER = 0;

TIMER.add_timer( 'task', Inf );

tracker_sync = struct();
tracker_sync.timer = NaN;
tracker_sync.interval = 1;

stim_handles = rmfield( STIMULI, 'setup' );

while ( true )

  [key_pressed, ~, key_code] = KbCheck();

  if ( key_pressed )
    if ( key_code(INTERFACE.stop_key) ), break; end
  end
  
  if ( isnan(tracker_sync.timer) || toc(tracker_sync.timer) >= tracker_sync.interval )
    TRACKER.send( 'RESYNCH' );
    tracker_sync.timer = tic();
  end

  TRACKER.update_coordinates();
  structfun( @(x) x.update_targets(), stim_handles );
  
  %   STATE task_identity  
  if ( strcmp(cstate, 'gf_task_identity') )
    if ( first_entry )
      TIMER.reset_timers( cstate );
      drew_identity_cue = false;
      first_entry = false;
    end
    
    if ( ~drew_identity_cue )
      cue = STIMULI.gf_task_identity_cue;
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
      DATA(tn).delay = current_delay;
      DATA(tn).look_direction = current_look_direction;
      DATA(tn).trial_type = current_trial_type;
      DATA(tn).image_file = current_image_file;
    end
    
    no_errors = ~any( structfun(@(x) x, errors) );
    
    if ( no_errors )
      is_right = rand() > 0.5;

      if ( is_right )
        current_look_direction = 'center-right';
      else
        current_look_direction = 'center-left';
      end
    end
    
    delays = TIMINGS.delays.gf_pre_target_delay;
    current_delay = delays( randi(numel(delays)) );
    
    current_trial_type_logical = consistent_types(TRIAL_IN_BLOCK);
    
    if ( current_trial_type_logical )
      current_trial_type = 'consistent';
    else
      current_trial_type = 'inconsistent';
    end
    
    events = structfun( @(x) nan, events, 'un', 0 );
    errors = structfun( @(x) false, errors, 'un', 0 );
    
    current_image_file = configure_images( ...
      STIMULI.gf_image1, STIMULI.setup.image_info.gf, current_look_direction ...
    );
  
    LOG_DEBUG(['Current trial type is: ', current_trial_type], 'param');
    LOG_DEBUG(['Current delay is:      ', num2str(current_delay)], 'param');
    LOG_DEBUG(['Current file is:       ', current_image_file], 'param');
    LOG_DEBUG(['Current direction is:  ', current_look_direction], 'param');
    
    TRIAL_NUMBER = TRIAL_NUMBER + 1;
    
    if ( no_errors )
      TRIAL_IN_BLOCK = TRIAL_IN_BLOCK + 1;
    end
    
    if ( TRIAL_IN_BLOCK > BLOCK_SIZE )
      TRIAL_IN_BLOCK = 1;
      consistent_types = consistent_types( randperm(BLOCK_SIZE) );
    end
    
    cstate = 'gf_fixation';
    first_entry = true;
  end

  %   STATE gf_fixation
  if ( strcmp(cstate, 'gf_fixation') )
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
      fix_square.color = STIMULI.gf_task_identity_cue.color;
      fix_square.draw();
      Screen( 'flip', WINDOW.index );
      events.fixation_onset = TIMER.get_time( 'task' );
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
      events.fixation_acquired = TIMER.get_time( 'task' );
      acquired_target = true;
      cstate = 'gf_present_image';
      first_entry = true;
    end

    if ( TIMER.duration_met(cstate) && ~acquired_target )
      errors.fixation_not_met = true;
      cstate = 'new_trial';
      first_entry = true;
    end
  end
  
  %   STATE gf_present_image
  if ( strcmp(cstate, 'gf_present_image') )
    if ( first_entry )
      LOG_DEBUG(['Entered ', cstate], 'entry');
      Screen( 'flip', WINDOW.index );
      TIMER.reset_timers( cstate );
       
      image_stims = { STIMULI.gf_image1; };
      
      cellfun( @(x) x.reset_targets(), image_stims );
      drew_stimulus = false;
      first_entry = false;
    end
    
    if ( ~drew_stimulus )
      cellfun( @(x) x.draw(), image_stims );
      Screen( 'flip', WINDOW.index );
      events.images_on = TIMER.get_time( 'task' );
      drew_stimulus = true;
    end
    
    if ( TIMER.duration_met(cstate) )
      cstate = 'gf_pre_target_delay';
      first_entry = true;
    end
  end
  
  %   STATE gf_pre_target_delay
  if ( strcmp(cstate, 'gf_pre_target_delay') )
    if ( first_entry )
      LOG_DEBUG(['Entered ', cstate], 'entry');
      TIMER.reset_timers( cstate );
      TIMER.set_durations( cstate, current_delay );
      
      image_stims = { STIMULI.gf_image1 };
      
      cellfun( @(x) x.reset_targets(), image_stims );
      drew_stimulus = false;
      first_entry = false;
    end
    
    if ( TIMER.duration_met(cstate) )
      cstate = 'gf_response';
      first_entry = true;
    end
  end
  
  %   STATE gf_response
  if ( strcmp(cstate, 'gf_response') )
    if ( first_entry )
      LOG_DEBUG(['Entered ', cstate], 'entry');
      TIMER.reset_timers( cstate );
      
      errors.broke_target_fixation = false;
      errors.target_fixation_not_met = false;
      
      response_target = STIMULI.gf_response1;
      image_stims = { response_target };
      
      response_target.put( current_look_direction );
      
      cellfun( @(x) x.reset_targets(), image_stims );
      drew_stimulus = false;
      looked_to_target = false;
      
      first_entry = false;
    end
    
    if ( ~drew_stimulus )
      cellfun( @(x) x.draw(), image_stims );
      Screen( 'flip', WINDOW.index );
      events.images_on = TIMER.get_time( 'task' );
      drew_stimulus = true;
    end
    
    if ( response_target.in_bounds() )
      looked_to_target = true;
    elseif ( looked_to_target )
      errors.broke_target_fixation = true;
      cstate = 'gf_target_error';
      first_entry = true;
      continue;
    end
    
    if ( response_target.duration_met() )
      cstate = 'gf_reward';
      first_entry = true;
      continue;
    end
    
    if ( TIMER.duration_met(cstate) )
      errors.target_fixation_not_met = true;
      cstate = 'gf_target_error';
      first_entry = true;
    end
  end
  
  %   STATE gf_target_error
  if ( strcmp(cstate, 'gf_target_error') )
    if ( first_entry )
      LOG_DEBUG(['Entered ', cstate], 'entry');
      TIMER.reset_timers( cstate );
      events.reward_on = TIMER.get_time( 'task' );
      Screen( 'flip', WINDOW.index );
      drew_error = false;
      first_entry = false;
    end
    
    if ( ~drew_error )
      STIMULI.generic_error.draw();
      Screen( 'flip', WINDOW.index );
      drew_error = true;
    end
    
    if ( TIMER.duration_met(cstate) )
      cstate = 'new_trial';
      first_entry = true;
    end
  end
  
  %   STATE gf_reward
  if ( strcmp(cstate, 'gf_reward') )
    if ( first_entry )
      LOG_DEBUG(['Entered ', cstate], 'entry');
      TIMER.reset_timers( cstate );
      events.reward_on = TIMER.get_time( 'task' );
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
  save_p = fullfile( opts.PATHS.data, 'gf' );
  
  shared_utils.io.require_dir( save_p );
  
  edf_file = TRACKER.edf;
  
  save( fullfile(save_p, fname), 'DATA', 'opts', 'edf_file' );
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

function ts = get_trial_types(probability, block_size)

ts = zeros( block_size, 1 );
n_1 = round( block_size * probability );
true_inds = randperm( block_size, n_1 );
ts(true_inds) = true;

end

function name = configure_images(img1, image_info, look_direction)

if ( ~isa(img1, 'Image') )
  warning( 'Stimulus is not an image.' );
  return
end

images = image_info(:, end);
filenames = image_info(:, end-1);
image_directions = image_info(:, 1);

matches = cellfun( @(x) ~isempty(strfind(look_direction, x)), image_directions );

if ( sum(matches) ~= 1 )
  warning( 'No or more than one image matched look direction "%s"', look_direction );
  img1.image = images{1}{1};
  return;
end

matching_imgs = images{matches};
matching_filenames = filenames{matches};

img_ind = randi( numel(matching_imgs) );

img1.image = matching_imgs{img_ind};
name = matching_filenames{img_ind};

end
	