# Agent state colors, same mapping as the Herdr sidebar (status_color in
# herdr's src/client/shell.rs), using the terminal's ANSI palette so they
# follow light/dark mode with the terminal theme (no hardcoded RGB).
#   working: yellow   blocked: red   done: teal (cyan)   idle: green ○   unknown: gray ·
C_WORKING='33' C_BLOCKED='31' C_DONE='36' C_IDLE='32' C_UNKNOWN='90'

# fzf colors: transparent background; the current row gets the pointer,
# bold text and the soft theme background below.
FZF_COLORS='16,bg:-1,bg+:-1,gutter:-1,fg+:-1:bold,pointer:4,header:8,prompt:4,hl:4,hl+:4:bold,separator:8,border:8'

# Soft background for the current row: the active Ghostty theme's own
# selection-background (read from the theme file, so it follows the theme and
# light/dark mode). Falls back to no background if it can't be found.
ghostty_dir="$HOME/.config/ghostty"
if /usr/bin/defaults read -g AppleInterfaceStyle 2>/dev/null | /usr/bin/grep -q Dark; then mode=dark; else mode=light; fi
theme=$(/usr/bin/sed -n 's/^theme *= *//p' "$ghostty_dir/config" 2>/dev/null | /usr/bin/tr ',' '\n' \
  | /usr/bin/sed -n "s/^ *$mode: *//p" | /usr/bin/sed 's/ *$//' | /usr/bin/head -1)
sel_bg=$([ -n "$theme" ] && /usr/bin/sed -n 's/^selection-background *= *\(#[0-9a-fA-F]\{6\}\).*/\1/p' \
  "$ghostty_dir/themes/$theme" 2>/dev/null | /usr/bin/head -1)
[ -n "$sel_bg" ] && FZF_COLORS="$FZF_COLORS,bg+:$sel_bg"
