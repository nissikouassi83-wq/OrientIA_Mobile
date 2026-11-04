import base64
import html
import ipaddress
import os
from pathlib import Path
from urllib.parse import urlsplit

import qrcode
from qrcode.constants import ERROR_CORRECT_H
from qrcode.image.svg import SvgPathImage


ROOT = Path(__file__).resolve().parent
PUBLIC_URL = os.environ.get("URL_PUBLIQUE", "").strip()
try:
    parsed_url = urlsplit(PUBLIC_URL)
    hostname = parsed_url.hostname or ""
except ValueError:
    raise SystemExit("URL_PUBLIQUE n’est pas une URL valide.")
try:
    address = ipaddress.ip_address(hostname)
except ValueError:
    address = None

if (
    parsed_url.scheme != "https"
    or not hostname
    or parsed_url.username
    or parsed_url.password
    or hostname == "localhost"
    or hostname.endswith((".localhost", ".local", ".test"))
    or (address is not None and not address.is_global)
    or "." not in hostname
):
    raise SystemExit(
        "Définissez URL_PUBLIQUE avec l’adresse HTTPS publique du portail "
        "(pas une adresse locale)."
    )

qr = qrcode.QRCode(
    version=None,
    error_correction=ERROR_CORRECT_H,
    box_size=32,
    border=4,
)
qr.add_data(PUBLIC_URL)
qr.make(fit=True)

png = qr.make_image(fill_color="#111827", back_color="white").convert("RGB")
logo_path = ROOT / "static" / "cnps_logo.jpeg"
if logo_path.is_file():
    from PIL import Image

    logo = Image.open(logo_path).convert("RGB")
    size = max(1, png.width // 6)
    logo.thumbnail((size, size))
    margin = max(8, png.width // 80)
    background = Image.new("RGB", (logo.width + 2 * margin, logo.height + 2 * margin), "white")
    background.paste(logo, (margin, margin))
    position = ((png.width - background.width) // 2, (png.height - background.height) // 2)
    png.paste(background, position)
png.save(ROOT / "static" / "qr_cnps.png", optimize=True)
qr.make_image(image_factory=SvgPathImage).save(ROOT / "static" / "qr_cnps.svg")

png_data = base64.b64encode((ROOT / "static" / "qr_cnps.png").read_bytes()).decode("ascii")
safe_url = html.escape(PUBLIC_URL, quote=True)
printable_page = f"""<!doctype html>
<html lang="fr">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="color-scheme" content="light">
  <title>QR code du portail CNPS</title>
  <style>
    * {{ box-sizing: border-box; }}
    body {{
      min-height: 100vh;
      margin: 0;
      padding: 32px 16px;
      display: grid;
      place-items: center;
      background: #eaf1fa;
      color: #17243b;
      font: 16px/1.5 "Segoe UI", Arial, sans-serif;
    }}
    main {{
      width: min(100%, 520px);
      padding: 24px;
      border-radius: 18px;
      background: #fff;
      box-shadow: 0 12px 32px rgb(23 53 89 / 12%);
      text-align: center;
    }}
    h1 {{ margin: 0; color: #fff; font-size: 1.35rem; }}
    header {{
      margin: -24px -24px 20px;
      padding: 20px 24px;
      border-radius: 18px 18px 0 0;
      background: #583083;
      text-align: left;
    }}
    header p {{ margin: 5px 0 0; color: #f0e9f8; }}
    img {{ display: block; width: min(100%, 360px); height: auto; margin: 0 auto; }}
    .url {{ margin: 12px 0 0; overflow-wrap: anywhere; color: #17467e; }}
    a {{ color: inherit; }}
    .hint {{ margin: 14px 0 0; color: #596a7d; font-size: .9rem; }}
    @media print {{
      @page {{ margin: 12mm; }}
      body {{ min-height: auto; padding: 0; background: #fff; }}
      main {{ width: 100%; padding: 14px; box-shadow: none; }}
      header {{ margin: -14px -14px 14px; }}
      img {{ width: min(100%, 95mm); }}
      .hint {{ display: none; }}
    }}
  </style>
</head>
<body>
  <main>
    <header>
      <h1>Accéder au portail CNPS</h1>
      <p>Scannez ce code pour ouvrir le portail d’informations CNPS sur votre téléphone.</p>
    </header>
    <img src="data:image/png;base64,{png_data}" alt="QR code ouvrant le portail CNPS">
    <p class="url"><a href="{safe_url}">{safe_url}</a></p>
    <p class="hint">Cette page est un support indépendant à imprimer. Le code ouvre directement le portail CNPS.</p>
  </main>
</body>
</html>
"""
(ROOT / "qr_cnps.html").write_text(printable_page, encoding="utf-8")
print(f"QR PNG, SVG et page autonome à imprimer générés pour {PUBLIC_URL}")
