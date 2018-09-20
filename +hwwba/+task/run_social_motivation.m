
function run_social_motivation(opts)

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
comm =        opts.SERIAL.comm;

%   begin in this state
cstate = 'new_trial';
first_entry = true;

DATA = struct();
events = struct();
errors = struct();

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

  %   STATE new_trial
  if ( strcmp(cstate, 'new_trial') )
    LOG_DEBUG(['Entered ', cstate], 'entry');
    
    if ( TRIAL_NUMBER > 0 )
      tn = TRIAL_NUMBER;
      
      DATA(tn).events = events;
      DATA(tn).errors = errors;
      DATA(tn).trial_type = trial_type;
      DATA(tn).cue_delay = current_delay;
      DATA(tn).cue_name = cue_name;
      DATA(tn).cued_image_name = cued_image_name;
    end
    
    no_errors = ~any( structfun(@(x) x, errors) );
    
    if ( no_errors )
      if ( rand() > 0.5 )
        trial_type = 'social';
      else
        trial_type = 'nonsocial';
      end
      
      delays = TIMINGS.delays.sm_cue_delay;
      current_delay = delays( randperm(numel(delays), 1) );
      
      image_info = STIMULI.setup.image_info.sm;
      cue_name = configure_cue( STIMULI.sm_cue1, image_info, trial_type );
      cued_image_name = configure_cued_image( STIMULI.sm_image1, image_info, trial_type );
      
      LOG_DEBUG( sprintf('trial_type: %s', trial_type), 'param' );
      LOG_DEBUG( sprintf('delay:      %0.1f', current_delay), 'param' );
      LOG_DEBUG( sprintf('cue_name:   %s', cue_name), 'param' );
      LOG_DEBUG( sprintf('cued_image  %s', cued_image_name), 'param' );
    end
    
    events = structfun( @(x) nan, events, 'un', 0 );
    errors = structfun( @(x) false, errors, 'un', 0 );
    
    TRIAL_NUMBER = TRIAL_NUMBER + 1;
    
    cstate = 'sm_fixation';
    first_entry = true;
  end

  %   STATE sm_fixation
  if ( strcmp(cstate, 'sm_fixation') )
    if ( first_entry )
      LOG_DEBUG(['Entered ', cstate], 'entry');
      Screen( 'flip', WINDOW.index );
      TIMER.reset_timers( cstate );
      fix_square = STIMULI.fix_square;
      fix_square.reset_targets();
      acquired_target = false;
      looked_to_target = false;
      drew_stimulus = false;
      
      events.(cstate) = TIMER.get_time( 'task' );
      
      errors.broke_fixation = false;
      errors.fixation_not_met = false;
      
      first_entry = false;
    end

    fix_square.update_targets();

    if ( ~drew_stimulus )
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
      cstate = 'sm_present_cue';
      first_entry = true;
    end

    if ( TIMER.duration_met(cstate) && ~acquired_target )
      errors.fixation_not_met = true;
      cstate = 'new_trial';
      first_entry = true;
    end
  end
  
  %   STATE sm_present_cue
  if ( strcmp(cstate, 'sm_present_cue') )
    if ( first_entry )
      LOG_DEBUG(['Entered ', cstate], 'entry');
      Screen( 'flip', WINDOW.index );
      TIMER.reset_timers( cstate );
       
      cue = STIMULI.sm_cue1;
      cue.targets{1}.duration = current_delay;
      
      stims = { cue };
      cellfun( @(x) x.reset_targets(), stims );
      
      drew_stimulus = false;
      looked_to_cue = false;
      
      events.(cstate) = TIMER.get_time( 'task' );
      
      errors.broke_cue_fixation = false;
      errors.cue_fixation_not_met = false;
      
      first_entry = false;
    end
    
    if ( cue.in_bounds() )
      looked_to_cue = true;      
    elseif ( looked_to_cue )
      errors.broke_cue_fixation = true;
      cstate = 'sm_cue_error';
      first_entry = true;
      continue;
    end
    
    if ( cue.duration_met() )
      cstate = 'sm_present_image';
      first_entry = true;
      continue;
    end
    
    if ( ~drew_stimulus )
      cellfun( @(x) x.draw(), stims );
      Screen( 'flip', WINDOW.index );
      events.sm_cue_on = TIMER.get_time( 'task' );
      drew_stimulus = true;
    end
    
    if ( ~looked_to_cue && TIMER.duration_met(cstate) )
      cstate = 'sm_cue_error';
      first_entry = true;
    end
  end
  
  %   STATE sm_present_image
  if ( strcmp(cstate, 'sm_present_image') )
    if ( first_entry )
      LOG_DEBUG(['Entered ', cstate], 'entry');
      Screen( 'flip', WINDOW.index );
      TIMER.reset_timers( cstate );
      
      events.(cstate) = TIMER.get_time( 'task' );
       
      image_stims = { STIMULI.sm_image1; };
      
      cellfun( @(x) x.reset_targets(), image_stims );
      drew_stimulus = false;
      first_entry = false;
    end
    
    if ( ~drew_stimulus )
      cellfun( @(x) x.draw(), image_stims );
      Screen( 'flip', WINDOW.index );
      events.sm_image_on = TIMER.get_time( 'task' );
      drew_stimulus = true;
    end
    
    if ( TIMER.duration_met(cstate) )
      cstate = 'sm_reward';
      first_entry = true;
    end
  end
  
  %   STATE sm_cue_error
  if ( strcmp(cstate, 'sm_cue_error') )
    if ( first_entry )
      LOG_DEBUG(['Entered ', cstate], 'entry');
      TIMER.reset_timers( cstate );
      
      events.(cstate) = TIMER.get_time( 'task' );
      
      Screen( 'flip', WINDOW.index );
      first_entry = false;
    end
    
    if ( TIMER.duration_met(cstate) )
      cstate = 'new_trial';
      first_entry = true;
    end
  end
  
  %   STATE sm_reward
  if ( strcmp(cstate, 'sm_reward') )
    if ( first_entry )
      LOG_DEBUG(['Entered ', cstate], 'entry');
      TIMER.reset_timers( cstate );
      
      events.(cstate) = TIMER.get_time( 'task' );
      comm.reward( 1, opts.REWARDS.sm_main );
      
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
  save_p = fullfile( opts.PATHS.data, 'sm' );
  
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

function name = configure_cue(cue, image_info, trial_type)

name = configure_cue_or_cued_image( cue, image_info, 'cue', trial_type );

end

function name = configure_cued_image(cued_image, image_info, trial_type)

name = configure_cue_or_cued_image( cued_image, image_info, 'cued-image', trial_type );

end

function name = configure_cue_or_cued_image(img, image_info, image_type, trial_type)

name = '';

if ( ~isa(img, 'Image') )
  warning( 'Stimulus is not an image.' );
  return
end

images = image_info(:, end);
image_types = image_info(:, 1);
trial_types = image_info(:, 2);
names = image_info(:, end-1);

it_ind = strcmp( image_types, image_type );
tt_ind = strcmp( trial_types, trial_type ) & it_ind;

if ( sum(tt_ind) ~= 1 )
  warning( 'More or fewer than 1 types / image_types matched "%s", "%s".', trial_type, image_type );
  return
end

tt_ind = find( tt_ind );
tt_imgs = images{tt_ind};
tt_names = names{tt_ind};

tt_use = randi( numel(tt_imgs) );
img.image = tt_imgs{tt_use};

name = tt_names{tt_use};

end