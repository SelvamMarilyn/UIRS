"""
Analytics and forecasting routes
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import Optional

from ..database import get_db
from ..models.user import User
from ..routes.users import get_current_user
from ..services.forecasting_service import forecasting_service

router = APIRouter()


@router.get("/forecast/hotspots")
def get_forecasted_hotspots(
    category: Optional[str] = None,
    forecast_days: int = 30,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get forecasted issue hotspots"""
    if not current_user.is_admin:
        raise HTTPException(status_code=403, detail="Admin access required")
    
    predictions = forecasting_service.predict_hotspots(
        db, category=category, forecast_days=forecast_days
    )
    
    return {
        "category": category or "all",
        "forecast_days": forecast_days,
        "predictions": predictions
    }


@router.get("/hotspots/current")
def get_current_hotspots(
    category: Optional[str] = None,
    days_back: int = 30,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get current location-based hotspots"""
    if not current_user.is_admin:
        raise HTTPException(status_code=403, detail="Admin access required")
    
    hotspots = forecasting_service.get_location_hotspots(
        db, category=category, days_back=days_back
    )
    
    return {
        "category": category or "all",
        "days_back": days_back,
        "hotspots": hotspots
    }

