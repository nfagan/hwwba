
function run_biased_attention(opts)

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

%   begin in this state
cstate = 'ba_task_identity';
first_entry = true;

DATA = struct();
events = struct();
errors = struct();

image_categories = { 'fear', 'neutral', 'threat' };
image_directness = { 'direct', 'indirect' };
image_conditions = get_image_condition_matrix( image_categories, image_directness );

block_info.index = size( image_conditions, 1 ) + 1;
block_info.condition_indices = [];

TRIAL_NUMBER = 0;

tracker_sync = struct();
tracker_sync.timer = NaN;
tracker_sync.interval = 1;
tracker_sync.times = [];
tracker_sync.index = 1;

stim_handles = rmfield( STIMULI, 'setup' );

% reset task timer
TIMER.reset_timers( 'ba_task' );

task_timer_id = TIMER.get_underlying_id( 'ba_task' );
task_time_limit = opts.TIMINGS.time_in.ba_task;
stop_key = INTERFACE.stop_key;

while ( hwwba.util.task_should_continue(task_timer_id, task_time_limit, stop_key) )
  
  if ( isnan(tracker_sync.timer) || toc(tracker_sync.timer) >= tracker_sync.interval )
    TRACKER.send( 'RESYNCH' );
    tracker_sync.timer = tic();
    tracker_sync.times(tracker_sync.index) = TIMER.get_time( 'ba_task' );
    tracker_sync.index = tracker_sync.index + 1;
  end

  TRACKER.update_coordinates();
  structfun( @(x) x.update_targets(), stim_handles );
  
  %   STATE task_identity  
  if ( strcmp(cstate, 'ba_task_identity') )
    if ( first_entry )
      TIMER.reset_timers( cstate );
      drew_identity_cue = false;
      first_entry = false;
    end
    
    if ( ~drew_identity_cue )
      cue = STIMULI.ba_task_identity_cue;
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
    
    no_errors = ~any( structfun(@(x) x, errors) );
    
    if ( TRIAL_NUMBER > 0 )
      tn = TRIAL_NUMBER;
      
      DATA(tn).events = events;
      DATA(tn).errors = errors;
      DATA(tn).left_image_category = left_image_category;
      DATA(tn).right_image_category = right_image_category;
      DATA(tn).left_image_filename = left_image_filename;
      DATA(tn).right_image_filename = right_image_filename;
      DATA(tn).directness = current_directness;
    end
    
    if ( no_errors )
      im1 = STIMULI.ba_image1;
      im2 = STIMULI.ba_image2;
      im_info = STIMULI.setup.image_info.ba;
      
      if ( block_info.index > size(image_conditions, 1) )
        block_info.index = 1;
        block_info.condition_indices = randperm( size(image_conditions, 1) );
      end
      
      condition_index = block_info.condition_indices(block_info.index);
      
      left_image_category = image_conditions{condition_index, 1};
      right_image_category = image_conditions{condition_index, 2};  
      current_directness = image_conditions{condition_index, 3};
      
      [left_image_filename, right_image_filename] = configure_images( im1, im2, im_info ...
        , left_image_category, right_image_category, current_directness );
      
      block_info.index = block_info.index + 1;
      
      LOG_DEBUG( sprintf('left-image-category:  %s', left_image_category), 'param' );
      LOG_DEBUG( sprintf('right-image-category: %s', right_image_category), 'param' );
      LOG_DEBUG( sprintf('directness:           %s', current_directness), 'param' );
    end
    
    events = structfun( @(x) nan, events, 'un', 0 );
    errors = structfun( @(x) false, errors, 'un', 0 );
    
    TRIAL_NUMBER = TRIAL_NUMBER + 1;
    
    cstate = 'ba_fixation';
    first_entry = true;
  end

  %   STATE ba_fixation
  if ( strcmp(cstate, 'ba_fixation') )
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
      
      events.(cstate) = TIMER.get_time( 'ba_task' );
      
      first_entry = false;
    end

    fix_square.update_targets();

    if ( ~drew_stimulus )
      fix_square.color = STIMULI.ba_task_identity_cue.color;
      fix_square.draw();
      Screen( 'flip', WINDOW.index );
      events.fixation_onset = TIMER.get_time( 'ba_task' );
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
      events.fixation_acquired = TIMER.get_time( 'ba_task' );
      acquired_target = true;
      cstate = 'ba_present_images';
      first_entry = true;
    end

    if ( TIMER.duration_met(cstate) && ~acquired_target )
      errors.fixation_not_met = true;
      cstate = 'new_trial';
      first_entry = true;
    end
  end
  
  %   STATE ba_present_images
  if ( strcmp(cstate, 'ba_present_images') )
    if ( first_entry )
      LOG_DEBUG(['Entered ', cstate], 'entry');
      Screen( 'flip', WINDOW.index );
      TIMER.reset_timers( cstate );
      
      image_stims = { STIMULI.ba_image1, STIMULI.ba_image2 };
      
      events.(cstate) = TIMER.get_time( 'ba_task' );
      
      cellfun( @(x) x.reset_targets(), image_stims );
      drew_stimulus = false;
      first_entry = false;
    end
    
    if ( ~drew_stimulus )
      cellfun( @(x) x.draw(), image_stims );
      Screen( 'flip', WINDOW.index );
      events.ba_images_on = TIMER.get_time( 'ba_task' );
      drew_stimulus = true;
    end
    
    if ( TIMER.duration_met(cstate) )
      cstate = 'ba_reward';
      first_entry = true;
    end
  end
  
  %   STATE ba_reward
  if ( strcmp(cstate, 'ba_reward') )
    if ( first_entry )
      LOG_DEBUG(['Entered ', cstate], 'entry');
      Screen( 'flip', WINDOW.index );
      events.ba_reward_on = TIMER.get_time( 'ba_task' );
      
      comm.reward( 1, opts.REWARDS.ba_main );
      
      first_entry = false;
    end
    
    if ( TIMER.duration_met(cstate) )
      cstate = 'new_trial';
      first_entry = true;
    end
  end
  
end

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

if ( opts.INTERFACE.save_data )
  fname = sprintf( '%s.mat', strrep(datestr(now), ':', '_') );
  save_p = fullfile( opts.PATHS.data, 'ba' );
  
  shared_utils.io.require_dir( save_p );
  
  edf_file = TRACKER.edf;
  
  save( fullfile(save_p, fname), 'DATA', 'opts', 'edf_file', 'tracker_sync' );
end

TRACKER.shutdown();

end

function c = get_image_condition_matrix(categories, gaze_types)

inds = combvec( 1:numel(categories), 1:numel(categories) ...
  , 1:numel(gaze_types) );

n_combs = size( inds, 2 );
c = {};
stp = 1;

for i = 1:n_combs
  cond = inds(:, i);
  
  left_category = categories(cond(1));
  right_category = categories(cond(2));
  gaze_type = gaze_types(cond(3));
  
  is_same_cat = strcmp( left_category, right_category );
  
  if ( is_same_cat ), continue; end
  
  c(stp, 1) = left_category;
  c(stp, 2) = right_category;
  c(stp, 3) = gaze_type;
  
  stp = stp + 1;
end

end

function [name1, name2] = configure_images(left_image, right_image, image_info ...
  , left_image_category, right_image_category, directness)

name1 = '';
name2 = '';

images = image_info(:, end);
image_filenames = image_info(:, end-1);
image_ids = image_info(:, 1);

if ( strcmp(directness, 'direct') )
  left_image_id = sprintf( '%s-direct', left_image_category );
  right_image_id = sprintf( '%s-direct', right_image_category );
else
  left_image_id = sprintf( '%s-indirect-left', left_image_category );
  right_image_id = sprintf( '%s-indirect-right', right_image_category );
end

if ( isa(left_image, 'Image') )
  [mat, name] = get_image( left_image_id );
  left_image.image = mat;
  name1 = name;
else
  disp( 'WARN: Image 1 is not an image.' );
end

if ( isa(right_image, 'Image') )
  [mat, name] = get_image( right_image_id );
  right_image.image = mat;
  name2 = name;
else
  disp( 'WARN: Image 2 is not an image.' );
end

  function [mat, name] = get_image(image_id)
    image_ind = find( strcmp(image_ids, image_id) );
  
    assert( numel(image_ind) == 1, 'No images or more than one image matched "%s".' ...
      , image_id );

    images_this_id = images{image_ind};
    filenames_this_id = image_filenames{image_ind};
    
    assert( numel(images_this_id) == numel(filenames_this_id) );
    
    use_image_ind = randi( numel(images_this_id) );
    
    mat = images_this_id{use_image_ind};
    name = filenames_this_id{use_image_ind};
  end

end
	