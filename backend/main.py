from fastapi import Depends, FastAPI, HTTPException
from sqlalchemy.exc import IntegrityError

from backend.core.config import settings
from backend.db.database import SessionLocal
from backend.dependencies.auth import get_current_user
from backend.models.user import User
from backend.schemas.auth import LoginRequest, TokenResponse
from backend.schemas.user import UserCreate
from backend.security.jwt import create_access_token
from backend.security.password import hash_password
from backend.services.auth import authenticate_user

app = FastAPI(title=settings.app_name)


@app.get("/health")
def health_check():
    return {
        "status": "healthy",
        "service": settings.app_name,
        "environment": settings.app_env,
    }


@app.post("/users/register")
def register_user(user_data: UserCreate):
    db = SessionLocal()

    try:
        existing_user = (
            db.query(User)
            .filter(User.email == user_data.email)
            .first()
        )

        if existing_user:
            raise HTTPException(
                status_code=409,
                detail="Email already registered",
            )

        user = User(
            email=user_data.email,
            password_hash=hash_password(user_data.password),
        )

        db.add(user)
        db.commit()
        db.refresh(user)

        return {
            "id": user.id,
            "email": user.email,
            "is_active": user.is_active,
        }

    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=409,
            detail="Email already registered",
        )

    finally:
        db.close()


@app.post("/users/login", response_model=TokenResponse)
def login_user(login_data: LoginRequest):
    db = SessionLocal()

    try:
        user = authenticate_user(
            db,
            login_data.email,
            login_data.password,
        )

        if not user:
            raise HTTPException(
                status_code=401,
                detail="Invalid email or password",
            )

        access_token = create_access_token(str(user.id))

        return {
            "access_token": access_token,
            "token_type": "bearer",
        }

    finally:
        db.close()
@app.get("/users/me")
def get_my_profile(current_user: User = Depends(get_current_user)):
    return {
        "id": current_user.id,
        "email": current_user.email,
        "is_active": current_user.is_active,
    }
