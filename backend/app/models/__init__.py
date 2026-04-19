"""
Database models for User, Voice, and CallSession
"""

from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, Boolean, Text, ARRAY
from sqlalchemy.orm import relationship
from datetime import datetime
from app.database import Base


class User(Base):
    """User model"""
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, index=True, nullable=False)
    password_hash = Column(String(255), nullable=False)
    username = Column(String(255), unique=True, index=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    voices = relationship("Voice", back_populates="user", cascade="all, delete-orphan")
    call_sessions = relationship("CallSession", back_populates="user", cascade="all, delete-orphan")


class Voice(Base):
    """Voice model for both predefined and custom voices"""
    __tablename__ = "voices"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)  # None for predefined
    name = Column(String(255), nullable=False)
    type = Column(String(50), nullable=False)  # 'predefined' or 'custom'
    category = Column(String(50), nullable=True)  # 'female', 'men', 'special' for predefined
    predefined_name = Column(String(255), nullable=True)  # e.g., 'Female Voice 1', 'Robotic'
    user_defined_name = Column(String(255), nullable=True)  # Custom voice name from user
    
    speaker_embedding = Column(Text, nullable=True)  # Serialized numpy array
    model_path = Column(String(255), nullable=True)  # Path to voice model file
    
    sample_count = Column(Integer, default=0)
    accuracy_percentage = Column(Float, default=0.0)  # 80-99%
    samples_uploaded_at = Column(ARRAY(DateTime), default=list)  # List of upload timestamps
    
    is_predefined = Column(Boolean, default=False)
    
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    user = relationship("User", back_populates="voices")
    call_sessions = relationship("CallSession", back_populates="voice")


class CallSession(Base):
    """Call session tracking"""
    __tablename__ = "call_sessions"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    voice_id = Column(Integer, ForeignKey("voices.id"), nullable=False)
    
    call_type = Column(String(50), nullable=True)  # 'whatsapp', 'telegram', 'native', 'voip'
    started_at = Column(DateTime, default=datetime.utcnow)
    duration = Column(Integer, default=0)  # Duration in seconds
    
    voice_accuracy = Column(Float, default=0.0)  # 99% etc
    is_predefined = Column(Boolean, default=False)
    
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    user = relationship("User", back_populates="call_sessions")
    voice = relationship("Voice", back_populates="call_sessions")
