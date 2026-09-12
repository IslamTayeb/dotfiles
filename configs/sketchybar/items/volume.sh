#!/bin/bash

sketchybar --add item volume right \
           --set volume icon.color=$WHITE \
                        label.color=$WHITE \
                        script="$PLUGIN_DIR/volume.sh" \
           --subscribe volume volume_change 
