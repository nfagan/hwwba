function print_performance(data, by_image_type, total_trials, image_type, include_incorrect ...
, initiated_func, correct_func)

if ( nargin < 7 )
  correct_func = @(data) ~any( structfun(@(x) x, data.errors) );
end

if ( ~isKey(by_image_type, image_type) )
  curr = struct();
  curr.num_correct = 0;
  curr.num_initiated = 0;
  curr.num_total = 0;
  
  if ( include_incorrect )
    curr.num_incorrect = 0;
  end
else
  curr = by_image_type(image_type);
end

did_initiate = initiated_func( data );

if ( correct_func(data) && did_initiate )
  curr.num_correct = curr.num_correct + 1;
  
elseif ( include_incorrect && did_initiate )
  curr.num_incorrect = curr.num_incorrect + 1;
end

if ( did_initiate )
  curr.num_initiated = curr.num_initiated + 1;
end

curr.num_total = curr.num_total + 1;
by_image_type(image_type) = curr;

image_types = keys( by_image_type );

all_correct = 0;
all_initiated = 0;
all_incorrect = 0;

for i = 1:numel(image_types)
  curr = by_image_type(image_types{i});
  
  if ( include_incorrect )
    fprintf( '\n Type: %s; Correct: %d; Incorrect: %d, Initiated: %d; Total: %d', image_types{i}, curr.num_correct ...
      , curr.num_incorrect, curr.num_initiated, curr.num_total );
    all_incorrect = all_incorrect + curr.num_incorrect;
  else
    fprintf( '\n Type: %s; Correct: %d; Initiated: %d; Total: %d', image_types{i} ...
      , curr.num_correct, curr.num_initiated, curr.num_total );
  end
  
  all_correct = all_correct + curr.num_correct;
  all_initiated = all_initiated + curr.num_initiated;
end

if ( include_incorrect )
  fprintf( '\n Total correct %d; total incorrect %d; total initiated: %d; total trials: %d' ...
    , all_correct, all_incorrect, all_initiated, total_trials );
else
  fprintf( '\n Total correct %d; total initiated: %d; total trials: %d' ...
    , all_correct, all_initiated, total_trials );
end

end