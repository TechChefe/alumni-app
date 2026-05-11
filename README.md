# UTH Digital Systems — Alumni Map

REST API + Single-Page Web Application
Assignment 2 of *Advanced Web Applications*, MSc Software Engineering, University of Thessaly.

---

## What this project does

* Shows current job locations of alumni on a Leaflet/OpenStreetMap.
* Lets visitors register, log in (JWT), search alumni with multi-criteria pagination, and view a Google Charts column chart of country distribution.
* Authenticated alumni can add, edit, and delete their own jobs.
* All data flows through a custom REST API at `/api/v1/...` and is encoded in JSON (the search endpoint also supports XML via `?format=xml`).

---

## Tech stack

| Layer            | Technology                                                   |
| ---------------- | ------------------------------------------------------------ |
| Backend language | **Python 3.11+**                                             |
| Web framework    | **Flask 3** + Flask-Cors                                     |
| Database driver  | **SQLAlchemy Core** + **PyMySQL** (over MySQL 8 from XAMPP)  |
| Auth             | **PyJWT** (HS256)                                            |
| Front-end        | HTML5, CSS3, vanilla JavaScript (ES6)                        |
| CSS framework    | Bootstrap 5 + Bootstrap Icons                                |
| Map              | Leaflet + OpenStreetMap (no API key)                         |
| Charts           | Google Charts (ColumnChart)                                  |
| Data formats     | JSON (default) + XML (search endpoint)                       |
| Static hosting   | Apache (XAMPP), serves `index.html` + `js/` + `css/`         |
| API hosting      | Flask dev server on port 5000                                |

---

## 1. Prerequisites

1. **XAMPP** with **Apache + MySQL** running (only used for static file serving + the database).
2. **Python 3.11+** with `pip`. Get it from <https://www.python.org/downloads/> — during install, tick "Add Python to PATH".
3. A modern browser.
4. *(Recommended)* IntelliJ IDEA Ultimate or PyCharm — both handle Python + JS + HTML in one place.

---

## 2. Install the project

Unzip the project so it lives at `C:\xampp\htdocs\alumni-app` (Windows) or your XAMPP htdocs equivalent.

Open a terminal **inside the `backend` folder** and create a virtual environment:

### Windows (cmd or PowerShell)

```bat
cd C:\xampp\htdocs\alumni-app\backend
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
```

### macOS / Linux

```bash
cd /opt/lampp/htdocs/alumni-app/backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

The virtual environment keeps the project's Python dependencies isolated from your system Python.

---

## 3. Set up the database

1. Start **Apache** and **MySQL** from the XAMPP control panel.
2. Open <http://localhost/phpmyadmin>.
3. Click **Import** → choose `database/alumni_db.sql` → **Go**.

You now have a database called `alumni_db` with **15 alumni** and their jobs already loaded.

> **Test passwords:** every seeded alumnus has the password `password123`.

If your MySQL `root` user has a non-empty password, edit `backend/config.py` and change `DB_PASS`. (You can also set the `DB_PASS` environment variable instead.)

---

## 4. Run the API

From the `backend` folder, with the virtual environment active:

```
python app.py
```

You should see:

```
 * Running on http://0.0.0.0:5000
 * Debug mode: on
```

Confirm it's alive:  <http://localhost:5000/api/v1/health> → `{"status":"ok"}`
And the count endpoint:  <http://localhost:5000/api/v1/alumni/count> → `{"count":15}`

Leave this terminal open — it's your API server. Open a second terminal for git/etc.

---

## 5. Open the front-end

The HTML/CSS/JS files are served as plain static files by Apache. Visit:

```
http://localhost/alumni-app/
```

The page should load with a full-screen map and 15 markers across Europe.

The front-end talks to the API at `http://<same-host>:5000/api/v1/...` (configured in `js/api.js`).

---

## 6. (Optional) Virtual host: `alumni.ds.uth.gr`

The assignment requires the site to live at `alumni.ds.uth.gr`. With XAMPP on Windows you can fake this locally in three steps.

### 6.1 Apache vhost

Open `C:\xampp\apache\conf\extra\httpd-vhosts.conf` **in a text editor opened as Administrator** and append:

```apache
<VirtualHost *:80>
    ServerName localhost
    DocumentRoot "C:/xampp/htdocs"
</VirtualHost>

<VirtualHost *:80>
    ServerName alumni.ds.uth.gr
    DocumentRoot "C:/xampp/htdocs/alumni-app"
    <Directory "C:/xampp/htdocs/alumni-app">
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
```

The first block keeps your other XAMPP projects reachable at plain `localhost`.

Then in `C:\xampp\apache\conf\httpd.conf` make sure this line is *uncommented*:

```apache
Include conf/extra/httpd-vhosts.conf
```

### 6.2 Hosts file

Open Notepad **as Administrator** and edit `C:\Windows\System32\drivers\etc\hosts`. Add:

```
127.0.0.1   alumni.ds.uth.gr
```

Restart Apache from the XAMPP control panel.

The site is now reachable at <http://alumni.ds.uth.gr> and the API at <http://alumni.ds.uth.gr:5000/api/v1/>.

---

## 7. Endpoint reference

| #   | Method | URL                                                 | Auth | Notes                                       |
| --- | ------ | --------------------------------------------------- | ---- | ------------------------------------------- |
| 1   | POST   | `/api/v1/alumni/`                                   |  —   | Register a new alumnus                      |
| 2   | POST   | `/api/v1/auth/login`                                |  —   | Returns a JWT and the user payload          |
| 3   | GET    | `/api/v1/alumni/count`                              |  —   | Returns `{"count": N}`                      |
| 4   | GET    | `/api/v1/alumni/{id}/jobs`                          |  —   | All jobs of one alumnus                     |
| 5   | GET    | `/api/v1/alumni/`                                   |  —   | All alumni with their current job           |
| 6a  | DELETE | `/api/v1/alumni/{id}/jobs/{jid}`                    |  ✓   | Nested delete                               |
| 6b  | DELETE | `/api/v1/jobs/{id}`                                 |  ✓   | Direct delete                               |
| 7a  | PUT    | `/api/v1/alumni/{id}/jobs/{jid}`                    |  ✓   | Nested update                               |
| 7b  | PUT    | `/api/v1/jobs/{id}`                                 |  ✓   | Direct update                               |
| 8   | GET    | `/api/v1/alumni/search?...&format=json\|xml&page=N` |  —   | Multi-criteria search, paginated 4 per page |

`Auth ✓` means the request must include `Authorization: Bearer <token>`.

---

## 8. Quick API tests (curl)

```bash
# 3. Count
curl http://localhost:5000/api/v1/alumni/count

# 5. List all
curl http://localhost:5000/api/v1/alumni/

# 8. Search (JSON, default)
curl "http://localhost:5000/api/v1/alumni/search?country=Greece&page=1"

# 8. Same search (XML)
curl "http://localhost:5000/api/v1/alumni/search?country=Greece&page=1&format=xml"

# 2. Login (Windows cmd)
curl -X POST http://localhost:5000/api/v1/auth/login ^
     -H "Content-Type: application/json" ^
     -d "{\"email\":\"maria.papadopoulou@example.com\",\"password\":\"password123\"}"

# 7. Update a job (auth, Windows cmd)
set TOKEN=paste-the-token-from-login-here
curl -X PUT http://localhost:5000/api/v1/alumni/1/jobs/1 ^
     -H "Content-Type: application/json" ^
     -H "Authorization: Bearer %TOKEN%" ^
     -d "{\"title\":\"Principal Engineer\"}"
```

(On macOS/Linux replace `^` line continuations with `\` and `%TOKEN%` with `$TOKEN`.)

---

## 9. Project structure

```
alumni-app/
├── backend/                       # Python REST API
│   ├── app.py                     # Flask app — all 8 endpoints
│   ├── config.py                  # DB + JWT settings
│   ├── database.py                # SQLAlchemy engine + session
│   ├── jwt_helper.py              # issue / decode / require_auth decorator
│   ├── xml_helper.py              # dict → XML (for endpoint #8)
│   └── requirements.txt           # pip dependencies
├── css/style.css                  # SPA styling
├── js/                            # SPA JavaScript
│   ├── api.js                     # fetch wrapper, points at :5000
│   ├── auth.js                    # JWT storage in sessionStorage
│   ├── chart.js                   # Google Charts country chart
│   ├── map.js                     # Leaflet map + markers
│   └── app.js                     # main controller, wires up modals
├── database/alumni_db.sql         # MySQL schema + 15 seeded alumni
├── index.html                     # SPA shell
├── vhost-config-example.conf      # Apache vhost snippet
├── alumni-app-report.docx         # Report deliverable
└── README.md                      # this file
```

---

## 10. Completion checklist

| 1ο | 2ο | 3ο | 4ο | 5ο | 6ο | 7ο | 8ο XML | 8ο JSON | virtual host |
|----|----|----|----|----|----|----|--------|---------|--------------|
| Ναι| Ναι| Ναι| Ναι| Ναι| Ναι| Ναι|  Ναι   |   Ναι   |     Ναι      |

---

## 11. Troubleshooting

* **`python: command not found`** (Windows) — run the Python installer again and tick "Add Python to PATH".
* **`pip install ... fails on cryptography`** — upgrade pip first: `python -m pip install --upgrade pip setuptools wheel`.
* **`Database connection failed` / `Access denied for user 'root'@'localhost'`** — change `DB_PASS` in `backend/config.py` to your MySQL root password.
* **`Can't connect to MySQL server on '127.0.0.1'`** — MySQL is not running. Open the XAMPP Control Panel and click **Start** next to MySQL.
* **CORS error in browser console** (`Access-Control-Allow-Origin`) — the API explicitly allows all origins via `flask_cors`. If you see this, the API isn't running or the front-end is hitting the wrong URL — check the Network tab.
* **`401 Missing Authorization Bearer token`** when you *did* send the header — confirm in DevTools Network tab that the `Authorization` header is actually attached to the request.
* **Markers don't show up** — open DevTools (F12) → Network tab → reload. The request to `/api/v1/alumni/` should return 200 with a JSON array. If it's red, follow the error.
* **Port 5000 already in use** — change `API_PORT` in `backend/config.py` (and update `js/api.js` to match).
