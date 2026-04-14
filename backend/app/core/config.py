from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    PROJECT_NAME: str = "Assistant AI"
    MONGODB_URL: str
    DATABASE_NAME: str = "assistant_ai"
    
    FIRST_SUPERUSER: str
    FIRST_SUPERUSER_PASSWORD: str

    MONGO_ROOT_USER: str
    MONGO_ROOT_PASSWORD: str

    model_config = SettingsConfigDict(
        env_file=".env", 
        case_sensitive=True,
        extra="ignore"
    )

settings = Settings()
