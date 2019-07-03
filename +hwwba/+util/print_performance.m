function print_performance(data, by_image_type, total_trials, image_type, include_incorrect ...
, initiated_func, correct_func)

if ( nargin < 7 )
  correct_func = @(data) ~any( structfun(@(x) x, data.errors) );
end

if ( ~isKey(by_image_type, image_type) )
  curr = struct();
  curr.num_correct = 0;
  curr.num_initiated = 0;
  
  if ( include_incorrect )
    curr.num_incorrect = 0;
  end
else
  curr = by_image_type(image_type);
end

if ( correct_func(data) )
  curr.num_correct = curr.num_correct + 1;
elseif ( include_incorrect )
  curr.num_incorrect = curr.num_incorrect + 1;
end

if ( initiated_func(data) )
  curr.num_initiated = curr.num_initiated + 1;
end

by_image_type(image_type) = curr;

image_types = keys( by_image_type );

all_correct = 0;
all_initiated = 0;
all_incorrect = 0;

for i = 1:numel(image_types)
  curr = by_image_type(image_types{i});
  
  if ( include_incorrect )
    fprintf( '\n Type: %s; Correct: %d; Incorrect: %d, Initiated: %d', image_types{i}, curr.num_correct ...
      , curr.num_incorrect, curr.num_initiated );
    all_incorrect = all_incorrect + curr.num_incorrect;
  else
    fprintf( '\n Type: %s; Correct: %d; Initiated: %d', image_types{i}, curr.num_correct, curr.num_initiated );
  end
  
  all_correct = all_correct + curr.num_correct;
  all_initiated = all_correct + curr.num_initiated;
end

if ( include_incorrect )
  fprintf( '\n Total correct %d; total incorrect %d; total initiated: %d; total trials: %d' ...
    , total_trials, all_correct, all_incorrect, all_initiated );
else
  fprintf( '\n Total correct %d; total initiated: %d; total trials: %d' ...
    , total_trials, all_correct, all_initiated );
end

end