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

task_order = conf.TASK_ORDER;
task_func_map = get_task_func_map();

order_values = struct2cell( task_order );
order_ids = fieldnames( task_order );

order_values = vertcat( order_values{:} );

if ( numel(order_values) ~= task_func_map.Count )
  error( 'Expected %d task order values; got %d.', task_func_map.Count, order_values );
end

for i = 1:numel(order_ids)
  if ( ~isKey(task_func_map, order_ids{i}) )
    error( 'Unrecognized task id: "%s".', order_ids{i} );
  end
end

if ( numel(unique(order_values)) ~= numel(order_values) )
  error( 'Task ordering is not unique.' );
end

[sorted_values, sorted_i] = sort( order_values );

if ( ~all(unique(diff(sorted_values)) == 1) )
  error( 'Task ordering is non-sequential.' );
end

sorted_ids = order_ids(sorted_i);
tasks = cellfun( @(x) task_func_map(x), sorted_ids, 'un', 0 );

for i = 1:numel(tasks)
  log_start( tasks{i}, conf );
  
  hwwba.task.start( tasks{i}, conf );
end

hwwba.util.print_latest_performance( conf );

end

function map = get_task_func_map()

map = containers.Map();
map('ac') = @hwwba.task.run_attentional_capture;
map('ba') = @hwwba.task.run_biased_attention;
map('gf') = @hwwba.task.run_gaze_following;
map('ja') = @hwwba.task.run_joint_attention;
map('sm') = @hwwba.task.run_social_motivation;

end

function log_start(task, conf)

if ( ~conf.INTERFACE.is_debug ), return; end
fprintf( '\n\n\nBEGINNING TASK: "%s"\n\n\n', func2str(task) );

end