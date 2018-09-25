function run_tasks_consecutively(conf)

%   RUN_TASKS_CONSECUTIVELY -- Run a series of tasks in sequence.
%
%     run_tasks_consecutively() runs each task present in `+hwwba/+task`
%     for an amount of time defined in the config file for that task.
%
%     run_tasks_consecutively( conf ) uses the config file `conf` instead
%     of the saved config file.
%
%     IN:
%       - `conf` (struct) |OPTIONAL|

if ( nargin < 1 || isempty(conf) )
  conf = hwwba.config.load();
end

tasks = {
    @hwwba.task.run_attentional_capture ...
  , @hwwba.task.run_biased_attention ...
  , @hwwba.task.run_gaze_following ...
  , @hwwba.task.run_joint_attention ...
  , @hwwba.task.run_social_motivation ...
};

for i = 1:numel(tasks)
  log_start( tasks{i}, conf );
  
  hwwba.task.start( tasks{i}, conf );
end

end

function log_start(task, conf)

if ( ~conf.INTERFACE.is_debug ), return; end
fprintf( '\n\n\nBEGINNING TASK: "%s"\n\n\n', func2str(task) );

end