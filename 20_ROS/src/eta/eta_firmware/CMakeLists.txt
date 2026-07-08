cmake_minimum_required(VERSION 3.8)
project(eta_firmware)

find_package(ament_cmake REQUIRED)

install(
  FILES
    eta_firmware.ino
    platformio.ini
  DESTINATION
    share/${PROJECT_NAME}/
)

install(
  DIRECTORY
    src
  DESTINATION
    share/${PROJECT_NAME}/
)

ament_package()
