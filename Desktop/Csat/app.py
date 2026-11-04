import copy
import hmac
import html
import json
import logging
import os
import re
import secrets
import sqlite3
import uuid
from datetime import datetime, timezone
from contextlib import closing
from html.parser import HTMLParser
from pathlib import Path

from flask import (
    Flask,
    abort,
    flash,
    redirect,
    render_template,
    request,
    session,
    url_for,
)
from markupsafe import Markup


ROOT = Path(__file__).resolve().parent
DATABASE = Path(os.environ.get("DATABASE_PATH", ROOT / "instance" / "reclamations.sqlite3"))
app = Flask(__name__)
APP_ENV = os.environ.get("APP_ENV", "development")
SECRET_KEY = os.environ.get("SECRET_KEY")
if APP_ENV == "production" and not SECRET_KEY:
    raise RuntimeError("SECRET_KEY doit être défini en production.")
app.config.update(
    SECRET_KEY=SECRET_KEY or secrets.token_hex(32),
    SESSION_COOKIE_HTTPONLY=True,
    SESSION_COOKIE_SAMESITE="Lax",
    SESSION_COOKIE_SECURE=APP_ENV == "production",
    MAX_CONTENT_LENGTH=32 * 1024,
)
logging.basicConfig(level=os.environ.get("LOG_LEVEL", "INFO"))


class SafeContentParser(HTMLParser):
    """Keep only the small set of formatting tags used by the source guide."""

    allowed_tags = {"p", "h4", "ul", "li", "b", "strong", "em", "table", "tr", "th", "td", "div"}

    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.output = []
        self.open_tags = []

    def handle_starttag(self, tag, attrs):
        if tag not in self.allowed_tags:
            return
        attributes = ""
        if tag == "div":
            css_class = dict(attrs).get("class")
            if css_class in {"nb", "tw"}:
                attributes = f' class="{css_class}"'
        self.output.append(f"<{tag}{attributes}>")
        self.open_tags.append(tag)

    def handle_startendtag(self, tag, attrs):
        self.handle_starttag(tag, attrs)
        self.handle_endtag(tag)

    def handle_endtag(self, tag):
        if tag not in self.open_tags:
            return
        while self.open_tags:
            current = self.open_tags.pop()
            self.output.append(f"</{current}>")
            if current == tag:
                break

    def handle_data(self, data):
        self.output.append(html.escape(data))

    def finish(self):
        while self.open_tags:
            self.output.append(f"</{self.open_tags.pop()}>")
        return Markup("".join(self.output))


def safe_guide_html(value):
    parser = SafeContentParser()
    parser.feed(value)
    return parser.finish()


def load_content():
    with (ROOT / "data" / "contenu.json").open(encoding="utf-8") as content_file:
        return json.load(content_file)


CONTENT = load_content()


def initialize_database():
    DATABASE.parent.mkdir(parents=True, exist_ok=True)
    with closing(sqlite3.connect(DATABASE)) as connection:
        with connection:
            connection.execute(
                """
                CREATE TABLE IF NOT EXISTS complaints (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    ticket TEXT NOT NULL UNIQUE,
                    name TEXT NOT NULL,
                    phone TEXT NOT NULL,
                    insured_number TEXT NOT NULL DEFAULT '',
                    subject TEXT NOT NULL,
                    message TEXT NOT NULL,
                    created_at TEXT NOT NULL
                )
                """
            )


def prepare_section(section):
    result = copy.deepcopy(section)
    for item in result.get("items", []):
        item["safe_body"] = safe_guide_html(item["b"])
    return result


def configured_platforms():
    platforms = copy.deepcopy(CONTENT["site"]["platforms"])
    whatsapp_number = os.environ.get(
        "WHATSAPP_NUMBER", CONTENT["site"]["whatsapp_number"]
    )
    whatsapp_digits = re.sub(r"\D", "", whatsapp_number)
    play_store = os.environ.get(
        "GOOGLE_PLAY_URL", CONTENT["site"]["google_play_url"]
    )
    app_store = os.environ.get("APP_STORE_URL", CONTENT["site"]["app_store_url"])
    for item in platforms:
        if item["id"] == "whatsapp":
            item["url"] = f"https://wa.me/{whatsapp_digits}" if whatsapp_digits else ""
        elif item["id"] == "google-play":
            item["url"] = play_store
        elif item["id"] == "app-store":
            item["url"] = app_store
    return platforms


def csrf_token():
    if "csrf_token" not in session:
        session["csrf_token"] = secrets.token_urlsafe(32)
    return session["csrf_token"]


@app.context_processor
def shared_template_values():
    return {"csrf_token": csrf_token, "site_name": CONTENT["site"]["name"]}


@app.after_request
def add_security_headers(response):
    response.headers.setdefault("X-Content-Type-Options", "nosniff")
    response.headers.setdefault("X-Frame-Options", "DENY")
    response.headers.setdefault("Referrer-Policy", "strict-origin-when-cross-origin")
    response.headers.setdefault(
        "Content-Security-Policy",
        "default-src 'self'; img-src 'self' data:; style-src 'self'; "
        "script-src 'self'; base-uri 'self'; form-action 'self'; frame-ancestors 'none'",
    )
    return response


@app.get("/service-worker.js")
def service_worker():
    response = app.send_static_file("service-worker.js")
    response.headers["Service-Worker-Allowed"] = "/"
    response.headers["Cache-Control"] = "no-cache"
    return response


@app.get("/offline.html")
def offline_page():
    return app.send_static_file("offline.html")


@app.get("/qr")
def legacy_qr_redirect():
    response = redirect(url_for("home"), code=302)
    response.headers["Cache-Control"] = "no-store"
    return response


@app.get("/")
def home():
    sections = {
        key: {**prepare_section(section), "key": key}
        for key, section in CONTENT.items()
        if key in {"sal", "ind", "ent"}
    }
    return render_template(
        "index.html",
        sections=sections,
        platforms=CONTENT["site"]["platforms"],
        complaints=CONTENT["site"]["complaint_methods"],
    )


@app.get("/rubrique/<slug>")
def rubrique(slug):
    if slug == "plateformes":
        platforms = configured_platforms()
        appointment_url = CONTENT["site"]["appointment_url"]
        return render_template(
            "platforms.html",
            platforms=platforms,
            appointment_url=appointment_url,
            section=CONTENT["site"]["platforms_section"],
        )
    if slug not in {"sal", "ind", "ent"}:
        abort(404)
    section = prepare_section(CONTENT[slug])
    return render_template("section.html", section=section, slug=slug)


@app.route("/reclamation", methods=["GET", "POST"])
def reclamation():
    values = {"name": "", "phone": "", "insured_number": "", "subject": "", "message": ""}
    if request.method == "POST":
        values = {
            key: request.form.get(key, "").strip()
            for key in values
        }
        submitted_token = request.form.get("csrf_token", "")
        if not hmac.compare_digest(submitted_token, session.get("csrf_token", "")):
            abort(400, description="Votre session a expiré. Rechargez la page puis réessayez.")

        errors = []
        limits = {"name": 100, "phone": 30, "insured_number": 40, "subject": 120, "message": 5000}
        required = ("name", "phone", "subject", "message")
        for field in required:
            if not values[field]:
                errors.append("Veuillez renseigner tous les champs obligatoires.")
                break
        if len(values["name"]) > limits["name"]:
            errors.append("Le nom ne doit pas dépasser 100 caractères.")
        if len(values["phone"]) > limits["phone"] or not re.fullmatch(
            r"[0-9+().\s-]{6,30}", values["phone"]
        ):
            errors.append("Saisissez un numéro de téléphone valide.")
        if len(values["insured_number"]) > limits["insured_number"]:
            errors.append("Le numéro d’assuré ne doit pas dépasser 40 caractères.")
        if len(values["subject"]) > limits["subject"]:
            errors.append("L’objet ne doit pas dépasser 120 caractères.")
        if len(values["message"]) > limits["message"]:
            errors.append("Le message ne doit pas dépasser 5 000 caractères.")
        if errors:
            for error in errors:
                flash(error, "error")
            return render_template("complaint.html", values=values), 400

        requested_ticket = request.form.get("offline_ticket", "")
        ticket = (
            requested_ticket
            if re.fullmatch(r"CNPS-\d{4}-[A-F0-9]{8}", requested_ticket)
            else f"CNPS-{datetime.now(timezone.utc):%Y}-{uuid.uuid4().hex[:8].upper()}"
        )
        try:
            with closing(sqlite3.connect(DATABASE, timeout=10)) as connection:
                with connection:
                    connection.execute(
                        """
                        INSERT OR IGNORE INTO complaints
                            (ticket, name, phone, insured_number, subject, message, created_at)
                        VALUES (?, ?, ?, ?, ?, ?, ?)
                        """,
                        (
                            ticket,
                            values["name"],
                            values["phone"],
                            values["insured_number"],
                            values["subject"],
                            values["message"],
                            datetime.now(timezone.utc).isoformat(),
                        ),
                    )
        except sqlite3.Error:
            app.logger.exception("Échec de l’enregistrement d’une réclamation")
            flash("L’enregistrement a échoué. Veuillez réessayer ou appeler le 1396.", "error")
            return render_template("complaint.html", values=values), 500
        session.pop("csrf_token", None)
        session["confirmation_ticket"] = ticket
        return redirect(url_for("reclamation"), code=303)

    ticket = session.pop("confirmation_ticket", None)
    response = app.make_response(
        render_template("complaint.html", values=values, ticket=ticket)
    )
    response.headers["Cache-Control"] = "no-store"
    return response


@app.errorhandler(400)
def bad_request(error):
    return render_template("error.html", code=400, message=error.description), 400


@app.errorhandler(404)
def not_found(_error):
    return render_template(
        "error.html", code=404, message="Cette page n’existe pas ou a été déplacée."
    ), 404


@app.errorhandler(500)
def internal_error(_error):
    return render_template(
        "error.html",
        code=500,
        message="Une erreur est survenue. Veuillez réessayer dans quelques instants.",
    ), 500


initialize_database()


if __name__ == "__main__":
    app.run(
        host=os.environ.get("HOST", "127.0.0.1"),
        port=int(os.environ.get("PORT", "5000")),
        debug=os.environ.get("FLASK_DEBUG") == "1",
    )
