#!/usr/bin/env python3
"""Switch the Endless arena backgrounds, their Shop thumbnails and the scenery masks to lossy import
(owner decision 2026-09-15: limits APK growth from thirty 941x1672 paintings).

Usage (repo root):  python3 tools/art/set_endless_import_lossy.py   then   tools/validate.sh

Owner-approved exception to "never hand-edit .import files": only compress/mode (-> 1, Lossy) and
compress/lossy_quality (-> LOSSY_QUALITY) change; every other line, including the uid, is kept, and
the script aborts if a uid would change. Run it again after new skins are imported for the first
time (Godot writes lossless defaults for new PNGs).
"""

import glob
import re
import sys

PATTERNS = [
    "assets/art/environment/endless/*.png.import",
    "assets/art/environment/endless/thumbnails/*.png.import",
    "assets/art/environment/endless/masks/*.png.import",
]
LOSSY_QUALITY = "0.8"


def main():
    changed = 0
    files = sorted(path for pattern in PATTERNS for path in glob.glob(pattern))
    for path in files:
        with open(path) as handle:
            text = handle.read()
        uid = re.search(r'^uid=".*"$', text, re.M)
        updated = re.sub(r"^compress/mode=\d+$", "compress/mode=1", text, flags=re.M)
        updated = re.sub(r"^compress/lossy_quality=[\d.]+$",
                         "compress/lossy_quality=" + LOSSY_QUALITY, updated, flags=re.M)
        if uid and re.search(r'^uid=".*"$', updated, re.M).group(0) != uid.group(0):
            sys.exit("uid changed in %s; aborting" % path)
        if updated != text:
            with open(path, "w") as handle:
                handle.write(updated)
            changed += 1
    print("set_endless_import_lossy: %d of %d .import files updated" % (changed, len(files)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
