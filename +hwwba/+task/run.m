
function run(opts)

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

while ( true )

  [key_pressed, ~, key_code] = KbCheck();

  if ( key_pressed )
    if ( key_code(INTERFACE.stop_key) ), break; end
  end

  TRACKER.update_coordinates();

  %   STATE new_trial
  if ( strcmp(cstate, 'new_trial') )
    configure_images( STIMULI.image1, STIMULI.image2, STIMULI.setup.image_info );    
    
    cstate = 'fixation';
    first_entry = true;
  end

  %   STATE fixation
  if ( strcmp(cstate, 'fixation') )
    if ( first_entry )
      Screen( 'flip', WINDOW.index );
      TIMER.reset_timers( cstate );
      %   get stimulus, and reset target timers
      fix_square = STIMULI.fix_square;
      fix_square.reset_targets();
      %   reset current state variables
      acquired_target = false;
      drew_stimulus = false;
      %   done with initial setup
      first_entry = false;
    end

    fix_square.update_targets();

    if ( ~drew_stimulus )
      fix_square.draw();
      Screen( 'flip', WINDOW.index );
      drew_stimulus = true;
    end

    if ( fix_square.duration_met() )
      acquired_target = true;
      cstate = 'present_images';
      first_entry = true;
    end

    if ( TIMER.duration_met(cstate) && ~acquired_target )
      cstate = 'new_trial';
      first_entry = true;
    end
  end
  
  %   STATE present_images
  if ( strcmp(cstate, 'present_images') )
    if ( first_entry )
      Screen( 'flip', WINDOW.index );
      TIMER.reset_timers( cstate );
      
      image_stims = { STIMULI.image1, STIMULI.image2 };
      
      cellfun( @(x) x.reset_targets(), image_stims );
      drew_stimulus = false;
      first_entry = false;
    end
    
    if ( ~drew_stimulus )
      cellfun( @(x) x.draw(), image_stims );
      Screen( 'flip', WINDOW.index );
      drew_stimulus = true;
    end
    
    if ( TIMER.duration_met(cstate) )
      cstate = 'reward';
      first_entry = true;
    end
  end
  
  %   STATE reward
  if ( strcmp(cstate, 'reward') )
    if ( first_entry )
      Screen( 'flip', WINDOW.index );
      first_entry = false;
    end
    
    if ( TIMER.duration_met(cstate) )
      cstate = 'new_trial';
      first_entry = true;
    end
  end
  
end

end

function configure_images(img1, img2, image_info)

images = image_info(:, end);

if ( isa(img1, 'Image') )
  img1.image = images{1}{1};
else
  disp( 'WARN: Image 1 is not an image.' );
end

if ( isa(img2, 'Image') )
  img2.image = images{1}{1};
else
  disp( 'WARN: Image 2 is not an image.' );
end

end
	