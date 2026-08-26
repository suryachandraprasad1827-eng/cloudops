from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "CloudOps"
    app_env: str = "development"
    app_port: int = 8000

    database_host: str = "127.0.0.1"
    database_port: int = 5432
    database_name: str = "cloudops"
    database_user: str = "cloudops"
    database_password: str = ""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )


settings = Settings()
