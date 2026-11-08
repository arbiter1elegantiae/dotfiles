# Herdr TUI

[`config.toml`](config.toml) uses the terminal's palette, a **Ctrl+B** prefix,
pane/tab/workspace shortcuts, compact pane dividers, and mouse capture.
Modified-key shortcuts depend on terminal key reporting and OS shortcuts;
adjust intercepted combinations locally.

## Install Herdr

If Herdr is not installed, follow the latest
[official Herdr TUI installation instructions](https://herdr.dev/tui/docs/install/)
for Linux or macOS.

## Replace the configuration

1. Find your active config: `~/.config/herdr/config.toml` on Linux and macOS,
   unless `HERDR_CONFIG_PATH` overrides it. `herdr --help` shows the resolved path;
   see the [configuration docs](https://herdr.dev/tui/docs/configuration/).
2. Inspect the existing file and any symlink target. Move the file or symlink to
   an unused backup filename (for example, `config.toml.backup`) before copying;
   do not overwrite an earlier backup or modify a symlink's target.
3. From the repository root, copy the supplied file to that location:

   ```sh
   config="${HERDR_CONFIG_PATH:-$HOME/.config/herdr/config.toml}"
   mkdir -p "$(dirname "$config")" &&
     cp -i herdr/config.toml "$config"
   ```

   This replaces the entire configuration rather than merging settings. The copy
   stays usable if this checkout moves or is deleted; repeat the backup and copy
   steps when updating it.
4. Reload through Herdr's **reload config** menu action (`Ctrl+B`, then `q` with
   this configuration). Startup-only settings require a restart.

To revert, replace only the installed copy with your backup at the same active
path, then reload again.
