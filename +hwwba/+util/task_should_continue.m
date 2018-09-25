function tf = task_should_continue(time_id, time_limit, stop_key)

%   TASK_SHOULD_CONTINUE -- True if the task should not quit.
%
%     tf = ... task_should_continue( time_id, time_limit, stop_key )
%     returns true if more than `time_limit` seconds have ellapsed for the
%     timer with id `time_id`, OR if the key given by key code `stop_key` 
%     has been pressed.
%
%     IN:
%       - `time_id` (uint64)
%       - `time_limit` (double)
%       - `stop_key` (double)
%     OUT:
%       - `tf` (logical)

tf = true;

if ( toc(time_id) > time_limit )
  tf = false;
  return
end

[key_pressed, ~, key_code] = KbCheck();

if ( key_pressed )
  if ( key_code(stop_key) )
    tf = false; 
  end
end

end