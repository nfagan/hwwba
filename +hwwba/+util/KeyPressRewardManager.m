%{
@T begin

declare function KbCheck :: [?, ?, double] = ()
declare function KbName :: [double] = (char)

end
%}
classdef KeyPressRewardManager < handle
  properties (Access = public)
    % @T :: [] = ()
    reward_func = @noop;
    timeout = 0.5;
    trigger_key = KbName( 'r' );
  end
  
  properties (Access = private)
    timer;
  end
  
  methods
    function obj = KeyPressRewardManager(reward_func)
      if ( nargin > 0 )
        obj.reward_func = reward_func;
      end
      
      obj.timer = nan;
    end
    
    function update(obj)
      [~, ~, key_state] = KbCheck();
      
      if ( key_state(obj.trigger_key) && ...
          (isnan(obj.timer) || toc(obj.timer) > obj.timeout) )
        obj.reward_func();
        obj.timer = tic;
      end
    end
  end
end

function noop()
end