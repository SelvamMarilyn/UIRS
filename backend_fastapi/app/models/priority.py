"""
Priority scoring model for tracking priority calculations
"""
from sqlalchemy import Column, Integer, Float, DateTime, ForeignKey
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from ..database import Base


class PriorityScore(Base):
    __tablename__ = "priority_scores"

    id = Column(Integer, primary_key=True, index=True)
    issue_id = Column(Integer, ForeignKey("issues.id"), nullable=False, unique=True)
    
    # Score components
    severity_score = Column(Float, default=0.0)
    age_score = Column(Float, default=0.0)
    upvote_score = Column(Float, default=0.0)
    risk_score = Column(Float, default=0.0)
    total_score = Column(Float, default=0.0)
    
    # Metadata
    calculated_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relationship
    issue = relationship("Issue", backref="priority")

