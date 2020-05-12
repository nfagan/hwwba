function manager = make_key_press_reward_manager(comm, channel, reward_amount)

reward_func = @() comm.reward( channel, reward_amount );
manager = hwwba.util.KeyPressRewardManager( reward_func );

end