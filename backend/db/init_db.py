from backend.db.database import Base, engine
from backend.models.user import User


def init_db() -> None:
    Base.metadata.create_all(bind=engine)


if __name__ == "__main__":
    init_db()
    print("Database tables created successfully")
