"""Parse structured configuration using the standard library (Python 3.11+)."""

import json
from pathlib import Path
import tomllib

root = Path(__file__).resolve().parents[1]
for path in sorted((root / "nvim").rglob("*.json")):
    with path.open() as file:
        json.load(file)
    print(f"JSON OK: {path.relative_to(root)}")
for path in [root / "herdr/config.toml", root / "nvim/stylua.toml"]:
    with path.open("rb") as file:
        tomllib.load(file)
    print(f"TOML OK: {path.relative_to(root)}")
