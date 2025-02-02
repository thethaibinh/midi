#!/bin/bash

# Pass number of rollouts as argument
if [ $1 ]
then
  N="$1"
else
  N=10
fi

parent_path=$(dirname "$PWD")
# Set Flightmare Path if it is not set
if [ -z $FLIGHTMARE_PATH ]
then
  export FLIGHTMARE_PATH=$parent_path/flightmare
fi

# Set Planner Path if it is not set
if [ -z $PLANNER_PATH ]
then
  export PLANNER_PATH=$parent_path/midi
fi

# Launch the simulator, unless it is already running
if [ -z $(pgrep visionsim_node) ]
then
  roslaunch envsim visionenv_sim.launch render:=True &
  ROS_PID="$!"
  echo $ROS_PID
  sleep 10
else
  ROS_PID=""
fi

SUMMARY_FILE="evaluation.yaml"

# Perform N evaluation runs
for i in $(eval echo {1..$N})
  do
  # Publish simulator reset
  rostopic pub /kingfisher/dodgeros_pilot/off std_msgs/Empty "{}" --once
  rostopic pub /kingfisher/dodgeros_pilot/reset_sim std_msgs/Empty "{}" --once
  rostopic pub /kingfisher/dodgeros_pilot/enable std_msgs/Bool "data: true" --once
  cd ../agile_flight/envtest/ros/
  # rostopic pub /sampling_mode std_msgs/Int8 "data: 2" --once
  python3 benchmarking_node.py --policy=midi &
  PY_PID="$!"
  cd -
  sleep 0.5
  rostopic pub /kingfisher/start_navigation std_msgs/Empty "{}" --once

  # Wait until the evaluation script has finished
  while ps -p $PY_PID > /dev/null
  do
    sleep 1
  done
  cat "$SUMMARY_FILE" "../agile_flight/envtest/ros/summary.yaml" > "tmp.yaml"
  mv "tmp.yaml" "$SUMMARY_FILE"

  # kill -SIGINT "$COMP_PID"
done

if [ $ROS_PID ]
then
  kill -SIGINT "$ROS_PID"
  kill -SIGINT "$PY_PID"
fi
