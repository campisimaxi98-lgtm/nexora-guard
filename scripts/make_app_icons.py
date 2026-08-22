#!/usr/bin/env python3
# ─────────────────────────────────────────────────────────────────────────────
# Generador del ícono de aplicación — NEXORA GUARD
#
# Fuente de verdad del ícono: los SVG en assets/brand/. No se editan los PNG
# a mano; se regeneran con `python scripts/make_app_icons.py` y se commitean.
#
#   assets/brand/nexora-icon.svg              → ícono completo (fondo + marca)
#   assets/brand/nexora-icon-foreground.svg   → solo la marca (adaptive icon)
#   assets/brand/nexora-icon-monochrome.svg   → marca en blanco (Android 13+)
#
# Salidas:
#   android/app/src/main/res/mipmap-*/ic_launcher.png             (legacy)
#   android/app/src/main/res/mipmap-*/ic_launcher_round.png       (legacy round)
#   android/app/src/main/res/mipmap-*/ic_launcher_foreground.png  (adaptativo)
#   android/app/src/main/res/mipmap-*/ic_launcher_background.png  (adaptativo)
#   android/app/src/main/res/mipmap-*/ic_launcher_monochrome.png  (tema Android 13+)
#   android/app/src/main/res/drawable-nodpi/nexora_splash_logo.png (splash)
#   ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-*.png  (sin alfa)
#   landing/assets/icon-512.png                                   (web / og)
#
# Dependencia única: rsvg-convert (paquete del sistema `librsvg2-bin` en
# Debian/Ubuntu, `librsvg` en Homebrew) + ImageMagick (`convert`) para
# aplanar el canal alfa en los íconos de iOS.
# ─────────────────────────────────────────────────────────────────────────────
from __future__ import annotations

import shutil
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BRAND = ROOT / "assets/brand"
ANDROID_RES = ROOT / "android/app/src/main/res"
IOS_ICONS = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"

ICON_SVG = BRAND / "nexora-icon.svg"
FOREGROUND_SVG = BRAND / "nexora-icon-foreground.svg"
MONOCHROME_SVG = BRAND / "nexora-icon-monochrome.svg"

BG_HEX = "#0A0F24"  # fondo NEXORA (azul muy oscuro), usado para aplanar iOS

# Densidades Android: (carpeta, px del ícono legacy/adaptativo — ambos
# lienzos comparten tamaño porque el SVG ya incluye el margen de seguridad).
DENSITIES = [
    ("mdpi", 48),
    ("hdpi", 72),
    ("xhdpi", 96),
    ("xxhdpi", 144),
    ("xxxhdpi", 192),
]

IOS_SIZES = {
    "Icon-App-20x20@1x.png": 20,
    "Icon-App-20x20@2x.png": 40,
    "Icon-App-20x20@3x.png": 60,
    "Icon-App-29x29@1x.png": 29,
    "Icon-App-29x29@2x.png": 58,
    "Icon-App-29x29@3x.png": 87,
    "Icon-App-40x40@1x.png": 40,
    "Icon-App-40x40@2x.png": 80,
    "Icon-App-40x40@3x.png": 120,
    "Icon-App-60x60@2x.png": 120,
    "Icon-App-60x60@3x.png": 180,
    "Icon-App-76x76@1x.png": 76,
    "Icon-App-76x76@2x.png": 152,
    "Icon-App-83.5x83.5@2x.png": 167,
    "Icon-App-1024x1024@1x.png": 1024,
}


def _check_deps() -> None:
    for tool in ("rsvg-convert", "convert"):
        if shutil.which(tool) is None:
            raise SystemExit(
                f"Falta '{tool}'. Instalá librsvg2-bin (rsvg-convert) e "
                "ImageMagick (convert) antes de correr este script."
            )


def _rsvg(svg: Path, size: int, out: Path) -> None:
    out.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(
        ["rsvg-convert", "-w", str(size), "-h", str(size), str(svg), "-o", str(out)],
        check=True,
    )
    print(f"  {out.relative_to(ROOT).as_posix()}  {size}x{size}")


def _flatten_for_ios(png: Path, size: int, out: Path) -> None:
    """iOS rechaza canales alfa en el ícono de app: se aplana sobre BG_HEX."""
    out.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(
        [
            "convert", str(png),
            "-background", BG_HEX, "-flatten",
            "-resize", f"{size}x{size}",
            str(out),
        ],
        check=True,
    )
    print(f"  {out.relative_to(ROOT).as_posix()}  {size}x{size}")


def main() -> None:
    _check_deps()

    print("Android — íconos legacy y adaptativos:")
    for folder, px in DENSITIES:
        out = ANDROID_RES / f"mipmap-{folder}"
        _rsvg(ICON_SVG, px, out / "ic_launcher.png")
        _rsvg(ICON_SVG, px, out / "ic_launcher_round.png")
        _rsvg(FOREGROUND_SVG, px, out / "ic_launcher_foreground.png")
        _rsvg(MONOCHROME_SVG, px, out / "ic_launcher_monochrome.png")
        # Fondo sólido de marca para la capa "background" del adaptive icon.
        subprocess.run(
            ["convert", "-size", f"{px}x{px}", f"xc:{BG_HEX}",
             str(out / "ic_launcher_background.png")],
            check=True,
        )
        print(f"  {(out / 'ic_launcher_background.png').relative_to(ROOT).as_posix()}  {px}x{px}")

    print("Android — splash screen:")
    _rsvg(ICON_SVG, 1024, ANDROID_RES / "drawable-nodpi/nexora_splash_logo.png")

    print("iOS — AppIcon (sin canal alfa):")
    tmp = ROOT / "build/_tmp_icon_1024.png"
    _rsvg(ICON_SVG, 1024, tmp)
    for name, px in IOS_SIZES.items():
        _flatten_for_ios(tmp, px, IOS_ICONS / name)
    tmp.unlink(missing_ok=True)

    print("Web / landing:")
    _rsvg(ICON_SVG, 512, ROOT / "landing/assets/icon-512.png")


if __name__ == "__main__":
    main()
