from fastapi import FastAPI, UploadFile, File, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from PIL import Image
import numpy as np
import io
import pickle
import os
import json
import sqlite3
from datetime import datetime, timedelta, timezone
from typing import Optional

from services import WeatherService, RwandaAgronomistAdvisor, RwandaCropPlanner

# Try to import huggingface_hub (optional dependency)
try:
    from huggingface_hub import hf_hub_download
    HF_AVAILABLE = True
except ImportError:
    HF_AVAILABLE = False
    print("⚠ huggingface_hub not installed. Install with: pip install huggingface_hub")

# --- Initialization ---
app = FastAPI(title="CropSense AI API", version="1.0.0")

# Allow your Flutter and React apps to communicate with this server
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Load your exported Keras model and class labels
model = None
label_encoder = None  # Optional: from sklearn
CLASS_NAMES: list[str] = []  # Fallback: from model_metadata.json
MODEL_LOAD_ERROR: str | None = None

def _tf_enabled() -> bool:
    """
    TensorFlow import/model loading is opt-in because some hosted Linux
    environments can segfault on TF import (native deps / CPU features).
    """
    return os.environ.get("CROPSENSE_ENABLE_TF", "").strip().lower() in {"1", "true", "yes", "on"}

#
# --- Simple Auth (SQLite + JWT) ---
# This replaces Supabase for login/register/profile.
#
security = HTTPBearer(auto_error=False)

DB_PATH = os.environ.get("CROPSENSE_DB_PATH", "cropsense.db")
DATABASE_URL = os.environ.get("DATABASE_URL") or os.environ.get("CROPSENSE_DATABASE_URL")
JWT_SECRET = os.environ.get("CROPSENSE_JWT_SECRET", "CHANGE_ME_IN_PRODUCTION")
JWT_ALG = "HS256"
JWT_EXPIRES_HOURS = int(os.environ.get("CROPSENSE_JWT_EXPIRES_HOURS", "168"))  # 7 days

def _is_postgres() -> bool:
    return bool(DATABASE_URL and DATABASE_URL.strip())

def _pg_connect():
    # psycopg2 is only needed in production when DATABASE_URL is set
    import psycopg2
    return psycopg2.connect(DATABASE_URL, sslmode="require")

def _db() -> sqlite3.Connection:
    # SQLite fallback for local development only.
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn

def _init_db() -> None:
    if _is_postgres():
        conn = _pg_connect()
        try:
            cur = conn.cursor()
            cur.execute(
                """
                CREATE TABLE IF NOT EXISTS users (
                  id SERIAL PRIMARY KEY,
                  email TEXT UNIQUE NOT NULL,
                  password_hash TEXT NOT NULL,
                  full_name TEXT NOT NULL,
                  phone TEXT DEFAULT '',
                  province TEXT DEFAULT '',
                  district TEXT DEFAULT '',
                  sector TEXT DEFAULT '',
                  cell TEXT DEFAULT '',
                  village TEXT DEFAULT '',
                  land_size DOUBLE PRECISION,
                  soil_type TEXT DEFAULT '',
                  created_at TIMESTAMPTZ NOT NULL,
                  updated_at TIMESTAMPTZ NOT NULL
                );
                """
            )
            cur.execute(
                """
                CREATE TABLE IF NOT EXISTS season_plans (
                  id SERIAL PRIMARY KEY,
                  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                  province TEXT NOT NULL DEFAULT '',
                  district TEXT NOT NULL DEFAULT '',
                  sector TEXT NOT NULL DEFAULT '',
                  cell TEXT NOT NULL DEFAULT '',
                  village TEXT NOT NULL DEFAULT '',
                  season TEXT NOT NULL DEFAULT '',
                  land_type TEXT NOT NULL DEFAULT '',
                  land_size TEXT NOT NULL DEFAULT '',
                  primary_crop TEXT NOT NULL DEFAULT '',
                  advisor_json TEXT NOT NULL DEFAULT '{}',
                  stages_json TEXT NOT NULL DEFAULT '[]',
                  is_active BOOLEAN NOT NULL DEFAULT TRUE,
                  created_at TIMESTAMPTZ NOT NULL,
                  updated_at TIMESTAMPTZ NOT NULL
                );
                """
            )
            conn.commit()
        finally:
            conn.close()
        return

    # SQLite fallback
    conn = _db()
    try:
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS users (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              email TEXT UNIQUE NOT NULL,
              password_hash TEXT NOT NULL,
              full_name TEXT NOT NULL,
              phone TEXT DEFAULT '',
              province TEXT DEFAULT '',
              district TEXT DEFAULT '',
              sector TEXT DEFAULT '',
              cell TEXT DEFAULT '',
              village TEXT DEFAULT '',
              land_size REAL,
              soil_type TEXT DEFAULT '',
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            );
            """
        )
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS season_plans (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
              province TEXT NOT NULL DEFAULT '',
              district TEXT NOT NULL DEFAULT '',
              sector TEXT NOT NULL DEFAULT '',
              cell TEXT NOT NULL DEFAULT '',
              village TEXT NOT NULL DEFAULT '',
              season TEXT NOT NULL DEFAULT '',
              land_type TEXT NOT NULL DEFAULT '',
              land_size TEXT NOT NULL DEFAULT '',
              primary_crop TEXT NOT NULL DEFAULT '',
              advisor_json TEXT NOT NULL DEFAULT '{}',
              stages_json TEXT NOT NULL DEFAULT '[]',
              is_active INTEGER NOT NULL DEFAULT 1,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            );
            """
        )
        conn.commit()
    finally:
        conn.close()

_init_db()

def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()

def _hash_password(password: str) -> str:
    import bcrypt
    hashed = bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt())
    return hashed.decode("utf-8")

def _verify_password(password: str, password_hash: str) -> bool:
    import bcrypt
    try:
        return bcrypt.checkpw(password.encode("utf-8"), password_hash.encode("utf-8"))
    except Exception:
        return False

def _create_token(user_id: int, email: str) -> str:
    from jose import jwt
    exp = datetime.now(timezone.utc) + timedelta(hours=JWT_EXPIRES_HOURS)
    payload = {"sub": str(user_id), "email": email, "exp": exp}
    return jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALG)

def _decode_token(token: str) -> dict:
    from jose import jwt
    return jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALG])

def _row_to_dict(row) -> dict:
    # sqlite3.Row supports dict(row); psycopg2 returns tuples
    if row is None:
        return {}
    if isinstance(row, sqlite3.Row):
        return dict(row)
    return dict(row)

def get_current_user(creds: Optional[HTTPAuthorizationCredentials] = Depends(security)):
    if creds is None or not creds.credentials:
        raise HTTPException(status_code=401, detail="Missing bearer token")
    try:
        payload = _decode_token(creds.credentials)
        user_id = int(payload.get("sub"))
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid token")

    if _is_postgres():
        conn = _pg_connect()
        try:
            cur = conn.cursor()
            cur.execute("SELECT * FROM users WHERE id = %s", (user_id,))
            row = cur.fetchone()
            if row is None:
                raise HTTPException(status_code=401, detail="User not found")
            cols = [d[0] for d in cur.description]
            return dict(zip(cols, row))
        finally:
            conn.close()

    conn = _db()
    try:
        row = conn.execute("SELECT * FROM users WHERE id = ?", (user_id,)).fetchone()
        if row is None:
            raise HTTPException(status_code=401, detail="User not found")
        return dict(row)
    finally:
        conn.close()

@app.post("/auth/register")
async def auth_register(payload: dict):
    email = (payload.get("email") or "").strip().lower()
    password = payload.get("password") or ""
    full_name = (payload.get("full_name") or "").strip()
    phone = (payload.get("phone") or "").strip()
    province = (payload.get("province") or "").strip()
    district = (payload.get("district") or "").strip()

    if not email or "@" not in email:
        raise HTTPException(status_code=400, detail="Valid email is required")
    if len(password) < 6:
        raise HTTPException(status_code=400, detail="Password must be at least 6 characters")
    if not full_name:
        raise HTTPException(status_code=400, detail="Full name is required")

    password_hash = _hash_password(password)

    if _is_postgres():
        conn = _pg_connect()
        try:
            cur = conn.cursor()
            now = datetime.now(timezone.utc)
            try:
                cur.execute(
                    """
                    INSERT INTO users (email, password_hash, full_name, phone, province, district, created_at, updated_at)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                    RETURNING *
                    """,
                    (email, password_hash, full_name, phone, province, district, now, now),
                )
                row = cur.fetchone()
                cols = [d[0] for d in cur.description]
                user = dict(zip(cols, row))
                conn.commit()
            except Exception as e:
                conn.rollback()
                # Unique violation
                if "duplicate key value" in str(e).lower():
                    raise HTTPException(status_code=409, detail="Email already registered")
                raise
            token = _create_token(int(user["id"]), user["email"])
            user.pop("password_hash", None)
            return {"access_token": token, "token_type": "bearer", "profile": user}
        finally:
            conn.close()

    conn = _db()
    try:
        now = _now_iso()
        try:
            conn.execute(
                """
                INSERT INTO users (email, password_hash, full_name, phone, province, district, created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (email, password_hash, full_name, phone, province, district, now, now),
            )
            conn.commit()
        except sqlite3.IntegrityError:
            raise HTTPException(status_code=409, detail="Email already registered")
        user = conn.execute("SELECT * FROM users WHERE email = ?", (email,)).fetchone()
        token = _create_token(user["id"], user["email"])
        prof = dict(user)
        prof.pop("password_hash", None)
        return {"access_token": token, "token_type": "bearer", "profile": prof}
    finally:
        conn.close()

@app.post("/auth/login")
async def auth_login(payload: dict):
    email = (payload.get("email") or "").strip().lower()
    password = payload.get("password") or ""
    if not email or not password:
        raise HTTPException(status_code=400, detail="Email and password are required")

    if _is_postgres():
        conn = _pg_connect()
        try:
            cur = conn.cursor()
            cur.execute("SELECT * FROM users WHERE email = %s", (email,))
            row = cur.fetchone()
            if row is None:
                raise HTTPException(status_code=401, detail="Invalid email or password")
            cols = [d[0] for d in cur.description]
            user = dict(zip(cols, row))
            if not _verify_password(password, user["password_hash"]):
                raise HTTPException(status_code=401, detail="Invalid email or password")
            token = _create_token(int(user["id"]), user["email"])
            user.pop("password_hash", None)
            return {"access_token": token, "token_type": "bearer", "profile": user}
        finally:
            conn.close()

    conn = _db()
    try:
        user = conn.execute("SELECT * FROM users WHERE email = ?", (email,)).fetchone()
        if user is None or not _verify_password(password, user["password_hash"]):
            raise HTTPException(status_code=401, detail="Invalid email or password")
        token = _create_token(user["id"], user["email"])
        prof = dict(user)
        prof.pop("password_hash", None)
        return {"access_token": token, "token_type": "bearer", "profile": prof}
    finally:
        conn.close()

@app.get("/auth/me")
async def auth_me(user: dict = Depends(get_current_user)):
    u = dict(user)
    u.pop("password_hash", None)
    return {"profile": u}

@app.put("/auth/profile")
async def auth_update_profile(payload: dict, user: dict = Depends(get_current_user)):
    fields = {
        "full_name": payload.get("full_name"),
        "phone": payload.get("phone"),
        "province": payload.get("province"),
        "district": payload.get("district"),
        "sector": payload.get("sector"),
        "cell": payload.get("cell"),
        "village": payload.get("village"),
        "land_size": payload.get("land_size"),
        "soil_type": payload.get("soil_type"),
    }
    updates = {k: v for k, v in fields.items() if v is not None}
    if not updates:
        return {"profile": {k: user[k] for k in user.keys() if k != "password_hash"}}

    if _is_postgres():
        updates["updated_at"] = datetime.now(timezone.utc)
        sets = ", ".join([f"{k} = %s" for k in updates.keys()])
        values = list(updates.values()) + [user["id"]]
        conn = _pg_connect()
        try:
            cur = conn.cursor()
            cur.execute(f"UPDATE users SET {sets} WHERE id = %s RETURNING *", values)
            row = cur.fetchone()
            cols = [d[0] for d in cur.description]
            new_user = dict(zip(cols, row))
            conn.commit()
            new_user.pop("password_hash", None)
            return {"profile": new_user}
        finally:
            conn.close()

    updates["updated_at"] = _now_iso()
    sets = ", ".join([f"{k} = ?" for k in updates.keys()])
    values = list(updates.values()) + [user["id"]]
    conn = _db()
    try:
        conn.execute(f"UPDATE users SET {sets} WHERE id = ?", values)
        conn.commit()
        new_user = conn.execute("SELECT * FROM users WHERE id = ?", (user["id"],)).fetchone()
        u = dict(new_user)
        u.pop("password_hash", None)
        return {"profile": u}
    finally:
        conn.close()


# --- Season plans (live on server; tied to authenticated user) ---

DEFAULT_SEASON_STAGES = [
    {
        "key": "prepare_land",
        "title": "Prepare land",
        "description": "Clear residues and weeds, test soil where possible, and plan inputs before the rains.",
        "done": False,
        "completed_at": None,
    },
    {
        "key": "plant_establish",
        "title": "Plant & establish crop",
        "description": "Choose recommended varieties for your province and season, and plant at the right spacing.",
        "done": False,
        "completed_at": None,
    },
    {
        "key": "manage_season",
        "title": "Manage crop during season",
        "description": "Monitor for pests, diseases, and nutrient stress. Use Crop Health Scanner and local advice to guide actions.",
        "done": False,
        "completed_at": None,
    },
    {
        "key": "harvest",
        "title": "Harvest at the right time",
        "description": "Avoid harvesting too early or too late so that yield and quality are not lost.",
        "done": False,
        "completed_at": None,
    },
    {
        "key": "post_harvest",
        "title": "Post-harvest handling & storage",
        "description": "Dry and store grain safely, or market fresh produce quickly to reduce losses.",
        "done": False,
        "completed_at": None,
    },
]


def _json_loads_field(raw, default):
    if raw is None:
        return default
    if isinstance(raw, (dict, list)):
        return raw
    if isinstance(raw, str):
        s = raw.strip()
        if not s:
            return default
        try:
            return json.loads(s)
        except json.JSONDecodeError:
            return default
    return default


def _season_plan_row_to_api(row: dict) -> dict:
    advisor = _json_loads_field(row.get("advisor_json"), {})
    stages = _json_loads_field(row.get("stages_json"), [])
    active = row.get("is_active")
    if isinstance(active, int):
        active = bool(active)
    return {
        "id": row["id"],
        "province": row.get("province") or "",
        "district": row.get("district") or "",
        "sector": row.get("sector") or "",
        "cell": row.get("cell") or "",
        "village": row.get("village") or "",
        "season": row.get("season") or "",
        "land_type": row.get("land_type") or "",
        "land_size": row.get("land_size") or "",
        "primary_crop": row.get("primary_crop") or "",
        "advisor": advisor,
        "stages": stages,
        "is_active": bool(active),
        "created_at": str(row.get("created_at", "")),
        "updated_at": str(row.get("updated_at", "")),
    }


def _merge_stage_updates(stages: list, updates: list) -> list:
    patch = {}
    for u in updates:
        if not isinstance(u, dict):
            continue
        key = (u.get("key") or "").strip()
        if key:
            patch[key] = u
    base = stages if stages else list(DEFAULT_SEASON_STAGES)
    out = []
    for s in base:
        if not isinstance(s, dict):
            continue
        key = (s.get("key") or "").strip()
        if not key:
            continue
        item = dict(s)
        if key in patch:
            u = patch[key]
            if u.get("done") is True:
                item["done"] = True
                item["completed_at"] = _now_iso()
            elif u.get("done") is False:
                item["done"] = False
                item["completed_at"] = None
        out.append(item)
    return out


@app.get("/season-plans/active")
async def season_plans_active(user: dict = Depends(get_current_user)):
    """Return the current active season plan for this user, or null."""
    uid = int(user["id"])
    if _is_postgres():
        conn = _pg_connect()
        try:
            cur = conn.cursor()
            cur.execute(
                """
                SELECT * FROM season_plans
                WHERE user_id = %s AND is_active = TRUE
                ORDER BY id DESC
                LIMIT 1
                """,
                (uid,),
            )
            row = cur.fetchone()
            if row is None:
                return {"plan": None}
            cols = [d[0] for d in cur.description]
            return {"plan": _season_plan_row_to_api(dict(zip(cols, row)))}
        finally:
            conn.close()

    conn = _db()
    try:
        row = conn.execute(
            """
            SELECT * FROM season_plans
            WHERE user_id = ? AND is_active = 1
            ORDER BY id DESC
            LIMIT 1
            """,
            (uid,),
        ).fetchone()
        if row is None:
            return {"plan": None}
        return {"plan": _season_plan_row_to_api(dict(row))}
    finally:
        conn.close()


@app.post("/season-plans")
async def season_plans_create(payload: dict, user: dict = Depends(get_current_user)):
    """
    Save a new active season plan (deactivates previous active plans for this user).
    Body: province, district, sector, cell, village, season, land_type, land_size, advisor (object, optional).
    """
    uid = int(user["id"])
    province = (payload.get("province") or "").strip()
    district = (payload.get("district") or "").strip()
    sector = (payload.get("sector") or "").strip()
    cell = (payload.get("cell") or "").strip()
    village = (payload.get("village") or "").strip()
    season = (payload.get("season") or "").strip()
    land_type = (payload.get("land_type") or "").strip()
    land_size = (payload.get("land_size") or "").strip()
    advisor = payload.get("advisor")
    if advisor is not None and not isinstance(advisor, dict):
        raise HTTPException(status_code=400, detail="advisor must be an object if provided")
    advisor_obj = advisor if isinstance(advisor, dict) else {}
    best = advisor_obj.get("best_match") if advisor_obj else None
    primary_crop = (payload.get("primary_crop") or "").strip()
    if not primary_crop and isinstance(best, dict):
        primary_crop = (best.get("crop") or "").strip()
    advisor_str = json.dumps(advisor_obj, ensure_ascii=False)
    stages_str = json.dumps(list(DEFAULT_SEASON_STAGES), ensure_ascii=False)
    now_pg = datetime.now(timezone.utc)
    now_sqlite = _now_iso()

    if _is_postgres():
        conn = _pg_connect()
        try:
            cur = conn.cursor()
            cur.execute(
                "UPDATE season_plans SET is_active = FALSE, updated_at = %s WHERE user_id = %s",
                (now_pg, uid),
            )
            cur.execute(
                """
                INSERT INTO season_plans (
                  user_id, province, district, sector, cell, village, season, land_type, land_size,
                  primary_crop, advisor_json, stages_json, is_active, created_at, updated_at
                ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, TRUE, %s, %s)
                RETURNING *
                """,
                (
                    uid,
                    province,
                    district,
                    sector,
                    cell,
                    village,
                    season,
                    land_type,
                    land_size,
                    primary_crop,
                    advisor_str,
                    stages_str,
                    now_pg,
                    now_pg,
                ),
            )
            row = cur.fetchone()
            cols = [d[0] for d in cur.description]
            conn.commit()
            return {"plan": _season_plan_row_to_api(dict(zip(cols, row)))}
        except Exception as e:
            conn.rollback()
            raise HTTPException(status_code=500, detail=f"Could not save season plan: {e}") from e
        finally:
            conn.close()

    conn = _db()
    try:
        conn.execute(
            "UPDATE season_plans SET is_active = 0, updated_at = ? WHERE user_id = ?",
            (now_sqlite, uid),
        )
        conn.execute(
            """
            INSERT INTO season_plans (
              user_id, province, district, sector, cell, village, season, land_type, land_size,
              primary_crop, advisor_json, stages_json, is_active, created_at, updated_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1, ?, ?)
            """,
            (
                uid,
                province,
                district,
                sector,
                cell,
                village,
                season,
                land_type,
                land_size,
                primary_crop,
                advisor_str,
                stages_str,
                now_sqlite,
                now_sqlite,
            ),
        )
        conn.commit()
        new_id = conn.execute("SELECT last_insert_rowid()").fetchone()[0]
        row = conn.execute("SELECT * FROM season_plans WHERE id = ?", (new_id,)).fetchone()
        return {"plan": _season_plan_row_to_api(dict(row))}
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=f"Could not save season plan: {e}") from e
    finally:
        conn.close()


@app.patch("/season-plans/{plan_id}/stages")
async def season_plans_patch_stages(
    plan_id: int,
    payload: dict,
    user: dict = Depends(get_current_user),
):
    """Update stage completion. Body: { \"stages\": [ {\"key\": \"prepare_land\", \"done\": true }, ... ] }"""
    uid = int(user["id"])
    updates = payload.get("stages")
    if not isinstance(updates, list) or not updates:
        raise HTTPException(status_code=400, detail="stages must be a non-empty list")

    if _is_postgres():
        conn = _pg_connect()
        try:
            cur = conn.cursor()
            cur.execute(
                "SELECT * FROM season_plans WHERE id = %s AND user_id = %s",
                (plan_id, uid),
            )
            row = cur.fetchone()
            if row is None:
                raise HTTPException(status_code=404, detail="Season plan not found")
            cols = [d[0] for d in cur.description]
            plan = dict(zip(cols, row))
            stages = _json_loads_field(plan.get("stages_json"), [])
            merged = _merge_stage_updates(stages, updates)
            new_str = json.dumps(merged, ensure_ascii=False)
            now_pg = datetime.now(timezone.utc)
            cur.execute(
                "UPDATE season_plans SET stages_json = %s, updated_at = %s WHERE id = %s AND user_id = %s",
                (new_str, now_pg, plan_id, uid),
            )
            conn.commit()
            cur.execute("SELECT * FROM season_plans WHERE id = %s", (plan_id,))
            row2 = cur.fetchone()
            cols2 = [d[0] for d in cur.description]
            return {"plan": _season_plan_row_to_api(dict(zip(cols2, row2)))}
        finally:
            conn.close()

    conn = _db()
    try:
        row = conn.execute(
            "SELECT * FROM season_plans WHERE id = ? AND user_id = ?",
            (plan_id, uid),
        ).fetchone()
        if row is None:
            raise HTTPException(status_code=404, detail="Season plan not found")
        plan = dict(row)
        stages = _json_loads_field(plan.get("stages_json"), [])
        merged = _merge_stage_updates(stages, updates)
        new_str = json.dumps(merged, ensure_ascii=False)
        now_sqlite = _now_iso()
        conn.execute(
            "UPDATE season_plans SET stages_json = ?, updated_at = ? WHERE id = ? AND user_id = ?",
            (new_str, now_sqlite, plan_id, uid),
        )
        conn.commit()
        row2 = conn.execute("SELECT * FROM season_plans WHERE id = ?", (plan_id,)).fetchone()
        return {"plan": _season_plan_row_to_api(dict(row2))}
    finally:
        conn.close()


def load_model():
    """
    Load model from Hugging Face (if configured) or fallback to local file.
    Priority: HUGGINGFACE_MODEL_ID > CROPSENSE_MODEL_PATH > default local path
    """
    global model, MODEL_LOAD_ERROR
    model = None
    MODEL_LOAD_ERROR = None

    if not _tf_enabled():
        MODEL_LOAD_ERROR = "TensorFlow disabled (set CROPSENSE_ENABLE_TF=1 to enable)."
        return

    # Local import so the API can boot even if TF crashes on import.
    import tensorflow as tf
    
    # Option 1: Try loading from Hugging Face
    hf_model_id = os.environ.get("HUGGINGFACE_MODEL_ID")
    if hf_model_id and HF_AVAILABLE:
        try:
            print(f"🔄 Attempting to load model from Hugging Face: {hf_model_id}")
            # Try best_model.keras first (from training script), then legacy name
            for fname in ("best_model.keras", "best_MobileNetV2.keras"):
                try:
                    model_file = hf_hub_download(
                        repo_id=hf_model_id,
                        filename=fname,
                        cache_dir=".hf_cache"
                    )
                    break
                except Exception:
                    continue
            else:
                raise FileNotFoundError("No best_model.keras or best_MobileNetV2.keras in repo")
            model = tf.keras.models.load_model(model_file)
            print(f"✓ Model loaded successfully from Hugging Face: {hf_model_id}")
            return
        except Exception as e:
            MODEL_LOAD_ERROR = f"Error loading model from Hugging Face: {e}"
            print(f"✗ Error loading model from Hugging Face: {e}")
            print("   Falling back to local model...")
    
    # Option 2: Load from local file (fallback)
    try:
        default_path = (
            "outputs/best_model.keras"
            if os.path.exists("outputs/best_model.keras")
            else "outputs/best_MobileNetV2.keras"
        )
        model_path = os.environ.get("CROPSENSE_MODEL_PATH", default_path)
        if os.path.exists(model_path):
            model = tf.keras.models.load_model(model_path)
            print(f"✓ Model loaded successfully from local path: {model_path}")
        else:
            print(f"✗ Model file not found: {model_path}")
            model = None
            MODEL_LOAD_ERROR = f"Model file not found: {model_path}"
    except Exception as e:
        print(f"✗ Error loading local model: {e}")
        model = None
        MODEL_LOAD_ERROR = f"Error loading local model: {e}"

def load_label_encoder():
    """
    Try to load a sklearn LabelEncoder from pickle.
    If not available, fall back to loading class names from model_metadata.json.
    """
    global label_encoder, CLASS_NAMES

    # First, try the pickle file (if you exported it)
    try:
        with open("outputs/label_encoder.pkl", "rb") as f:
            label_encoder = pickle.load(f)
        # If the encoder has classes_, also cache them for reference
        if hasattr(label_encoder, "classes_"):
            CLASS_NAMES = [str(c) for c in label_encoder.classes_]
        print("✓ Label encoder loaded successfully from outputs/label_encoder.pkl")
        return
    except Exception as e:
        print(f"✗ Error loading label encoder from pickle: {e}")
        label_encoder = None

    # Fallback: load class names from model_metadata.json
    # Try Hugging Face first, then local file
    hf_model_id = os.environ.get("HUGGINGFACE_MODEL_ID")
    if hf_model_id and HF_AVAILABLE:
        try:
            meta_file = hf_hub_download(
                repo_id=hf_model_id,
                filename="model_metadata.json",
                cache_dir=".hf_cache"
            )
            with open(meta_file, "r") as f:
                meta = json.load(f)
            classes = meta.get("classes") or meta.get("class_names") or []
            CLASS_NAMES = [str(c) for c in classes]
            if CLASS_NAMES:
                print(f"✓ Loaded class names from Hugging Face: {CLASS_NAMES}")
                return
        except Exception as e:
            print(f"✗ Error loading metadata from Hugging Face: {e}")
    
    # Fallback to local file
    try:
        meta_path = os.path.join("outputs", "model_metadata.json")
        with open(meta_path, "r") as f:
            meta = json.load(f)
        classes = meta.get("classes") or meta.get("class_names") or []
        CLASS_NAMES = [str(c) for c in classes]
        if CLASS_NAMES:
            print(f"✓ Loaded class names from {meta_path}: {CLASS_NAMES}")
        else:
            print(f"✗ No 'classes' or 'class_names' in {meta_path}")
    except Exception as e:
        print(f"✗ Error loading class names from model_metadata.json: {e}")
        CLASS_NAMES = []

# Load model and encoder on startup
@app.on_event("startup")
def _startup_load_assets():
    # Don't block server startup on ML assets; prediction endpoint already
    # returns a graceful fallback when model/classes are missing.
    try:
        load_model()
    except Exception as e:
        # Note: this can't catch segfaults, but it will catch normal Python errors.
        global MODEL_LOAD_ERROR
        MODEL_LOAD_ERROR = f"Unexpected error loading model: {e}"
        print(f"✗ Unexpected error loading model: {e}")
    try:
        load_label_encoder()
    except Exception as e:
        print(f"✗ Unexpected error loading label encoder: {e}")

# Initialize services
weather_service = WeatherService()
advisor = RwandaAgronomistAdvisor()
crop_planner = RwandaCropPlanner()

# --- Health Check Endpoint ---
@app.get("/")
async def root():
    """Health check endpoint"""
    return {
        "status": "CropSense AI API is running",
        "version": "1.0.0",
        "model_loaded": model is not None,
        "encoder_loaded": label_encoder is not None,
        "tf_enabled": _tf_enabled(),
        "model_load_error": MODEL_LOAD_ERROR,
        "auth": "enabled",
    }

@app.get("/health")
async def health():
    """Detailed health check"""
    return {
        "status": "healthy",
        "model": "loaded" if model is not None else "not loaded",
        "label_encoder": "loaded" if label_encoder is not None else "not loaded",
        "tf_enabled": _tf_enabled(),
        "model_load_error": MODEL_LOAD_ERROR,
        "weather_service": "available",
        "advisor_service": "available",
        "crop_planner_rows": len(crop_planner._rows),
    }

# --- Prediction Endpoint ---
@app.post("/predict")
async def predict(file: UploadFile = File(...)):
    """
    Predict crop disease from image and provide advice
    
    - **file**: Image file of the crop leaf or plant
    - Returns: Prediction, weather data, and agronomic advice
    """
    # If the ML model or class mapping is missing, return a graceful demo response
    if model is None or (label_encoder is None and not CLASS_NAMES):
        weather = weather_service.get_weather_data("Rwanda")
        fallback_crop = "maize"
        used_weather_fallback = False
        try:
            t = weather.get("temperature", 20)
            h = weather.get("humidity", 60)
            if t in (None, "N/A"):
                temp_val = 20.0
                used_weather_fallback = True
            else:
                temp_val = float(t)
            if h in (None, "N/A"):
                hum_val = 60.0
                used_weather_fallback = True
            else:
                hum_val = float(h)
        except (TypeError, ValueError):
            temp_val, hum_val = 20.0, 60.0
            used_weather_fallback = True
        advice = advisor.get_advice(
            crop=fallback_crop,
            temperature=temp_val,
            humidity=hum_val,
        )

        return {
            "prediction": "Model not loaded - showing example advice for maize",
            "confidence": 0.0,
            "weather": weather,
            "advice": advice,
            "weather_is_realtime": not used_weather_fallback,
            "weather_note": "Real-time weather unavailable; showing generic advice based on typical conditions."
            if used_weather_fallback
            else "Advice uses real-time weather from Open-Meteo.",
            "timestamp": weather.get("timestamp"),
        }
    
    try:
        # Read and preprocess the image
        contents = await file.read()
        image = Image.open(io.BytesIO(contents)).convert("RGB")
        
        # Resize to match model input (trained with IMG_SIZE=128 in notebook)
        image = image.resize((128, 128))
        image_array = np.array(image) / 255.0
        image_array = np.expand_dims(image_array, axis=0)
        
        # Make prediction
        predictions = model.predict(image_array)
        predicted_class_idx = np.argmax(predictions[0])
        confidence = float(predictions[0][predicted_class_idx])
        
        # Decode prediction: prefer LabelEncoder if available, otherwise CLASS_NAMES
        if label_encoder is not None:
            predicted_crop = label_encoder.inverse_transform([predicted_class_idx])[0]
        elif CLASS_NAMES and 0 <= predicted_class_idx < len(CLASS_NAMES):
            predicted_crop = CLASS_NAMES[predicted_class_idx]
        else:
            predicted_crop = f"class_{predicted_class_idx}"
        
        # Fetch weather data
        weather = weather_service.get_weather_data("Rwanda")
        # Coerce to float so advisor never gets str (e.g. "N/A")
        used_weather_fallback = False
        try:
            t = weather.get("temperature", 20)
            if t in (None, "N/A"):
                temp_val = 20.0
                used_weather_fallback = True
            else:
                temp_val = float(t)
        except (TypeError, ValueError):
            temp_val = 20.0
            used_weather_fallback = True
        try:
            h = weather.get("humidity", 60)
            if h in (None, "N/A"):
                hum_val = 60.0
                used_weather_fallback = True
            else:
                hum_val = float(h)
        except (TypeError, ValueError):
            hum_val = 60.0
            used_weather_fallback = True

        # Get agronomic advice
        advice = advisor.get_advice(
            crop=predicted_crop,
            temperature=temp_val,
            humidity=hum_val,
        )
        
        return {
            "prediction": predicted_crop,
            "confidence": round(confidence * 100, 2),
            "weather": weather,
            "advice": advice,
             "weather_is_realtime": not used_weather_fallback,
             "weather_note": "Real-time weather unavailable; showing generic advice based on typical conditions."
             if used_weather_fallback
             else "Advice uses real-time weather from Open-Meteo.",
            "timestamp": weather.get("timestamp"),
        }
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Prediction error: {str(e)}")

# --- Weather Endpoint ---
@app.get("/weather")
async def get_weather(location: str = "Rwanda", province: str = "", district: str = ""):
    """Get current weather data for a location (pass province/district for accurate coords)"""
    try:
        display = (f"{district}, {province}".strip(", ") if (district or province) else None) or location or "Rwanda"
        weather = weather_service.get_weather_data(display, province=province, district=district)
        return weather
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Weather error: {str(e)}")

# --- Advice Endpoint ---
@app.post("/advice")
async def get_advice(crop: str, temperature: float = 20, humidity: float = 60):
    """Get agronomic advice for a specific crop"""
    try:
        advice = advisor.get_advice(crop, temperature, humidity)
        return advice
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Advice error: {str(e)}")

# --- Crops List Endpoint ---
@app.get("/crops")
async def get_crops_list():
    """Get list of supported crops"""
    crops = list(advisor.crop_advice.keys())
    return {
        "supported_crops": crops,
        "total": len(crops)
    }

# --- AI Advisor / Season Planning Endpoint ---
@app.post("/advisor")
async def ai_advisor(payload: dict):
    """
    Recommend crops based on province, district, land type and season using the
    Rwanda crop calendar data.

    Expected payload:
    {
      "province": "...",
      "district": "...",
      "sector": "...",
      "cell": "...",
      "village": "...",
      "season": "season-a" | "season-b",
      "landType": "wetland" | "hillside" | "valley" | "plateau"
    }
    """
    if not crop_planner._rows:
        raise HTTPException(
            status_code=500,
            detail="Crop calendar data not available on server",
        )

    province = (payload.get("province") or "").strip()
    district = (payload.get("district") or "").strip()
    season = (payload.get("season") or "").strip()
    land_type = (payload.get("landType") or "").strip()

    # Get location-specific weather data
    location_name = f"{district}, {province}" if district and province else province or "Rwanda"
    weather = weather_service.get_weather_data(
        location=location_name,
        province=province,
        district=district
    )

    # Get crop recommendations with weather consideration
    recs = crop_planner.get_recommendations(
        province=province,
        district=district,
        land_type=land_type,
        season=season,
        weather_data=weather,
    )

    if not recs:
        return {
            "input": {
                "province": province,
                "district": district,
                "season": season,
                "landType": land_type,
            },
            "best_match": None,
            "alternatives": [],
            "message": "No matching crops found for this combination. Try a different land type or season.",
        }

    # First result as best match, rest as alternatives
    best = recs[0]
    alts = recs[1:4]  # limit to 3 alternatives for UI

    # Get weather-based advice for each crop
    def to_dict(r):
        # Get specific advice for this crop based on current weather
        temp = weather.get("temperature")
        humidity = weather.get("humidity")
        
        advice = None
        if temp != "N/A" and humidity != "N/A":
            try:
                temp_float = float(temp) if isinstance(temp, (int, float, str)) and temp != "N/A" else 20
                humidity_float = float(humidity) if isinstance(humidity, (int, float, str)) and humidity != "N/A" else 60
                advice = advisor.get_advice(
                    crop=r.crop,
                    temperature=temp_float,
                    humidity=humidity_float
                )
            except (ValueError, TypeError):
                pass
        
        return {
            "crop": r.crop,
            "agroZone": r.agro_zone,
            "reason": r.reason,
            "sowingWindow": r.sowing_window,
            "growingPeriod": r.growing_period,
            "weatherAdvice": advice,
        }

    return {
        "input": {
            "province": province,
            "district": district,
            "season": season,
            "landType": land_type,
        },
        "weather": weather,
        "best_match": to_dict(best),
        "alternatives": [to_dict(r) for r in alts],
    }

# --- Error Handling ---
@app.exception_handler(HTTPException)
async def http_exception_handler(request, exc):
    return JSONResponse(
        status_code=exc.status_code,
        content={"detail": exc.detail}
    )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)