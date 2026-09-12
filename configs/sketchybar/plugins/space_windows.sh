#!/bin/bash

if [ "$SENDER" = "space_windows_change" ]; then
  space="$(echo "$INFO" | jq -r '.space')"
  apps="$(echo "$INFO" | jq -r '.apps | keys[]')"

  icon_strip=""
  while IFS= read -r app; do
    case "$app" in
      "" | "Screen Studio" | "ScreenStudio" | "Screen Studio Helper"*)
        continue
        ;;
    esac

    icon_strip+=" $($CONFIG_DIR/plugins/icon_map_fn.sh "$app")"
  done <<< "${apps}"

  if [ "${icon_strip}" = "" ]; then
    icon_strip=" —"
  fi

  sketchybar --set space.$space label="$icon_strip"
fi
