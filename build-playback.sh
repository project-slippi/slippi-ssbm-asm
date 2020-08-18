#!/bin/bash
echo Building playback.json...
gecko build -c playback.json -defsym "STG_EXIIndex=1"
echo ""
