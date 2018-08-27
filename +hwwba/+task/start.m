
function err = start(conf)

%   START -- Attempt to setup and run the task.
%
%     OUT:
%       - `err` (double, MException) -- 0 if successful; otherwise, the
%         raised MException, if setup / run fails.

if ( nargin < 1 || isempty(conf) )
  conf = hwwba.config.load();
else
  hwwba.util.assertions.assert__is_config( conf );
end

try
  opts = hwwba.task.setup( conf );
catch err
  hwwba.task.cleanup();
  hwwba.util.print_error_stack( err );
  return;
end

try
  err = 0;
  hwwba.task.run( opts );
  hwwba.task.cleanup();
catch err
  hwwba.task.cleanup();
  hwwba.util.print_error_stack( err );
end

end