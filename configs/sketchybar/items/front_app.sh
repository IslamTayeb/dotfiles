#!/bin/bash

sketchybar --add item front_app right \
  --set front_app background.color=$RED \
  icon.color=$BAR_COLOR \
  icon.font="sketchybar-app-font:Regular:16.0" \
  label.color=$BAR_COLOR \
  label.font="Hack Nerd Font:Bold:14.0" \
  script="$PLUGIN_DIR/front_app.sh" \
  --subscribe front_app front_app_switched
