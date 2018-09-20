function m = get_function_to_stimuli_subfolder_map()

%   GET_FUNCTION_TO_STIMULI_SUBFOLDER_MAP -- Get a map indicating which
%   stimuli subfolder corresponds to each task function.
%
%     OUT:
%       - `m` (containers.Map)

m = containers.Map();

prefix = 'hwwba.task.';

m(sprintf('%srun_attentional_capture', prefix)) = 'ac';
m(sprintf('%srun_biased_attention', prefix)) = 'ba';
m(sprintf('%srun_gaze_following', prefix)) = 'gf';
m(sprintf('%srun_joint_attention', prefix)) = 'ja';
m(sprintf('%srun_social_motivation', prefix)) = 'sm';

end