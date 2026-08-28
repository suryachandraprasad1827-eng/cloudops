from uuid import uuid4

from fastapi.testclient import TestClient

from backend.db.database import SessionLocal
from backend.main import app
from backend.models.user import User
from backend.security.password import hash_password


client = TestClient(app)


def create_test_user():
    email = f"auth-{uuid4().hex}@example.com"
    password = "TestPassword123!"

    db = SessionLocal()

    try:
        user = User(
            email=email,
            password_hash=hash_password(password),
        )
        db.add(user)
        db.commit()
        db.refresh(user)

        return user.id, email, password

    finally:
        db.close()


def delete_test_user(user_id):
    db = SessionLocal()

    try:
        user = db.query(User).filter(User.id == user_id).first()

        if user:
            db.delete(user)
            db.commit()

    finally:
        db.close()


def test_users_me_requires_authentication():
    response = client.get("/users/me")

    assert response.status_code == 401


def test_users_me_rejects_invalid_token():
    response = client.get(
        "/users/me",
        headers={
            "Authorization": "Bearer invalid-token",
        },
    )

    assert response.status_code == 401


def test_users_me_accepts_valid_token():
    user_id, email, password = create_test_user()

    try:
        login_response = client.post(
            "/users/login",
            json={
                "email": email,
                "password": password,
            },
        )

        assert login_response.status_code == 200

        token = login_response.json()["access_token"]

        response = client.get(
            "/users/me",
            headers={
                "Authorization": f"Bearer {token}",
            },
        )

        assert response.status_code == 200

        data = response.json()

        assert data["id"] == user_id
        assert data["email"] == email
        assert data["is_active"] is True

    finally:
        delete_test_user(user_id)
