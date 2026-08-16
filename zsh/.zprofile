# Login-shell environment.

# Homebrew uses different canonical prefixes on Apple Silicon and Intel macOS.
if [[ $OSTYPE == darwin* ]]; then
  for brew_executable in \
    /opt/homebrew/bin/brew \
    /usr/local/bin/brew
  do
    if [[ -x $brew_executable ]]; then
      eval "$("$brew_executable" shellenv)"
      break
    fi
  done

  unset brew_executable
fi
