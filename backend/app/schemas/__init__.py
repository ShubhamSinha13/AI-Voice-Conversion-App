"""
Pydantic schemas for request/response validation
"""

from pydantic import BaseModel, EmailStr
from typing import Optional, List
from datetime import datetime


# User Schemas
class UserCreate(BaseModel):
    """User creation schema"""
    email: EmailStr
    password: str
    username: str


class UserLogin(BaseModel):
    """User login schema"""
    email: EmailStr
    password: str


class UserResponse(BaseModel):
    """User response schema"""
    id: int
    email: str
    username: str
    created_at: datetime
    
    class Config:
        from_attributes = True


# Voice Schemas
class VoiceCreate(BaseModel):
    """Create custom voice schema"""
    name: str
    user_defined_name: str


class VoiceResponse(BaseModel):
    """Voice response schema"""
    id: int
    name: str
    type: str
    category: Optional[str]
    predefined_name: Optional[str]
    user_defined_name: Optional[str]
    sample_count: int
    accuracy_percentage: float
    is_predefined: bool
    created_at: datetime
    
    class Config:
        from_attributes = True


class VoiceDetailResponse(VoiceResponse):
    """Detailed voice response"""
    samples_uploaded_at: List[datetime]
    updated_at: datetime


class VoiceListResponse(BaseModel):
    """List of voices response"""
    predefined_voices: List[VoiceResponse]
    custom_voices: List[VoiceResponse]


# Call Session Schemas
class CallSessionCreate(BaseModel):
    """Create call session schema"""
    voice_id: int
    call_type: Optional[str]


class CallSessionResponse(BaseModel):
    """Call session response schema"""
    id: int
    user_id: int
    voice_id: int
    call_type: Optional[str]
    started_at: datetime
    duration: int
    voice_accuracy: float
    is_predefined: bool
    created_at: datetime
    
    class Config:
        from_attributes = True


# Upload Schemas
class VoiceSampleUpload(BaseModel):
    """Voice sample upload schema"""
    voice_id: int
    sample_file_path: str


# Accuracy Schemas
class AccuracyResponse(BaseModel):
    """Accuracy calculation response"""
    voice_id: int
    accuracy_percentage: float
    sample_count: int
    message: str
    next_suggestion: Optional[str]


# Token Schema
class Token(BaseModel):
    """JWT token schema"""
    access_token: str
    token_type: str
    expires_in: int


class TokenData(BaseModel):
    """Token data schema"""
    email: Optional[str] = None
