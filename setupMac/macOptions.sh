#!/bin/sh

# Set a fast keyboard repeat rate
defaults write NSGlobalDomain KeyRepeat -int 1
defaults write NSGlobalDomain InitialKeyRepeat -int 12

# Draw a window clicking on any part (control + command + click)
defaults write -g NSWindowShouldDragOnGesture -bool true

