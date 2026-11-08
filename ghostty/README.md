# Ghostty

[config](config) is a shared Linux/macOS configuration. **Install Ghostty
independently** using the [upstream instructions](https://ghostty.org/docs/install/binary).
There is no Ghostty installer here, and bootstrap does not configure it.

## Appearance and behavior

- **Ayu Mirage**, **13-point** bundled JetBrains Mono with Nerd Font symbols;
  **no separate font installation required**.
- **14-point** padding, **0.96** opacity, a non-blinking block cursor, automatic
  window appearance, no resize overlay, and a 0.95 scroll multiplier.
- Native shortcuts and toolbar styling, without custom keybindings or GTK-only
  overrides. Shell integration keeps the block cursor and enables `ssh-env`,
  not automatic remote terminfo installation. Requires Ghostty **1.2.0+**.
- Close confirmation is disabled: closing a terminal can terminate running work
  without warning. Applications can override the cursor; shell prompts and
  application colors are configured separately.

Transparency depends on the compositor; application-painted backgrounds may stay
opaque. On macOS, native fullscreen disables transparency and changing opacity
requires a full restart. See the [option reference](https://ghostty.org/docs/config/reference).

## Integrating the configuration

1. Inspect `${XDG_CONFIG_HOME:-$HOME/.config}/ghostty` on either platform. macOS
   also loads `~/Library/Application Support/com.mitchellh.ghostty` **after** XDG,
   so it can override those settings.
2. Check both `config` and `config.ghostty` (supported since 1.2.3), symlinks and
   `config-file` includes. Avoid loading duplicate files unintentionally; included
   files load last and can override their parent. Back up affected files and link
   targets before editing.
3. Compare and copy the desired settings, preserving necessary local overrides.
   Alternatively, deliberately link the tracked file into one supported location.
   Never overwrite blindly; a link depends on this checkout staying in place and
   follows later repository changes.
4. Validate below, reload with Ctrl+Shift+Comma on Linux or Command+Shift+Comma on
   macOS, and test a new window while keeping a working terminal open.

## Verification and recovery

From the repository root:

```sh
ghostty --version
ghostty +list-themes --plain
ghostty +validate-config --config-file="$PWD/ghostty/config"
```

Confirm `Ayu Mirage` is listed. On macOS, the executable may instead be at
`/Applications/Ghostty.app/Contents/MacOS/ghostty`. After integration, run
`ghostty +validate-config` to check the active configuration and overrides.

Validation checks syntax and theme loading, not appearance. Check fonts and
transparency on each platform; parser success does not establish equal rendering.

To revert, restore your backups or remove only the link you created after checking
its target, then reload/restart. Do not run bootstrap or uninstall Ghostty.

### Agent-ready integration prompt

```text
Read <repository>/ghostty/README.md and ghostty/config as the desired setup.
Inspect my version, configuration files, includes and local overrides. Propose
minimal integration before editing; back up approved changes and preserve unrelated
settings. Do not install/upgrade tools, run bootstrap or change my default terminal.
Validate the tracked and active configurations, explain visual checks and recovery.
```
