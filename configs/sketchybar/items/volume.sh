#!/bin/bash

sketchybar --add item volume right \
           --set volume icon.color=$YELLOW \
                        label.color=$YELLOW \
                        script="$PLUGIN_DIR/volume.sh" \
           --subscribe volume volume_change 
