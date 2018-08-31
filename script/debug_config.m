hwwba.config.delete();
conf = hwwba.config.load();

conf.INTERFACE.save_data = false;
conf.INTERFACE.is_debug = true;
conf.INTERFACE.debug_tags = { 'response' };

conf.TIMINGS.time_in.ja_response_error = 2;
conf.TIMINGS.time_in.ja_reward = 0;
conf.TIMINGS.time_in.gf_present_image = 0.001;

task = @hwwba.task.run_biased_attention;
% task = @hwwba.task.run_joint_attention;
% task = @hwwba.task.run_attentional_capture;
% task = @hwwba.task.run_gaze_following;

hwwba.task.start( task, conf );

%%

clear all; 
close all; 
clc;

%%

hwwba.gui.start;