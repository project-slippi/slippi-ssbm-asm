# Slippi SSBM ASM
## Project Slippi
This repository is part of the Project Slippi ecosystem. For more information about all of the Project Slippi projects, visit https://github.com/project-slippi/project-slippi.

## Intro
This project is home to the series of ASM mods that are applied to Melee in order to make Slippi work. It includes multiple configurations of the code for different use cases.

## Build Instructions
### Local
1. In order to build this project you will need to [download](https://github.com/JLaferri/gecko/releases) the `gecko` program and add it to your PATH env variable. Linux/macOS users can pull the code and run `go build` to generate a binary.
2. All systems should support running `make` to build. Otherwise, on Windows you can run `build.bat` and on Linux/macOS you can run `build.sh`.

### Docker
We also have a docker image that you can use to build by running `docker run --volume=${PWD}:/work --workdir=/work nikhilnarayana/devkitpro-slippi make`.

## Output
### Console
These are `.gct` files for use with Nintendont when recording replays on console.

### Netplay
This codeset should be used for Netplay or any other form of playing the game on Dolphin. Place the `GALE01r2.ini` file in the `Sys/GameSettings` directory of your Dolphin build. It may also be worth checking if you have the following codes enabled in Dolphin:
- Faster Melee Netplay Settings
- Normal Lag Reduction
- Game Music ON/OFF (preference)
- Enable OSReport Print on Crash (1.02)
- Slippi Recording

### Playback
This codeset is used for launching and watching replay files. It is automatically packaged as part of the Slippi Desktop App. It works similarly to the Netplay output as it is also a Dolphin config.
