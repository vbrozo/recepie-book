#!/usr/bin/env python3
"""Post-build patch: point CanvasKit at the locally-bundled canvaskit/
folder instead of Google's CDN (gstatic.com), so the deployed app doesn't
depend on an external host to render once it's loaded.

`flutter build web` regenerates web/flutter_bootstrap.js from scratch
every run (a checked-in override under web/ gets clobbered), so this runs
as a separate step against the build output right after `flutter build web`:

    flutter build web --release --base-href=/recepie-book/
    python3 tool/patch_canvaskit_local.py build/web/flutter_bootstrap.js
"""
import sys

MARKER = "_flutter.loader.load({"
# Note: the bare string "canvasKitBaseUrl" also appears in flutter.js's own
# (unpatched) loader logic as a property-name check, so detecting "already
# patched" needs the literal value we inject, not just the property name.
ALREADY_PATCHED = 'canvasKitBaseUrl: "canvaskit/"'


def patch(path: str) -> None:
    with open(path, encoding="utf-8") as f:
        content = f.read()

    if ALREADY_PATCHED in content:
        print(f"{path}: already patched, skipping")
        return

    idx = content.rindex(MARKER)
    insert_at = content.index("});", idx)
    patched = (
        content[:insert_at]
        + ',\n  config: {\n    canvasKitBaseUrl: "canvaskit/"\n  }\n'
        + content[insert_at:]
    )

    with open(path, "w", encoding="utf-8") as f:
        f.write(patched)
    print(f"{path}: patched canvasKitBaseUrl -> canvaskit/")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(1)
    patch(sys.argv[1])
