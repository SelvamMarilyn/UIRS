"""
Issue reporting and management routes
"""
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from sqlalchemy.orm import Session
from typing import List, Optional
from pydantic import BaseModel
from datetime import datetime

from ..database import get_db
from ..models.issue import Issue, IssueCategory, IssueStatus, IssueSeverity
from ..models.user import User
from ..models.priority import PriorityScore
from ..services.image_classifier import image_classifier
from ..services.text_classifier import text_classifier
from ..services.duplicate_checker import duplicate_checker
from ..services.priority_engine import priority_engine

router = APIRouter()


class IssueCreate(BaseModel):
    user_id: int
    latitude: float
    longitude: float
    title: str
    description: Optional[str] = None
    category: Optional[str] = None


class IssueResponse(BaseModel):
    id: int
    user_id: int
    latitude: float
    longitude: float
    address: Optional[str]
    category: str
    title: str
    description: Optional[str]
    severity: str
    status: str
    priority_score: float
    upvotes: int
    department: Optional[str]
    ml_category_confidence: Optional[float]
    ml_severity_confidence: Optional[float]
    image_path: Optional[str]
    reported_at: datetime
    
    class Config:
        from_attributes = True


@router.post("/", response_model=IssueResponse)
async def create_issue(
    user_id: int = Form(...),
    latitude: float = Form(...),
    longitude: float = Form(...),
    title: str = Form(...),
    description: Optional[str] = Form(None),
    category: Optional[str] = Form(None),
    image: Optional[UploadFile] = File(None),
    db: Session = Depends(get_db)
):
    """Create a new issue report with optional image classification"""
    try:
        # Normalize category from user input
        input_category = (category or "road_damage").lower()
        if "road" in input_category:
            detected_category = "road_damage"
        elif "waste" in input_category:
            detected_category = "waste_overflow"
        elif "light" in input_category:
            detected_category = "streetlight_failure"
        else:
            detected_category = "road_damage"

        severity = "medium"
        severity_confidence = 0.5
        department = "public_works"
        ml_confidence = 0.0
        image_hash = None
        image_path = None

        if image and image.filename:
            # Read image
            image_bytes = await image.read()

            if image_bytes:
                # Classify image
                try:
                    # Compute hash for duplicate detection
                    image_hash = duplicate_checker.compute_image_hash(image_bytes)
                    
                    detected_category_ml, ml_confidence = image_classifier.classify(image_bytes)
                    
                    # Hybrid Logic & Conflict Detection
                    if detected_category != detected_category_ml:
                        if ml_confidence > 0.6:
                            # HIGH CONFIDENCE OVERRIDE: Smart Resolve
                            original_label = detected_category
                            detected_category = detected_category_ml
                            note = f"(AI auto-corrected from {original_label} based on visual evidence)"
                            description = f"{description}\n\n[SYSTEM NOTE] {note}" if description else note
                        else:
                            # MEDIUM CONFIDENCE CONFLICT: Flag for Admin
                            note = f"(⚠️ POSSIBLE CONFLICT: User selected {detected_category}, but AI detected {detected_category_ml})"
                            description = f"{description}\n\n[SYSTEM NOTE] {note}" if description else note
                    
                    elif not category:
                        # No user category provided, use AI
                        detected_category = detected_category_ml
                        
                except Exception as e:
                    print(f"Error in hybrid resolution: {e}")
                    pass

                # Classify text (now using the resolved category)
                try:
                    text_input = f"{title} {description or ''}"
                    severity, severity_confidence = text_classifier.classify_severity(text_input)
                    department = text_classifier.classify_department(text_input, detected_category)
                except Exception:
                    pass

                # Save image
                import os
                os.makedirs("uploads", exist_ok=True)
                image_path = f"uploads/{datetime.utcnow().timestamp()}_{user_id}.jpg"
                with open(image_path, "wb") as f:
                    f.write(image_bytes)
        else:
            # Still classify text even without image
            try:
                text_input = f"{title} {description or ''}"
                severity, severity_confidence = text_classifier.classify_severity(text_input)
                department = text_classifier.classify_department(text_input, detected_category)
            except Exception:
                pass

        # Validate and convert to enum
        try:
            issue_category = IssueCategory(detected_category)
        except ValueError:
            issue_category = IssueCategory.ROAD_DAMAGE

        # Duplicate detection (Now after category normalization)
        if image and image_hash:
            try:
                duplicate_issue = duplicate_checker.find_duplicates(
                    db, image_hash, latitude, longitude, issue_category.value
                )
                if duplicate_issue:
                    duplicate_checker.increment_upvotes(db, duplicate_issue)
                    return IssueResponse.from_orm(duplicate_issue)
            except Exception as e:
                db.rollback()
                print(f"Error in duplicate detection: {e}")
                # Log error but continue with creation if detection fails safely

        # Create issue
        issue = Issue(
            user_id=user_id,
            latitude=latitude,
            longitude=longitude,
            title=title,
            description=description,
            category=issue_category,
            severity=IssueSeverity(severity),
            image_path=image_path,
            image_hash=image_hash,
            ml_category_confidence=float(ml_confidence),
            ml_severity_confidence=float(severity_confidence),
            department=department
        )

        db.add(issue)
        db.commit()
        db.refresh(issue)

        # Calculate priority score
        try:
            scores = priority_engine.calculate_priority_score(issue)
            issue.priority_score = scores['total_score']
            priority_record = PriorityScore(
                issue_id=issue.id,
                severity_score=scores['severity_score'],
                age_score=scores['age_score'],
                upvote_score=scores['upvote_score'],
                risk_score=scores['risk_score'],
                total_score=scores['total_score']
            )
            db.add(priority_record)
            db.commit()
            db.refresh(issue)
        except Exception:
            pass

        return IssueResponse.from_orm(issue)

    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Error creating issue: {str(e)}")


@router.get("/", response_model=List[IssueResponse])
def get_issues(
    category: Optional[str] = None,
    status: Optional[str] = None,
    limit: int = 50,
    offset: int = 0,
    db: Session = Depends(get_db)
):
    """Get list of issues with optional filters"""
    query = db.query(Issue).filter(Issue.is_duplicate == False)
    
    if category:
        query = query.filter(Issue.category == IssueCategory(category))
    if status:
        query = query.filter(Issue.status == IssueStatus(status))
    
    issues = query.order_by(Issue.priority_score.desc()).offset(offset).limit(limit).all()
    return [IssueResponse.from_orm(issue) for issue in issues]


@router.get("/{issue_id}", response_model=IssueResponse)
def get_issue(issue_id: int, db: Session = Depends(get_db)):
    """Get a specific issue by ID"""
    issue = db.query(Issue).filter(Issue.id == issue_id).first()
    if not issue:
        raise HTTPException(status_code=404, detail="Issue not found")
    return IssueResponse.from_orm(issue)


@router.put("/{issue_id}/status")
def update_issue_status(
    issue_id: int,
    status: str,
    db: Session = Depends(get_db)
):
    """Update issue status"""
    issue = db.query(Issue).filter(Issue.id == issue_id).first()
    if not issue:
        raise HTTPException(status_code=404, detail="Issue not found")
    
    issue.status = IssueStatus(status)
    if status == "resolved":
        issue.resolved_at = datetime.utcnow()
    
    db.commit()
    return {"message": "Status updated successfully"}

