from uuid import uuid4

from fastapi.testclient import TestClient

from backend.db.database import SessionLocal
from backend.main import app
from backend.models.user import User


client = TestClient(app)


def test_user_registration():
    email = f"test-{uuid4().hex}@example.com"

    response = client.post(
        "/users/register",
        json={
            "email": email,
            "password": "TestPassword123!",
        },
    )

    try:
        assert response.status_code == 200

        data = response.json()

        assert data["email"] == email
        assert data["is_active"] is True
        assert "password" not in data
        assert "password_hash" not in data

    finally:
        db = SessionLocal()
        try:
            user = db.query(User).filter(User.email == email).first()
            if user:
                db.delete(user)
                db.commit()
        finally:
            db.close()


def test_duplicate_email_rejected():
    email = f"duplicate-{uuid4().hex}@example.com"

    first_response = client.post(
        "/users/register",
        json={
            "email": email,
            "password": "TestPassword123!",
        },
    )

    try:
        assert first_response.status_code == 200

        second_response = client.post(
            "/users/register",
            json={
                "email": email,
                "password": "TestPassword123!",
            },
        )

        assert second_response.status_code == 409
        assert second_response.json() == {
            "detail": "Email already registered"
        }

    finally:
        db = SessionLocal()
        try:
            user = db.query(User).filter(User.email == email).first()
            if user:
                db.delete(user)
                db.commit()
        finally:
            db.close()
