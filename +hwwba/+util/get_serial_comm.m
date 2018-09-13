function comm = get_serial_comm(conf)

%   GET_SERIAL_COMM -- Get an instantiated interface to the reward Arduino.
%
%     IN:
%       - `conf` (struct)
%     OUT:
%       - `comm` (serial_comm.SerialManager)

if ( nargin < 1 || isempty(conf) )
  conf = hwwba.config.load();
else
  hwwba.util.assertions.assert__is_config( conf );
end

SERIAL = conf.SERIAL;

comm = serial_comm.SerialManager( SERIAL.port, struct(), SERIAL.channels );
comm.bypass = ~conf.INTERFACE.use_reward;

end