"""API routes initialization"""

from fastapi import APIRouter
from app.api.voices import router as voices_router

api_router = APIRouter(prefix="/api")
api_router.include_router(voices_router)
