"""
Application configuration settings
"""

from pydantic_settings import BaseSettings
from typing import Optional


class Settings(BaseSettings):
    """Application settings from environment variables"""
    
    # Database
    database_url: str = "postgresql://user:password@localhost:5432/voice_converter_db"
    
    # JWT
    secret_key: str = "your-secret-key-change-in-production"
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 30
    
    # Server
    api_host: str = "0.0.0.0"
    api_port: int = 8000
    environment: str = "development"
    
    # File Storage
    upload_dir: str = "./uploads"
    max_upload_size: int = 52428800  # 50MB
    
    # AWS S3 (Optional)
    aws_access_key_id: Optional[str] = None
    aws_secret_access_key: Optional[str] = None
    aws_bucket_name: Optional[str] = None
    
    # ML Models
    model_path: str = "./ml_models"
    device: str = "cuda"  # or cpu
    
    class Config:
        env_file = ".env"
        case_sensitive = False


settings = Settings()
