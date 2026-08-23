# Compone los artefactos finales de las tiendas sobre el arte base generado
# por test/store_assets_test.dart (flutter test --update-goldens).
#
#   python scripts/make_store_assets.py
#
# Salida en store/: app-icon-512.png y feature-graphic-1024x500.png.
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
GOLD = (232, 198, 117)
STEEL = (185, 196, 226)
CREDIT = (143, 160, 201)
CREATOR = "Maximiliano Campissi"


def _font(name_bold: str, name_reg: str, size: int) -> ImageFont.FreeTypeFont:
    for name in (name_bold, name_reg):
        candidate = Path("C:/Windows/Fonts") / name
        if candidate.exists():
            return ImageFont.truetype(str(candidate), size)
    return ImageFont.load_default(size)


def main() -> None:
    out_dir = ROOT / "store"
    out_dir.mkdir(exist_ok=True)

    # Ícono de Play Store: tal cual el golden.
    icon = Image.open(ROOT / "test/goldens/store-icon-512.png")
    icon.save(out_dir / "app-icon-512.png")

    # Feature graphic 1024x500 con tipografía real.
    base = Image.open(ROOT / "test/goldens/store-feature-base.png").convert("RGB")
    draw = ImageDraw.Draw(base)

    title = _font("segoeuib.ttf", "arialbd.ttf", 88)
    subtitle = _font("segoeui.ttf", "arial.ttf", 33)
    credit_label = _font("segoeui.ttf", "arial.ttf", 26)
    credit_name = _font("segoeuib.ttf", "arialbd.ttf", 30)

    x = 440
    draw.text((x, 150), "NEXORA GUARD", font=title, fill=GOLD)
    draw.text(
        (x, 258),
        "Sensor forense de diagnóstico · 100 % local",
        font=subtitle,
        fill=STEEL,
    )
    label_w = draw.textlength("Creado por  ", font=credit_label)
    start_x = x
    draw.text((start_x, 330), "Creado por  ", font=credit_label, fill=CREDIT)
    draw.text((start_x + label_w, 327), CREATOR, font=credit_name, fill=GOLD)

    base.save(out_dir / "feature-graphic-1024x500.png")

    for f in sorted(out_dir.iterdir()):
        print(f"{f.name}  {f.stat().st_size // 1024} KB")


if __name__ == "__main__":
    main()
