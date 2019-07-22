function tracker_sync = update_tracker_sync(tracker_sync, current_time)

tracker_sync.timer = tic();
tracker_sync.times(tracker_sync.index) = current_time;
tracker_sync.index = tracker_sync.index + 1;

end