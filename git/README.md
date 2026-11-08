# Git aliases

[`aliases.gitconfig`](aliases.gitconfig) contains shared, shell-independent Git
aliases. Install the complete file rather than copying individual definitions so
future additions, changes and removals use the same installation process.
Git is managed separately; bootstrap does not configure it.

## Install on Linux or macOS

Requires Git 2.30+ for `--fixed-value`. Before first installation, inspect your
existing aliases/includes and back up your global Git config and any existing
managed copy. Run from the repository root:

```sh
file="${XDG_CONFIG_HOME:-$HOME/.config}/git/dotfiles-aliases.gitconfig"
mkdir -p "${file%/*}" &&
  cp git/aliases.gitconfig "$file" &&
  git config --global --fixed-value --replace-all include.path "$file" "$file"
```

This replaces the project-managed copy and registers its include without
duplicating it or replacing unrelated includes/settings. The destination uses
`XDG_CONFIG_HOME` when set, otherwise `~/.config`, on both platforms.

The installed file is independent of this checkout: moving or deleting the
repository will not break the aliases. It does **not** update automatically.

## Update or customize

After updating your checkout, rerun the installation commands to refresh the
entire managed file. Edits made directly to the installed copy will be replaced.

Keep personal overrides in your own Git configuration, not the managed file.
Later definitions win, and repository-local settings override global settings;
existing definitions can therefore override the supplied aliases.

## Verify

Inspect the active aliases and their configuration sources, then run the aliases
you want to use in a Git repository:

```sh
git config --show-origin --show-scope --get-regexp '^alias\.'
```

## Remove

Remove only this project's global include:

```sh
file="${XDG_CONFIG_HOME:-$HOME/.config}/git/dotfiles-aliases.gitconfig"
git config --global --fixed-value --unset-all include.path "$file"
```

Use the path chosen during installation if you have since changed
`XDG_CONFIG_HOME`. Git returns a nonzero status if the include is already absent.
You may then delete the managed copy if no other configuration includes it.
Unrelated aliases, includes and other settings are left intact.
