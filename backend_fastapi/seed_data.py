import os
import random
from datetime import datetime, timedelta
from sqlalchemy.orm import Session
from app.database import SessionLocal, engine, Base
from app.models.user import User
from app.models.issue import Issue, IssueCategory, IssueStatus, IssueSeverity
from app.models.crew import Crew, CrewStatus
from passlib.context import CryptContext

# Setup password hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def get_password_hash(password: str) -> str:
    return pwd_context.hash(password)

def seed_data():
    db = SessionLocal()
    try:
        # 1. Create Admin User
        admin_email = "admin@urbanai.com"
        admin = db.query(User).filter(User.email == admin_email).first()
        if not admin:
            admin = User(
                email=admin_email,
                username="admin",
                hashed_password=get_password_hash("admin123"),
                full_name="System Administrator",
                is_admin=True
            )
            db.add(admin)
            print(f"Created admin user: {admin_email}")
        
        # 2. Create standard citizen user for reports
        citizen_email = "citizen@example.com"
        citizen = db.query(User).filter(User.email == citizen_email).first()
        if not citizen:
            citizen = User(
                email=citizen_email,
                username="citizen",
                hashed_password=get_password_hash("user123"),
                full_name="John Doe",
                is_admin=False
            )
            db.add(citizen)
            print(f"Created citizen user: {citizen_email}")
        
        db.commit()
        db.refresh(admin)
        db.refresh(citizen)

        # 3. Create Crews for each department
        departments = ["Road Maintenance", "Sanitation", "Electrical", "General"]
        for dept in departments:
            # Create 2 crews for each
            for i in range(1, 3):
                crew_name = f"{dept} Crew {i}"
                existing = db.query(Crew).filter(Crew.name == crew_name).first()
                if not existing:
                    crew = Crew(
                        name=crew_name,
                        department=dept,
                        status=CrewStatus.AVAILABLE,
                        max_capacity=5,
                        current_load=0,
                        current_latitude=12.9716 + (random.random() - 0.5) * 0.1,
                        current_longitude=77.5946 + (random.random() - 0.5) * 0.1
                    )
                    db.add(crew)
        print("Seeded crews for all departments.")

        # 4. Seed historical issues for the last 15 days (to enable forecasting)
        categories = list(IssueCategory)
        severities = list(IssueSeverity)
        statuses = [IssueStatus.REPORTED, IssueStatus.VERIFIED, IssueStatus.ASSIGNED, IssueStatus.IN_PROGRESS, IssueStatus.RESOLVED]
        
        # Base location (Bangalore/India example)
        base_lat, base_lon = 12.9716, 77.5946

        print("Seeding 30 historical issues...")
        for i in range(30):
            # Spread across last 15 days
            days_ago = random.randint(0, 15)
            reported_at = datetime.utcnow() - timedelta(days=days_ago, hours=random.randint(0, 23))
            
            # Group some issues into hotspots
            if i < 10:
                # Hotspot 1
                lat = base_lat + 0.01 + (random.random() - 0.5) * 0.005
                lon = base_lon + 0.01 + (random.random() - 0.5) * 0.005
            elif i < 20:
                # Hotspot 2
                lat = base_lat - 0.02 + (random.random() - 0.5) * 0.005
                lon = base_lon + 0.02 + (random.random() - 0.5) * 0.005
            else:
                # Scattered
                lat = base_lat + (random.random() - 0.5) * 0.1
                lon = base_lon + (random.random() - 0.5) * 0.1

            # Correctly map category to department
            category = random.choice(categories)
            dept_map = {
                IssueCategory.ROAD_DAMAGE: "Road Maintenance",
                IssueCategory.WASTE_OVERFLOW: "Sanitation",
                IssueCategory.STREETLIGHT_FAILURE: "Electrical"
            }
            department = dept_map.get(category, "General")

            issue = Issue(
                user_id=citizen.id,
                latitude=lat,
                longitude=lon,
                title=f"Sample Issue {i+1}",
                description=f"Automated sample description for testing analytics and heatmaps. This is a {category} issue.",
                category=category,
                department=department,
                severity=random.choice(severities),
                status=random.choice(statuses),
                priority_score=random.uniform(10, 95),
                reported_at=reported_at,
                is_duplicate=False
            )
            db.add(issue)
        
        db.commit()
        print("Successfully seeded all data!")

    except Exception as e:
        db.rollback()
        print(f"Error seeding data: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    seed_data()
