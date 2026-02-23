"""
Admin dashboard routes
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import List, Dict
from datetime import datetime, timedelta

from ..database import get_db
from ..models.issue import Issue, IssueStatus
from ..models.crew import Crew, Assignment
from ..models.user import User
from ..routes.users import get_current_user
from ..services.optimizer import optimizer
from ..services.forecasting_service import forecasting_service

router = APIRouter()


@router.get("/dashboard/stats")
def get_dashboard_stats(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get dashboard statistics"""
    if not current_user.is_admin:
        raise HTTPException(status_code=403, detail="Admin access required")
    
    # Total issues
    total_issues = db.query(func.count(Issue.id)).filter(
        Issue.is_duplicate == False
    ).scalar()
    
    # Issues by status
    status_counts = db.query(
        Issue.status,
        func.count(Issue.id)
    ).filter(
        Issue.is_duplicate == False
    ).group_by(Issue.status).all()
    
    # Issues by category
    category_counts = db.query(
        Issue.category,
        func.count(Issue.id)
    ).filter(
        Issue.is_duplicate == False
    ).group_by(Issue.category).all()
    
    # High priority issues
    high_priority = db.query(func.count(Issue.id)).filter(
        Issue.is_duplicate == False,
        Issue.priority_score >= 70
    ).scalar()
    
    # Recent issues (last 7 days)
    recent_date = datetime.utcnow() - timedelta(days=7)
    recent_issues = db.query(func.count(Issue.id)).filter(
        Issue.reported_at >= recent_date,
        Issue.is_duplicate == False
    ).scalar()
    
    return {
        "total_issues": total_issues,
        "status_breakdown": {status.value: count for status, count in status_counts},
        "category_breakdown": {category.value: count for category, count in category_counts},
        "high_priority_count": high_priority,
        "recent_issues_7d": recent_issues
    }


@router.get("/issues/priority-list")
def get_priority_list(
    limit: int = 50,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get issues sorted by priority"""
    if not current_user.is_admin:
        raise HTTPException(status_code=403, detail="Admin access required")
    
    issues = db.query(Issue).filter(
        Issue.is_duplicate == False,
        Issue.status != IssueStatus.RESOLVED
    ).order_by(
        Issue.priority_score.desc()
    ).limit(limit).all()
    
    return [
        {
            "id": issue.id,
            "title": issue.title,
            "category": issue.category.value,
            "severity": issue.severity.value,
            "priority_score": issue.priority_score,
            "status": issue.status.value,
            "latitude": issue.latitude,
            "longitude": issue.longitude,
            "reported_at": issue.reported_at.isoformat()
        }
        for issue in issues
    ]


@router.post("/assignments/optimize")
def optimize_assignments(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Optimize crew assignments for pending issues"""
    if not current_user.is_admin:
        raise HTTPException(status_code=403, detail="Admin access required")
    
    # Get unassigned high-priority issues
    issues = db.query(Issue).filter(
        Issue.is_duplicate == False,
        Issue.status == IssueStatus.VERIFIED,
        Issue.priority_score >= 50
    ).limit(20).all()
    
    # Get available crews
    crews = db.query(Crew).filter(
        Crew.status == "available"
    ).all()
    
    if not issues or not crews:
        return {"message": "No issues or crews available for assignment"}
    
    # Optimize assignments
    assignments = optimizer.optimize_assignments(db, issues, crews)
    
    # Create assignment records
    optimizer.create_assignments(db, assignments)
    
    return {
        "message": f"Optimized {len(assignments)} assignments",
        "assignments": [
            {"issue_id": issue.id, "crew_id": crew.id}
            for issue, crew in assignments
        ]
    }


@router.get("/crews")
def get_crews(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get all crews"""
    if not current_user.is_admin:
        raise HTTPException(status_code=403, detail="Admin access required")
    
    crews = db.query(Crew).all()
    return [
        {
            "id": crew.id,
            "name": crew.name,
            "department": crew.department,
            "status": crew.status.value,
            "current_load": crew.current_load,
            "max_capacity": crew.max_capacity
        }
        for crew in crews
    ]

