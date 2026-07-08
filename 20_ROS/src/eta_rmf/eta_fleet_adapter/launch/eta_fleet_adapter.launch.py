import os
from ament_index_python.packages import get_package_share_directory

from launch import LaunchDescription
from launch_ros.actions import Node


def generate_launch_description():

    rmf_config_file = os.path.join(get_package_share_directory('eta_fleet_adapter'), 'config.yaml')
    nav_graph_file = os.path.join(get_package_share_directory('eta_rmf_maps'), 'maps', 'eta_office', 'nav_graphs', '0.yaml')

    fleet_adapter = Node(
        package= 'eta_fleet_adapter',
        executable= 'fleet_adapter',
        name= 'eta_fleet_adapter',
        arguments=['-c', rmf_config_file, '-n', nav_graph_file, '--use_sim_time'],
        output='both',
    )
    
    ld = LaunchDescription()
    ld.add_action(fleet_adapter)

    return ld
