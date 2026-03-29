"""HTTP-level tests for the CropSense FastAPI app (no running server)."""

import io
import uuid
from unittest.mock import patch

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from PIL import Image

from main import app


def _minimal_png() -> bytes:
    buf = io.BytesIO()
    Image.new("RGB", (8, 8), color=(34, 139, 34)).save(buf, format="PNG")
    return buf.getvalue()


def _weather_stub():
    return {
        "location": "Rwanda",
        "temperature": 22.0,
        "humidity": 60.0,
        "condition": "cloudy",
        "wind_speed": 10.0,
        "precipitation": 0.0,
        "timestamp": "2026-01-01T12:00:00+00:00",
    }


@pytest_asyncio.fixture
async def client():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac


async def _register_user(client: AsyncClient, email: str | None = None, password: str = "testpass123"):
    """Helper: register a user and return (email, token, profile)."""
    email = email or f"pytest_{uuid.uuid4().hex[:12]}@example.com"
    r = await client.post(
        "/auth/register",
        json={"email": email, "password": password, "full_name": "Test User", "phone": "+250780000000"},
    )
    assert r.status_code == 200
    data = r.json()
    return email, data["access_token"], data["profile"]


# ── 1. Root & health ────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_root_returns_json(client: AsyncClient):
    r = await client.get("/")
    assert r.status_code == 200
    data = r.json()
    assert data.get("version") == "1.0.0"
    assert "model_loaded" in data


@pytest.mark.asyncio
async def test_health_endpoint(client: AsyncClient):
    r = await client.get("/health")
    assert r.status_code == 200
    body = r.json()
    assert body["status"] == "healthy"
    assert body["crop_planner_rows"] >= 0


# ── 2. Auth: register, login, me ────────────────────────────────────────────

@pytest.mark.asyncio
async def test_register_returns_token_and_profile(client: AsyncClient):
    email, token, profile = await _register_user(client)
    assert token
    assert profile["email"] == email
    assert profile["full_name"] == "Test User"


@pytest.mark.asyncio
async def test_register_duplicate_email_fails(client: AsyncClient):
    email, _, _ = await _register_user(client)
    r = await client.post(
        "/auth/register",
        json={"email": email, "password": "another123", "full_name": "Dup User"},
    )
    assert r.status_code in (400, 409)
    assert "already" in r.json()["detail"].lower() or "exists" in r.json()["detail"].lower() or "registered" in r.json()["detail"].lower()


@pytest.mark.asyncio
async def test_login_with_correct_password(client: AsyncClient):
    email, _, _ = await _register_user(client, password="mypassword")
    r = await client.post("/auth/login", json={"email": email, "password": "mypassword"})
    assert r.status_code == 200
    assert r.json()["access_token"]


@pytest.mark.asyncio
async def test_login_with_wrong_password(client: AsyncClient):
    email, _, _ = await _register_user(client)
    r = await client.post("/auth/login", json={"email": email, "password": "wrongpassword"})
    assert r.status_code in (400, 401)


@pytest.mark.asyncio
async def test_me_returns_profile(client: AsyncClient):
    email, token, _ = await _register_user(client)
    r = await client.get("/auth/me", headers={"Authorization": f"Bearer {token}"})
    assert r.status_code == 200
    assert r.json()["profile"]["email"] == email


@pytest.mark.asyncio
async def test_me_without_token_fails(client: AsyncClient):
    r = await client.get("/auth/me")
    assert r.status_code in (401, 403)


# ── 3. Profile update ───────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_update_profile(client: AsyncClient):
    _, token, _ = await _register_user(client)
    r = await client.put(
        "/auth/profile",
        headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"},
        json={"full_name": "Updated Name", "province": "Eastern Province", "district": "Rwamagana"},
    )
    assert r.status_code == 200
    profile = r.json()["profile"]
    assert profile["full_name"] == "Updated Name"
    assert profile["province"] == "Eastern Province"


# ── 4. Password reset ───────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_forgot_password_always_returns_success(client: AsyncClient):
    """Never reveals whether email exists — always returns 200."""
    r = await client.post("/auth/forgot-password", json={"email": "nonexistent@example.com"})
    assert r.status_code == 200
    assert "message" in r.json()


@pytest.mark.asyncio
async def test_forgot_password_invalid_email_returns_400(client: AsyncClient):
    r = await client.post("/auth/forgot-password", json={"email": "not-an-email"})
    assert r.status_code == 400


@pytest.mark.asyncio
async def test_reset_password_invalid_token(client: AsyncClient):
    r = await client.post(
        "/auth/reset-password",
        json={"token": "fakeinvalidtoken", "new_password": "newpass123"},
    )
    assert r.status_code == 400
    assert "invalid" in r.json()["detail"].lower() or "expired" in r.json()["detail"].lower()


@pytest.mark.asyncio
async def test_reset_password_short_password(client: AsyncClient):
    r = await client.post(
        "/auth/reset-password",
        json={"token": "sometoken", "new_password": "ab"},
    )
    assert r.status_code == 400
    assert "6" in r.json()["detail"]


# ── 5. Crops and advice ─────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_crops_list(client: AsyncClient):
    r = await client.get("/crops")
    assert r.status_code == 200
    body = r.json()
    assert body["total"] == len(body["supported_crops"])
    assert body["total"] > 0


@pytest.mark.asyncio
async def test_advice_for_known_crop(client: AsyncClient):
    r = await client.post("/advice", params={"crop": "maize", "temperature": 22.0, "humidity": 55.0})
    assert r.status_code == 200
    assert r.json()["crop"] == "maize"
    assert "advice" in r.json()


# ── 6. Prediction ───────────────────────────────────────────────────────────

@pytest.mark.asyncio
@patch("main.weather_service.get_weather_data", return_value=_weather_stub())
async def test_predict_returns_structure(_, client: AsyncClient):
    files = {"file": ("leaf.png", _minimal_png(), "image/png")}
    r = await client.post("/predict", files=files)
    assert r.status_code == 200
    data = r.json()
    assert "prediction" in data
    assert "confidence" in data
    assert "advice" in data


# ── 7. Advisor ───────────────────────────────────────────────────────────────

@pytest.mark.asyncio
@patch("main.weather_service.get_weather_data", return_value=_weather_stub())
async def test_advisor_returns_input_echo(_, client: AsyncClient):
    r = await client.post(
        "/advisor",
        json={
            "province": "Eastern Province",
            "district": "Rwamagana",
            "season": "season-a",
            "landType": "hillside",
        },
    )
    assert r.status_code == 200
    body = r.json()
    assert body["input"]["province"] == "Eastern Province"
    assert body["input"]["landType"] == "hillside"


# ── 8. Season plans ─────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_season_plan_create_and_get(client: AsyncClient):
    _, token, _ = await _register_user(client)
    headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}

    # No active plan initially
    r = await client.get("/season-plans/active", headers={"Authorization": f"Bearer {token}"})
    assert r.status_code == 200
    assert r.json()["plan"] is None

    # Create a plan
    r = await client.post(
        "/season-plans",
        headers=headers,
        json={
            "province": "Eastern Province",
            "district": "Rwamagana",
            "sector": "",
            "cell": "",
            "village": "",
            "season": "season-a",
            "land_type": "hillside",
            "land_size": "2",
        },
    )
    assert r.status_code == 200
    plan = r.json()["plan"]
    assert plan["province"] == "Eastern Province"
    assert plan["is_active"] is True

    # Now active plan should return it
    r = await client.get("/season-plans/active", headers={"Authorization": f"Bearer {token}"})
    assert r.status_code == 200
    assert r.json()["plan"] is not None
    assert r.json()["plan"]["id"] == plan["id"]


@pytest.mark.asyncio
async def test_season_plan_stages_update(client: AsyncClient):
    _, token, _ = await _register_user(client)
    headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}

    # Create plan
    r = await client.post(
        "/season-plans",
        headers=headers,
        json={
            "province": "Western Province",
            "district": "Rusizi",
            "sector": "",
            "cell": "",
            "village": "",
            "season": "season-b",
            "land_type": "wetland",
            "land_size": "1",
        },
    )
    plan_id = r.json()["plan"]["id"]

    # Update a stage
    r = await client.patch(
        f"/season-plans/{plan_id}/stages",
        headers=headers,
        json={"stages": [{"key": "prepare_land", "done": True}]},
    )
    assert r.status_code == 200
    stages = r.json()["plan"]["stages"]
    prep = next(s for s in stages if s["key"] == "prepare_land")
    assert prep["done"] is True
