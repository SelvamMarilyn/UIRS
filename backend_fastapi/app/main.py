"""
Main FastAPI application entry point
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
import os
from .database import engine, Base
from .routes import issues, users, admin, analytics

# Create database tables (only if database is available)
try:
    Base.metadata.create_all(bind=engine)
    print("[OK] Database tables created/verified successfully")
except Exception as e:
    print(f"[WARNING] Could not connect to database: {e}")
    print("[WARNING] Server will start but database features will not work until connection is established")
    print("[WARNING] Please check your DATABASE_URL in .env file")

app = FastAPI(
    title="Predictive Urban Issue Management System API",
    description="AI-powered civic issue management system with ML classification and predictive analytics",
    version="1.0.0"
)

# CORS middleware for Flutter frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify exact origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Ensure uploads directory exists
os.makedirs("uploads", exist_ok=True)

# Serve static files (uploads)
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

# Include routers
app.include_router(issues.router, prefix="/api/issues", tags=["Issues"])
app.include_router(users.router, prefix="/api/users", tags=["Users"])
app.include_router(admin.router, prefix="/api/admin", tags=["Admin"])
app.include_router(analytics.router, prefix="/api/analytics", tags=["Analytics"])


@app.get("/")
async def root():
    return {
        "message": "Predictive Urban Issue Management System API",
        "version": "1.0.0",
        "status": "running"
    }


@app.get("/health")
async def health_check():
    return {"status": "healthy"}

