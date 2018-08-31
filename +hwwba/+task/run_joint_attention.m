
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
    LOG_DEBUG(['Entered ', cstate]);
    
    no_errors = ~any( structfun(@(x) x, errors) );
    
    if ( no_errors )
      configure_images( STIMULI.ja_image1, STIMULI.setup.image_info.ja );
    end
    
    if ( TRIAL_NUMBER > 0 )
      tn = TRIAL_NUMBER;
      
      DATA(tn).events = events;
      DATA(tn).errors = errors;
      DATA(tn).response_direction = ja_response_direction;
    end
    
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
      cstate = 'ja_present_image';
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
      LOG_DEBUG(['Entered ', cstate]);
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
      events.images_on = TIMER.get_time( 'task' );
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
      LOG_DEBUG(['Entered ', cstate]);
      Screen( 'flip', WINDOW.index );
      TIMER.reset_timers( cstate );
      
      stims = { STIMULI.ja_response1, STIMULI.ja_response2 };
      
      ja_response_direction = '';
      looked_to = '';
      
      cellfun( @(x) x.reset_targets(), stims );
      drew_stimulus = false;
      first_entry = false;
    end
    
    if ( ~drew_stimulus )
      cellfun( @(x) x.draw(), stims );
      Screen( 'flip', WINDOW.index );
      events.response_targets_on = TIMER.get_time( 'task' );
      drew_stimulus = true;
    end
    
    for i = 1:numel(stims)
      if ( ~stims{i}.in_bounds() )
        if ( ~isempty(looked_to) && strcmp(looked_to, stims{i}.placement) )
          ja_response_direction = '';
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
      cstate = 'ja_reward';
      first_entry = true;
      continue;
    end
    
    if ( TIMER.duration_met(cstate) )
      cstate = 'ja_response_error';
      first_entry = true;
    end
  end
  
  %   STATE ja_reward
  if ( strcmp(cstate, 'ja_reward') )
    if ( first_entry )
      LOG_DEBUG(['Entered ', cstate]);
      events.reward_on = TIMER.get_time( 'task' );
      TIMER.reset_timers( cstate );
      Screen( 'flip', WINDOW.index );
      first_entry = false;
    end
    
    if ( TIMER.duration_met(cstate) )
      cstate = 'new_trial';
      first_entry = true;
    end
  end
  
  %   STATE ja_response_error
  if ( strcmp(cstate, 'ja_response_error') )
    if ( first_entry )
      LOG_DEBUG(['Entered ', cstate]);
      events.ja_response_error = TIMER.get_time( 'task' );
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
  fname = datestr( now );
  save_p = fullfile( opts.PATHS.data, 'ja' );
  
  shared_utils.io.require_dir( save_p );
  
  save( fullfile(save_p, fname), 'DATA', 'opts' );
end

  function LOG_DEBUG(msg)
    if ( opts.INTERFACE.is_debug )
      fprintf( '\n%s', msg );
    end
  end

end

function configure_images(img1, image_info)

images = image_info(:, end);

if ( isa(img1, 'Image') )
  img1.image = images{1}{1};
else
  disp( 'WARN: Image 1 is not an image.' );
end

end
	