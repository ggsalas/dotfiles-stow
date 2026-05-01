#!/bin/sh

# Set a fast keyboard repeat rate
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# Disable press-and-hold for keys (required for key repeat in vim)
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# Disable autocorrect and text substitutions
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# Move a window by Ctrl+Cmd+dragging from anywhere (not just the title bar)
defaults write -g NSWindowShouldDragOnGesture -bool true

# Finder
defaults write com.apple.finder AppleShowAllFiles -bool true        # show hidden files
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv" # list view
defaults write com.apple.finder _FXSortFoldersFirst -bool true
defaults write com.apple.finder _FXSortFoldersFirstOnDesktop -bool true
defaults write com.apple.finder NewWindowTarget -string "PfAF"      # open All Files by default
killall Finder

# Menu bar clock
defaults write com.apple.menuextra.clock ShowAMPM -bool true
defaults write com.apple.menuextra.clock ShowDate -bool false
defaults write com.apple.menuextra.clock ShowDayOfWeek -bool true

# Standby: disabled on AC (-c), enabled on battery (-b)
# Without this, Mac won't wake from external keyboard after ~70min on AC
sudo pmset -c standby 0
sudo pmset -b standby 1

# Display sleep: 20 min on AC, 4 min on battery
sudo pmset -c displaysleep 10
sudo pmset -b displaysleep 4

# Sleep: never on AC, 5 min on battery
sudo pmset -b sleep 5
sudo pmset -c sleep 0

# Dock
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock tilesize -int 53
defaults write com.apple.dock show-recents -bool false

# Mission Control - do not reorder spaces automatically
defaults write com.apple.dock mru-spaces -bool false

killall Dock

# Keyboard shortcuts (Mission Control, Spaces, Spotlight)
# Helper to set a symbolic hotkey
set_hotkey() {
  defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add "$1" \
    "<dict><key>enabled</key><$2/><key>value</key><dict><key>parameters</key><array><integer>$3</integer><integer>$4</integer><integer>$5</integer></array><key>type</key><string>standard</string></dict></dict>"
}

# Mission Control
set_hotkey 32  true  65535 126 8650752  # Ctrl+Up

# Switch to Desktop 1-8 (Cmd+1 to Cmd+8)
set_hotkey 118 true  49 18 1048576
set_hotkey 119 true  50 19 1048576
set_hotkey 120 true  51 20 1048576
set_hotkey 121 true  52 21 1048576
set_hotkey 122 true  53 23 1048576
set_hotkey 123 true  54 22 1048576
set_hotkey 124 true  55 26 1048576
set_hotkey 125 true  56 28 1048576

# Move left/right a space (Cmd+[ and Cmd+])
set_hotkey 79  true  93 30 1048576
set_hotkey 80  true  93 30 1179648
set_hotkey 81  true  91 33 1048576
set_hotkey 82  true  91 33 1179648

# Spotlight (Cmd+Space for Launchpad)
set_hotkey 64  true  32 49 1048576
set_hotkey 60  false 32 49 262144   # disable Ctrl+Space Spotlight
set_hotkey 61  false 32 49 786432   # disable Ctrl+Opt+Space Spotlight

# Notification Center
set_hotkey 98  true  47 44 1179648  # Shift+Cmd+/

# Apply hotkey changes
/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u

echo "macOS options applied. Restart may be required."

