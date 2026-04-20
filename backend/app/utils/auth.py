"""
Utility functions for authentication and token management
"""

from datetime import datetime, timedelta
from typing import Optional
from jose import JWTError, jwt
import hashlib
import secrets
from fastapi import Header, HTTPException, status, Depends
from app.config import settings

# For simple password hashing without bcrypt's 72-byte limit
def hash_password(password: str) -> str:
    """Hash a password using PBKDF2"""
    # Use PBKDF2 which doesn't have bcrypt's 72-byte limitation
    salt = secrets.token_hex(32)
    pwd_hash = hashlib.pbkdf2_hmac('sha256', password.encode(), salt.encode(), 100000)
    return f"pbkdf2${salt}${pwd_hash.hex()}"


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify a password against its hash"""
    try:
        if not hashed_password.startswith('pbkdf2$'):
            return False
        
        parts = hashed_password.split('$')
        if len(parts) != 3:
            return False
        
        salt = parts[1]
        stored_hash = parts[2]
        
        # Compute hash with same salt
        computed_hash = hashlib.pbkdf2_hmac('sha256', plain_password.encode(), salt.encode(), 100000)
        
        return computed_hash.hex() == stored_hash
    except Exception:
        return False


def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    """Create JWT access token"""
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=settings.access_token_expire_minutes)
    
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, settings.secret_key, algorithm=settings.algorithm)
    return encoded_jwt


def decode_token(token: str) -> Optional[str]:
    """Decode JWT token and return email"""
    try:
        payload = jwt.decode(token, settings.secret_key, algorithms=[settings.algorithm])
        email: str = payload.get("sub")
        if email is None:
            return None
        return email
    except JWTError:
        return None


async def get_current_user(authorization: Optional[str] = Header(None)):
    """Get current user from Authorization header
    
    This dependency extracts the JWT token from the Authorization header,
    validates it, and returns the User object if valid.
    
    Args:
        authorization: Authorization header in format "Bearer <token>"
    
    Returns:
        User object if valid
        
    Raises:
        HTTPException: If token is invalid or user not found
    """
    from app.database import SessionLocal
    from app.models import User
    
    if not authorization:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Not authenticated"
        )
    
    # Extract token from "Bearer <token>"
    try:
        scheme, token = authorization.split()
        if scheme.lower() != "bearer":
            raise ValueError()
    except (ValueError, AttributeError):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authorization header"
        )
    
    email = decode_token(token)
    if not email:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token"
        )
    
    db = SessionLocal()
    try:
        user = db.query(User).filter(User.email == email).first()
        if not user:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="User not found"
            )
        return user
    finally:
        db.close()
