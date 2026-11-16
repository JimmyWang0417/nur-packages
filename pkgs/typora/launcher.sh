#!@shell@
set -eu

if [ -z "${HOME:-}" ]; then
  echo 'typora: HOME must be set' >&2
  exit 1
fi

settings_dir="$HOME/.config/typora_plugin"
settings_file="$settings_dir/settings.user.toml"
if ! mkdir -p -- "$settings_dir"; then
  echo "typora: cannot create $settings_dir" >&2
  exit 1
fi
if [ ! -e "$settings_file" ] && [ ! -L "$settings_file" ]; then
  (umask 077; set -C; : > "$settings_file") 2>/dev/null || true
fi
if [ ! -f "$settings_file" ] || [ ! -r "$settings_file" ]; then
  echo "typora: settings must be a readable file: $settings_file" >&2
  exit 1
fi

exec @program@ @extraFlags@ "$@"
