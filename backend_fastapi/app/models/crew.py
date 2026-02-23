"""
Crew and assignment models for resource allocation
"""
from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, Boolean, Enum
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
import enum
from ..database import Base


class CrewStatus(str, enum.Enum):
    AVAILABLE = "available"
    ASSIGNED = "assigned"
    BUSY = "busy"
    OFFLINE = "offline"


class Crew(Base):
    __tablename__ = "crews"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    department = Column(String, nullable=False)  # road, waste, streetlight
    phone = Column(String)
    email = Column(String)
    
    # Location
    current_latitude = Column(Float)
    current_longitude = Column(Float)
    
    # Status and capacity
    status = Column(Enum(CrewStatus), default=CrewStatus.AVAILABLE)
    max_capacity = Column(Integer, default=5)  # Max concurrent assignments
    current_load = Column(Integer, default=0)
    
    # Skills/capabilities
    skills = Column(String)  # JSON array of skills
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relationships
    assignments = relationship("Assignment", back_populates="crew")


class Assignment(Base):
    __tablename__ = "assignments"

    id = Column(Integer, primary_key=True, index=True)
    issue_id = Column(Integer, ForeignKey("issues.id"), nullable=False)
    crew_id = Column(Integer, ForeignKey("crews.id"), nullable=False)
    
    # Assignment details
    assigned_at = Column(DateTime(timezone=True), server_default=func.now())
    started_at = Column(DateTime(timezone=True), nullable=True)
    completed_at = Column(DateTime(timezone=True), nullable=True)
    estimated_duration = Column(Integer)  # in minutes
    actual_duration = Column(Integer)  # in minutes
    
    # Status
    is_completed = Column(Boolean, default=False)
    
    # Relationships
    issue = relationship("Issue", back_populates="assignments")
    crew = relationship("Crew", back_populates="assignments")

