"""
Issue model for storing citizen-reported urban issues
"""
from sqlalchemy import Column, Integer, String, Float, DateTime, Text, Boolean, ForeignKey, Enum
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
import enum
from ..database import Base


class IssueCategory(str, enum.Enum):
    ROAD_DAMAGE = "road_damage"
    WASTE_OVERFLOW = "waste_overflow"
    STREETLIGHT_FAILURE = "streetlight_failure"


class IssueStatus(str, enum.Enum):
    REPORTED = "reported"
    VERIFIED = "verified"
    ASSIGNED = "assigned"
    IN_PROGRESS = "in_progress"
    RESOLVED = "resolved"
    REJECTED = "rejected"


class IssueSeverity(str, enum.Enum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"


class Issue(Base):
    __tablename__ = "issues"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    
    # Location data
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    address = Column(String)  # Reverse geocoded address
    
    # Issue details
    category = Column(Enum(IssueCategory), nullable=False)
    title = Column(String, nullable=False)
    description = Column(Text)
    severity = Column(Enum(IssueSeverity), default=IssueSeverity.MEDIUM)
    status = Column(Enum(IssueStatus), default=IssueStatus.REPORTED)
    
    # Media
    image_path = Column(String)  # Path to uploaded image
    image_hash = Column(String)  # Perceptual hash for duplicate detection
    
    # Classification results
    ml_category_confidence = Column(Float)  # Confidence from image classifier
    ml_severity_confidence = Column(Float)  # Confidence from text classifier
    department = Column(String)  # Assigned department
    
    # Priority and tracking
    priority_score = Column(Float, default=0.0)
    upvotes = Column(Integer, default=0)  # Merged duplicate reports
    is_duplicate = Column(Boolean, default=False)
    duplicate_of = Column(Integer, ForeignKey("issues.id"), nullable=True)
    
    # Timestamps
    reported_at = Column(DateTime(timezone=True), server_default=func.now())
    verified_at = Column(DateTime(timezone=True), nullable=True)
    assigned_at = Column(DateTime(timezone=True), nullable=True)
    resolved_at = Column(DateTime(timezone=True), nullable=True)
    
    # Relationships
    user = relationship("User", backref="issues")
    assignments = relationship("Assignment", back_populates="issue")

