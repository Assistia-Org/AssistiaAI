from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    PROJECT_NAME: str = "Assistant AI"
    MONGODB_URL: str
    REDIS_URL: str = ""
    DATABASE_NAME: str = "assistant_ai"
    
    FIRST_SUPERUSER: str
    FIRST_SUPERUSER_PASSWORD: str

    MONGO_ROOT_USER: str
    MONGO_ROOT_PASSWORD: str
    OPENROUTER_API_KEY: str = ""
    RESEND_API_KEY: str = ""
    EMAILS_FROM_EMAIL: str = ""
    BACKEND_URL: str = ""

    # JWT Settings
    SECRET_KEY: str = "your-complex-secret-key-for-development"  # In production, use env
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30  # 30 minutes
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7  # 1 week

    model_config = SettingsConfigDict(
        env_file=".env", 
        case_sensitive=True,
        extra="ignore"
    )

settings = Settings()
