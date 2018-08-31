hwwba.config.delete();
conf = hwwba.config.load();

conf.INTERFACE.save_data = false;
conf.INTERFACE.is_debug = true;

conf.TIMINGS.time_in.ja_response_error = 2;
conf.TIMINGS.time_in.ja_reward = 0;

% task = @hwwba.task.run_biased_attention;
% task = @hwwba.task.run_joint_attention;
task = @hwwba.task.run_attentional_capture;

hwwba.task.start( task, conf );

%%

hwwba.gui.start;