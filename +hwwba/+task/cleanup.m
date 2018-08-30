
function cleanup(tracker)

%   CLEANUP -- Close open files, ports, etc.

try
  sca;

  ListenChar( 0 );
catch err
  warning( err.message );
end

hwwba.util.close_ports();

if ( nargin >= 1 && ~isempty(tracker) )
  tracker.shutdown()
end

end