"""
UTH Digital Systems — Alumni REST API (Python / Flask).

Exposes 8 endpoints under /api/v1/:

  #1  POST   /api/v1/alumni/                     register a new alumnus
  #2  POST   /api/v1/auth/login                  JWT login
  #3  GET    /api/v1/alumni/count                count of alumni
  #4  GET    /api/v1/alumni/<id>/jobs            jobs of one alumnus
  #5  GET    /api/v1/alumni/                     all alumni + current job
  #6a DELETE /api/v1/alumni/<id>/jobs/<jid>      delete (nested form)   [auth]
  #6b DELETE /api/v1/jobs/<jid>                  delete (direct form)   [auth]
  #7a PUT    /api/v1/alumni/<id>/jobs/<jid>      update (nested form)   [auth]
  #7b PUT    /api/v1/jobs/<jid>                  update (direct form)   [auth]
  #8  GET    /api/v1/alumni/search?...           multi-criteria search,
                                                 pagination 4/page,
                                                 JSON or XML (?format=xml)

Run:
    python app.py
"""
import math
import re
import time

import bcrypt
from flask import Flask, request, jsonify, make_response, g
from flask_cors import CORS
from sqlalchemy import text

import config
from database import SessionLocal
from jwt_helper import issue_token, require_auth
from xml_helper import to_xml


app = Flask(__name__)
# Allow the front-end (served by Apache on a different port/host) to call us.
CORS(app, resources={r"/api/*": {"origins": "*"}}, expose_headers=["Content-Type"])

@app.before_request
def _open_session():
    g.db = SessionLocal()


@app.teardown_request
def _close_session(exc):
    db = g.pop("db", None)
    if db is not None:
        db.close()
    SessionLocal.remove()

EMAIL_RE = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")
PER_PAGE = 4


def _err(message: str, status: int = 400):
    return jsonify({"error": message}), status


def _row_to_alumnus(r) -> dict:
    """Shape a flat alumni+current_job row from a SELECT into a nested dict."""
    a = {
        "id":              int(r.id),
        "first_name":      r.first_name,
        "last_name":       r.last_name,
        "email":           r.email,
        "enrollment_year": int(r.enrollment_year),
        "graduation_year": int(r.graduation_year) if r.graduation_year is not None else None,
        "country":         r.country,
        "current_job":     None,
    }
    if r.current_job_id:
        a["current_job"] = {
            "id":        int(r.current_job_id),
            "title":     r.current_job_title,
            "company":   r.current_job_company,
            "city":      r.current_job_city,
            "country":   r.current_job_country,
            "latitude":  float(r.current_job_latitude),
            "longitude": float(r.current_job_longitude),
        }
        # GET /alumni includes start_date in the popup; search results don't need it
        if hasattr(r, "current_job_start") and r.current_job_start is not None:
            a["current_job"]["start_date"] = _date_str(r.current_job_start)
    return a


def _date_str(v):
    """Serialize a date/datetime/str/None into an ISO string or None."""
    if v is None:
        return None
    if hasattr(v, "isoformat"):
        return v.isoformat()
    return str(v)


# ===========================================================================
# Endpoint #1: POST /api/v1/alumni/   (register)
# Endpoint #5: GET  /api/v1/alumni/   (list all + current job)
# ===========================================================================

@app.route("/api/v1/alumni/", methods=["GET", "POST"])
@app.route("/api/v1/alumni",  methods=["GET", "POST"])
def alumni_collection():
    if request.method == "GET":
        # ---- #5: list all alumni with current job (LEFT JOIN) ----
        sql = text("""
            SELECT  a.id, a.first_name, a.last_name, a.email,
                    a.enrollment_year, a.graduation_year, a.country,
                    j.id        AS current_job_id,
                    j.title     AS current_job_title,
                    j.company   AS current_job_company,
                    j.city      AS current_job_city,
                    j.country   AS current_job_country,
                    j.latitude  AS current_job_latitude,
                    j.longitude AS current_job_longitude,
                    j.start_date AS current_job_start
            FROM alumni a
            LEFT JOIN jobs j
                   ON j.alumni_id = a.id AND j.is_current = 1
            ORDER BY a.last_name, a.first_name
        """)
        rows = g.db.execute(sql).all()
        return jsonify([_row_to_alumnus(r) for r in rows])

    # ---- #1: register ----
    body = request.get_json(silent=True) or {}
    required = ["first_name", "last_name", "email", "password",
                "enrollment_year", "country"]
    for field in required:
        if not body.get(field):
            return _err(f"Field '{field}' is required", 422)

    if not EMAIL_RE.match(body["email"]):
        return _err("Invalid email", 422)
    if len(body["password"]) < 6:
        return _err("Password must be at least 6 characters", 422)

    try:
        enroll = int(body["enrollment_year"])
    except (TypeError, ValueError):
        return _err("enrollment_year must be an integer", 422)

    grad = body.get("graduation_year")
    if grad in ("", None):
        grad = None
    else:
        try:
            grad = int(grad)
        except (TypeError, ValueError):
            return _err("graduation_year must be an integer", 422)

    if enroll < 1990 or enroll > 2100:
        return _err("enrollment_year out of range", 422)
    if grad is not None and grad < enroll:
        return _err("graduation_year cannot precede enrollment_year", 422)

    # uniqueness
    existing = g.db.execute(
        text("SELECT id FROM alumni WHERE email = :e"), {"e": body["email"]}
    ).first()
    if existing:
        return _err("Email already registered", 409)

    password_hash = bcrypt.hashpw(
        body["password"].encode("utf-8"), bcrypt.gensalt()
    ).decode("utf-8")

    res = g.db.execute(
        text("""INSERT INTO alumni
                (first_name, last_name, email, password_hash,
                 enrollment_year, graduation_year, country)
              VALUES (:fn, :ln, :em, :ph, :ey, :gy, :ctry)"""),
        {
            "fn": body["first_name"],
            "ln": body["last_name"],
            "em": body["email"],
            "ph": password_hash,
            "ey": enroll,
            "gy": grad,
            "ctry": body["country"],
        },
    )
    g.db.commit()
    new_id = res.lastrowid

    return jsonify({
        "id": int(new_id),
        "first_name": body["first_name"],
        "last_name":  body["last_name"],
        "email":      body["email"],
        "enrollment_year": enroll,
        "graduation_year": grad,
        "country": body["country"],
        "message": "Alumnus registered successfully",
    }), 201


# ===========================================================================
# Endpoint #3: GET /api/v1/alumni/count


@app.route("/api/v1/alumni/count", methods=["GET"])
def alumni_count():
    n = g.db.execute(text("SELECT COUNT(*) AS n FROM alumni")).scalar_one()
    return jsonify({"count": int(n)})


# ===========================================================================
# Endpoint #2: POST /api/v1/auth/login  (JWT)
# ===========================================================================

@app.route("/api/v1/auth/login", methods=["POST"])
def login():
    body= request.get_json(silent=True) or {}
    email = (body.get("email") or "").strip()
    pw= body.get("password") or ""

    if not email or not pw:
        return _err("email and password are required", 422)

    user = g.db.execute(
        text("SELECT * FROM alumni WHERE email = :e"), {"e": email}
    ).mappings().first()

    if not user or not bcrypt.checkpw(pw.encode("utf-8"),
                                      user["password_hash"].encode("utf-8")):
        time.sleep(0.2)  # marginal timing-attack mitigation
        return _err("Invalid credentials", 401)

    token = issue_token(int(user["id"]), user["email"])

    return jsonify({
        "token": token,
        "user": {
            "id":              int(user["id"]),
            "first_name":      user["first_name"],
            "last_name":       user["last_name"],
            "email":           user["email"],
            "enrollment_year": int(user["enrollment_year"]),
            "graduation_year": int(user["graduation_year"]) if user["graduation_year"] is not None else None,
            "country":         user["country"],
        },
    })


# ===========================================================================
# Endpoints #4 / #6 / #7 (nested form): /api/v1/alumni/<id>/jobs[/<jid>]
# ===========================================================================

@app.route("/api/v1/alumni/<int:alumni_id>/jobs",  methods=["GET", "POST"])
@app.route("/api/v1/alumni/<int:alumni_id>/jobs/", methods=["GET", "POST"])
def jobs_of_alumnus(alumni_id: int):
    # confirm alumnus exists
    exists = g.db.execute(
        text("SELECT id FROM alumni WHERE id = :i"), {"i": alumni_id}
    ).first()
    if not exists:
        return _err("Alumnus not found", 404)

    if request.method == "GET":
        # ---- #4 ----
        rows = g.db.execute(text("""
            SELECT id, title, company, city, country,
                   latitude, longitude, start_date, end_date, is_current
            FROM jobs WHERE alumni_id = :i
            ORDER BY is_current DESC, start_date DESC
        """), {"i": alumni_id}).mappings().all()

        return jsonify([{
            "id":         int(j["id"]),
            "title":      j["title"],
            "company":    j["company"],
            "city":       j["city"],
            "country":    j["country"],
            "latitude":   float(j["latitude"]),
            "longitude":  float(j["longitude"]),
            "start_date": _date_str(j["start_date"]),
            "end_date":   _date_str(j["end_date"]),
            "is_current": bool(j["is_current"]),
        } for j in rows])

    # POST -> create new job (auth required, must be self)
    return _create_job_for_alumnus(alumni_id)


@require_auth
def _create_job_for_alumnus(alumni_id: int, *, auth_id: int):
    if auth_id != alumni_id:
        return _err("Forbidden: can only manage your own jobs", 403)

    body = request.get_json(silent=True) or {}
    required = ["title", "company", "city", "country",
                "latitude", "longitude", "start_date"]
    for f in required:
        if body.get(f) in (None, ""):
            return _err(f"Field '{f}' is required", 422)

    is_current = 1 if body.get("is_current") else 0

    try:
        if is_current:
            g.db.execute(
                text("UPDATE jobs SET is_current = 0 WHERE alumni_id = :a"),
                {"a": alumni_id},
            )
        res = g.db.execute(text("""
            INSERT INTO jobs
              (alumni_id, title, company, city, country,
               latitude, longitude, start_date, end_date, is_current)
            VALUES
              (:a, :t, :co, :ci, :ctry, :lat, :lng, :sd, :ed, :ic)
        """), {
            "a":   alumni_id,
            "t":   body["title"],
            "co":  body["company"],
            "ci":  body["city"],
            "ctry": body["country"],
            "lat": float(body["latitude"]),
            "lng": float(body["longitude"]),
            "sd":  body["start_date"],
            "ed":  body.get("end_date") or None,
            "ic":  is_current,
        })
        g.db.commit()
        return jsonify({"id": int(res.lastrowid), "message": "Job created"}), 201
    except Exception as e:
        g.db.rollback()
        return _err(f"DB error: {e}", 500)


# Nested PUT/DELETE  /api/v1/alumni/<id>/jobs/<jid>
@app.route("/api/v1/alumni/<int:alumni_id>/jobs/<int:job_id>",
           methods=["PUT", "DELETE"])
@require_auth
def nested_job_modify(alumni_id: int, job_id: int, *, auth_id: int):
    if auth_id != alumni_id:
        return _err("Forbidden: can only manage your own jobs", 403)

    job = g.db.execute(
        text("SELECT id FROM jobs WHERE id = :j AND alumni_id = :a"),
        {"j": job_id, "a": alumni_id},
    ).first()
    if not job:
        return _err("Job not found for this alumnus", 404)

    if request.method == "DELETE":
        g.db.execute(text("DELETE FROM jobs WHERE id = :j"), {"j": job_id})
        g.db.commit()
        return jsonify({"id": job_id, "message": "Job deleted"})

    return _update_job(job_id, alumni_id)


# ===========================================================================
# Endpoints #6b / #7b (direct form): /api/v1/jobs/<jid>
# ===========================================================================

@app.route("/api/v1/jobs/<int:job_id>", methods=["PUT", "DELETE"])
@require_auth
def direct_job_modify(job_id: int, *, auth_id: int):
    job = g.db.execute(
        text("SELECT alumni_id FROM jobs WHERE id = :j"), {"j": job_id}
    ).first()
    if not job:
        return _err("Job not found", 404)
    if auth_id != int(job.alumni_id):
        return _err("Forbidden: this job does not belong to you", 403)

    if request.method == "DELETE":
        g.db.execute(text("DELETE FROM jobs WHERE id = :j"), {"j": job_id})
        g.db.commit()
        return jsonify({"id": job_id, "message": "Job deleted"})

    return _update_job(job_id, int(job.alumni_id))


def _update_job(job_id: int, alumni_id: int):
    body = request.get_json(silent=True) or {}
    allowed = ["title", "company", "city", "country", "latitude",
               "longitude", "start_date", "end_date", "is_current"]
    sets = {col: body[col] for col in allowed if col in body}
    if not sets:
        return _err("Nothing to update", 422)

    if "is_current" in sets:
        sets["is_current"] = 1 if sets["is_current"] else 0

    try:
        if sets.get("is_current") == 1:
            g.db.execute(
                text("UPDATE jobs SET is_current=0 "
                     "WHERE alumni_id = :a AND id <> :j"),
                {"a": alumni_id, "j": job_id},
            )
        set_clause = ", ".join(f"{k} = :{k}" for k in sets.keys())
        params = dict(sets)
        params["j"] = job_id
        g.db.execute(text(f"UPDATE jobs SET {set_clause} WHERE id = :j"), params)
        g.db.commit()
        return jsonify({"id": job_id, "message": "Job updated"})
    except Exception as e:
        g.db.rollback()
        return _err(f"DB error: {e}", 500)


# ===========================================================================
# Endpoint #8: GET /api/v1/alumni/search   (JSON + XML)
# ===========================================================================

@app.route("/api/v1/alumni/search", methods=["GET"])
def search_alumni():
    last_name= (request.args.get("last_name") or "").strip()
    enrollment_year= request.args.get("enrollment_year") or ""
    graduation_year= request.args.get("graduation_year") or ""
    country= (request.args.get("country") or "").strip()
    fmt= (request.args.get("format") or "json").lower()

    try:
        page = max(1, int(request.args.get("page", "1")))
    except ValueError:
        page = 1

    where = []
    params = {}

    if last_name:
        where.append("a.last_name LIKE :ln")
        params["ln"] = f"%{last_name}%"

    if enrollment_year and enrollment_year.isdigit():
        where.append("a.enrollment_year = :ey")
        params["ey"] = int(enrollment_year)

    if graduation_year and graduation_year.isdigit():
        where.append("a.graduation_year = :gy")
        params["gy"] = int(graduation_year)

    if country:
        # match either residence or current job's country
        where.append("(a.country LIKE :ctry OR j.country LIKE :ctry2)")
        params["ctry"]  = f"%{country}%"
        params["ctry2"] = f"%{country}%"

    where_sql = ("WHERE " + " AND ".join(where)) if where else ""

    # total
    total = g.db.execute(text(f"""
        SELECT COUNT(DISTINCT a.id) AS n
        FROM alumni a
        LEFT JOIN jobs j ON j.alumni_id = a.id AND j.is_current = 1
        {where_sql}
    """), params).scalar_one()
    total = int(total)

    total_pages = max(1, math.ceil(total / PER_PAGE))
    page = min(page, total_pages)
    offset = (page - 1) * PER_PAGE

    page_params = dict(params)
    page_params["lim"] = PER_PAGE
    page_params["off"] = offset

    rows = g.db.execute(text(f"""
        SELECT  a.id, a.first_name, a.last_name, a.email,
                a.enrollment_year, a.graduation_year, a.country,
                j.id        AS current_job_id,
                j.title     AS current_job_title,
                j.company   AS current_job_company,
                j.city      AS current_job_city,
                j.country   AS current_job_country,
                j.latitude  AS current_job_latitude,
                j.longitude AS current_job_longitude
        FROM alumni a
        LEFT JOIN jobs j ON j.alumni_id = a.id AND j.is_current = 1
        {where_sql}
        ORDER BY a.last_name, a.first_name
        LIMIT :lim OFFSET :off
    """), page_params).all()

    payload = {
        "pagination": {
            "page":        page,
            "per_page":    PER_PAGE,
            "total":       total,
            "total_pages": total_pages,
        },
        "filters": {
            "last_name":       last_name,
            "enrollment_year": int(enrollment_year) if enrollment_year and enrollment_year.isdigit() else None,
            "graduation_year": int(graduation_year) if graduation_year and graduation_year.isdigit() else None,
            "country":         country,
        },
        "results": [_row_to_alumnus(r) for r in rows],
    }

    if fmt == "xml":
        body = to_xml(payload, root="search_response")
        resp = make_response(body)
        resp.headers["Content-Type"] = "application/xml; charset=utf-8"
        return resp

    return jsonify(payload)


# ---------------------------------------------------------------------------
# Health + 404
# ---------------------------------------------------------------------------

@app.route("/api/v1/health", methods=["GET"])
def health():
    try:
        g.db.execute(text("SELECT 1"))
        return jsonify({"status": "ok"})
    except Exception as e:
        return jsonify({"status": "error", "detail": str(e)}), 500


@app.errorhandler(404)
def _404(_):
    return jsonify({"error": "Not found"}), 404


@app.errorhandler(405)
def _405(_):
    return jsonify({"error": "Method not allowed"}), 405


# ---------------------------------------------------------------------------
if __name__ == "__main__":
    app.run(host=config.API_HOST, port=config.API_PORT, debug=config.DEBUG)
