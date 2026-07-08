'''
This test script is intended to test all functions available in RobotClientAPI module.

To run the test,

1. launch the simulation with controller servers.

    ros2 launch eta_rmf_gz spawn_multiple_robot.launch.py

2. run the fleet manager.

    ros2 run eta_fleet_manager fleet_manager

3. run test using the following command,

    pytest-3 ~/ros2_ws/src/eta_fleet_open_rmf/eta_fleet_adapter/test/test_robot_api.py
'''

import pytest
import rclpy
from rclpy.node import Node
from eta_fleet_adapter.RobotClientAPI import RobotAPI


rclpy.init()
@pytest.fixture
def setup():
    # create RobotAPI object which requires test_node as argument
    robot_api = RobotAPI('', 'test', 'test')
    return robot_api

# test functions
def test_connection(setup):
    is_connected = setup.check_connection()
    assert is_connected == True


def test_get_position(setup):
    # get eta1 position
    robot1_pose = setup.position('eta1')
    assert robot1_pose is not None

    # get eta2 position
    robot2_pose = setup.position('eta2')
    assert robot2_pose is not None

def test_navigate(setup):
    # send goal to eta1
    is_goal1_sent = setup.navigate('eta1', [1.0, 1.0, 0.0], '')
    assert is_goal1_sent == True

    # send goal to eta2
    is_goal2_sent = setup.navigate('eta2', [-0.7, 0.2, 0.0], '')
    assert is_goal2_sent == True

def test_stop(setup):
    # cancel current goal
    is_robot1_stop = setup.stop('eta1')
    assert is_robot1_stop == True

    is_robot2_stop = setup.stop('eta2')
    assert is_robot2_stop == True

def test_navigation_duration(setup):
    # check remaining duration
    duration1 = setup.navigation_remaining_duration('eta1')
    assert duration1 is not None

    duration2 = setup.navigation_remaining_duration('eta2')
    assert duration2 is not None

def test_navigation_completed(setup):
    # check navigation completed
    is_completed1 = setup.navigation_completed('eta1')
    assert is_completed1 == False

    is_completed2 = setup.navigation_completed('eta2')
    assert is_completed2 == False
