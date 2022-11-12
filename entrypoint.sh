#!/bin/bash
# This script is the entry point of the build management
# script in the zephyr-builder container.

CONFIG_MODE="config"
PROD_MODE="prod"
DEV_MODE="dev"
DEBUG_MODE="debug"
QEMU_MODE="qemu"
TEST_MODE="test"

ZEPHYR_WORKDIR=/zephyr-project
APP_DIR=$ZEPHYR_WORKDIR/app
PROJ_CONFIG=$APP_DIR/prj.conf
BUILD_ARTEFACT=$ZEPHYR_WORKDIR/build
TEST_ARTEFACT=$ZEPHYR_WORKDIR/twister-out

GITHUB_WORKSPACE=/github/workspace/

BUILD_MODE=$1

function redPrint {
  if [[ "$1" != "" ]]
  then
    STRING=$1
    RED='\033[0;31m'
    NC='\033[0m' # No Color
    echo -e "${RED}${STRING}${NC}"
  fi
}

function greenPrint {
  if [[ "$1" != "" ]]
  then
    STRING=$1
    GREEN='\033[0;32m'
    NC='\033[0m' # No Color
    echo -e "${GREEN}${STRING}${NC}"
  fi
}

function exitError {
  ERR_MSG=$1
  redPrint "${ERR_MSG}"
  exit 1
}

function validateBuildMode {
  if [[ ! $BUILD_MODE =~ ^($PROD_MODE|$DEV_MODE|$DEBUG_MODE|$QEMU_MODE|$TEST_MODE|$CONFIG_MODE)$ ]]
  then
    exitError "ERROR: ${BUILD_MODE} is not a supported build mode."
  fi
}

function setupWorkspace {
  greenPrint "Copying source code..."
  cp -r $GITHUB_WORKSPACE $APP_DIR
  greenPrint "Updating the workspace..."
  cd $ZEPHYR_WORKDIR
  west update
  return $?
}

function buildFirmware {
  if [[ "$1" != "" ]]
  then
    BUILD_ENV=$1
    greenPrint "Building firmware in ${BUILD_ENV} environment..."
    cd $ZEPHYR_WORKDIR
    west build ./app -- -DBUILD_ENV=${BUILD_ENV} || exitError "ERROR: Unable to build the firmware."
  else
    exitError "ERROR: ${BUILD_ENV} is not a supported build environment."
  fi
}

function moveBuildArtefacts {
  # TODO: Name the target artefact base on the firmware name and version (appInfo.h)
  cp -r $BUILD_ARTEFACT $GITHUB_WORKSPACE/ || return 1
  return 0
}

function moveTestArtefacts {
  # TODO: Name the target artefact base on the firmware name and version (appInfo.h)
  cp -r $TEST_ARTEFACT $GITHUB_WORKSPACE/ || return 1
  return 0
}

if [ -z "$BUILD_MODE" ]
then
  exitError "ERROR: No build mode have been provided."
fi

# Validate build mode
validateBuildMode

# Export variables
# export ZEPHYR_BASE=/zephyr-project/zephyr
export ZEPHYR_TOOLCHAIN_VARIANT=zephyr

# Setup the workspace
greenPrint "Setting up the Zephyr workspace..."
setupWorkspace || exitError "ERROR: Unable to setup the Zephyr workspace."
greenPrint "Zephyr workspace setup DONE!"

# Launch configuration tool if mode is config
if [[ $BUILD_MODE =~ ^($CONFIG_MODE)$ ]]
then
  buildFirmware ${PROD_MODE}
  greenPrint "Configuring the firmware..."
  west build -t menuconfig || exitError "ERROR: Unable to configure the firmware."
  greenPrint "Firmation configuration DONE!"
  # TODO: Move and rename defconfig??
fi

# Build the firmware in release mode
if [[ $BUILD_MODE =~ ^($PROD_MODE)$ ]]
then
  greenPrint "Building the firmware in ${BUILD_MODE} mode..."
  buildFirmware ${BUILD_MODE}
  greenPrint "Firmware build DONE!"
  greenPrint "Moving build artefacts..."
  moveBuildArtefacts || exitError "ERROR: Unable to move build artefacts."
  greenPrint "Build artefacts move DONE!!"
fi

# Build the firmware in development/debug mode
if [[ $BUILD_MODE =~ ^($DEV_MODE|$DEBUG_MODE)$ ]]
then
  greenPrint "Building the firmware in ${BUILD_MODE} mode..."
  buildFirmware ${DEV_MODE}
  greenPrint "Firmware build DONE!"
  if [[ $BUILD_MODE =~ ^($DEBUG_MODE)$ ]]
  then
    greenPrint "Debugging the firmware..."
    west debug || exitError "ERROR: Unable to debug firmware."
    greenPrint "Firmware debug DONE!!"
  else
    greenPrint "Flashing target..."
    west flash || exitError "ERROR: Unable to flash the target."
    greenPrint "Target flash DONE!!"
  fi
fi

# Run the firmware if mode is qemu
if [[ $BUILD_MODE =~ ^($QEMU_MODE)$ ]]
then
  buildFirmware ${BUILD_MODE}
  greenPrint "Running the firmware in ${BUILD_MODE} mode..."
  west build -t run || exitError "ERROR: Unable to run the firmware."
  greenPrint "Firmware run DONE!!"
fi

# Run the test cases
# TODO: setup coverage
if [[ $BUILD_MODE =~ ^($TEST_MODE)$ ]]
then
  greenPrint "Running the firmware tests..."
  cd $ZEPHYR_WORKDIR
  echo $PWD
  ls .
  cat ./app/west.yml
  ls ./app/
  zephyr/scripts/twister -T app/
  testResut=$?
  greenPrint "Moving test artefacts..."
  moveTestArtefacts || exitError "ERROR: Unable to move test artefacts."
  greenPrint "Test artefacts move DONE!!"
  if [ $testResut -ne 0 ]
  then
    exitError "ERROR: Unable to test the firmware."
  fi
  greenPrint "Firmware tests DONE!!"
fi
