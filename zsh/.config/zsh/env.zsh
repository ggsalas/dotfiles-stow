export EDITOR="nvim"
export VISUAL="nvim"
export PAGER="less -R"
export LANG="en_US.UTF-8"

# android
export JAVA_HOME=$(/usr/libexec/java_home -v 17)
export ANDROID_HOME="/opt/homebrew/share/android-commandlinetools"
unset ANDROID_SDK_ROOT
export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"

# opencode
export PATH="$HOME/.opencode/bin:$PATH"

# ollama to comunicate with opencode
export LOCAL_ENDPOINT=http://localhost:11434

# lm studio
export PATH="$PATH:$HOME/.lmstudio/bin"

# local bin
export PATH="$HOME/.local/bin:$PATH"
