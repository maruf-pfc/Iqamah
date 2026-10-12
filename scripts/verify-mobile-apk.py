#!/usr/bin/env python3
"""Reject APKs that package stale web assets. No Android device or SDK needed."""
import hashlib
import json
import sys
from pathlib import Path
from zipfile import ZipFile


def verify(apk: Path, expected: Path, app_version: str) -> str:
    with ZipFile(apk) as archive:
        bundled = archive.read("assets/flutter_assets/assets/web/index.html")
    if bundled != expected.read_bytes():
        raise ValueError("APK contains stale web assets. Clean the Flutter build, rebuild, and verify again.")
    if app_version.encode() not in bundled:
        raise ValueError("Bundled web asset is missing the current application version.")
    return hashlib.sha256(bundled).hexdigest()


if __name__ == "__main__":
    root = Path(__file__).resolve().parent.parent
    apk = Path(sys.argv[1]) if len(sys.argv) > 1 else root / "mobile/build/app/outputs/flutter-apk/app-debug.apk"
    version = json.loads((root / "client/package.json").read_text())["version"]
    try:
        digest = verify(apk, root / "mobile/assets/web/index.html", version)
    except (OSError, KeyError, ValueError) as error:
        sys.exit(str(error))
    print(f"Verified {apk}: current web asset, {version}, SHA-256 {digest}")
