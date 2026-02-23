"""
Duplicate detection service using perceptual hashing and geo-distance clustering
"""
import imagehash
from PIL import Image
import io
from geopy.distance import geodesic
from typing import List, Tuple, Optional
from sqlalchemy.orm import Session
from ..models.issue import Issue
from datetime import datetime, timedelta


class DuplicateChecker:
    def __init__(self):
        self.hash_size = 16  # Perceptual hash size
        self.geo_threshold_km = 0.1  # 100 meters threshold for duplicate detection
        self.time_threshold_hours = 24  # Consider reports within 24 hours
    
    def compute_image_hash(self, image_bytes: bytes) -> str:
        """Compute perceptual hash of image"""
        try:
            image = Image.open(io.BytesIO(image_bytes))
            image_hash = imagehash.phash(image, hash_size=self.hash_size)
            return str(image_hash)
        except Exception as e:
            print(f"Error computing image hash: {e}")
            return ""
    
    def hash_similarity(self, hash1: str, hash2: str) -> float:
        """Calculate similarity between two hashes (0-1, higher is more similar)"""
        if not hash1 or not hash2:
            return 0.0
        
        try:
            h1 = imagehash.hex_to_hash(hash1)
            h2 = imagehash.hex_to_hash(hash2)
            # Normalize hamming distance to similarity (0-1)
            max_distance = len(h1.hash) * 8  # Maximum possible hamming distance
            distance = h1 - h2
            similarity = 1.0 - (distance / max_distance)
            return similarity
        except Exception as e:
            print(f"Error calculating hash similarity: {e}")
            return 0.0
    
    def geo_distance_km(self, lat1: float, lon1: float, lat2: float, lon2: float) -> float:
        """Calculate distance between two coordinates in kilometers"""
        try:
            return geodesic((lat1, lon1), (lat2, lon2)).kilometers
        except Exception as e:
            print(f"Error calculating geo distance: {e}")
            return float('inf')
    
    def find_duplicates(
        self,
        db: Session,
        image_hash: str,
        latitude: float,
        longitude: float,
        category: str,
        time_window_hours: int = None
    ) -> Optional[Issue]:
        """
        Find duplicate issues based on image hash, location, and time
        
        Returns:
            Issue object if duplicate found, None otherwise
        """
        if not image_hash:
            return None
        
        time_window = time_window_hours or self.time_threshold_hours
        time_threshold = datetime.utcnow() - timedelta(hours=time_window)
        
        # Query recent issues of the same category
        recent_issues = db.query(Issue).filter(
            Issue.category == category,
            Issue.reported_at >= time_threshold,
            Issue.is_duplicate == False,
            Issue.image_hash.isnot(None)
        ).all()
        
        best_match = None
        best_similarity = 0.0
        
        for issue in recent_issues:
            if not issue.image_hash:
                continue
            
            # Check image hash similarity
            hash_sim = self.hash_similarity(image_hash, issue.image_hash)
            
            # Check geo distance
            geo_dist = self.geo_distance_km(
                latitude, longitude,
                issue.latitude, issue.longitude
            )
            
            # Consider duplicate if:
            # 1. Hash similarity > 0.85 (very similar images)
            # 2. AND geo distance < threshold (same location)
            if hash_sim > 0.85 and geo_dist < self.geo_threshold_km:
                if hash_sim > best_similarity:
                    best_similarity = hash_sim
                    best_match = issue
        
        return best_match
    
    def mark_as_duplicate(
        self,
        db: Session,
        duplicate_issue: Issue,
        original_issue: Issue
    ):
        """Mark an existing issue as duplicate and increment upvotes on original"""
        duplicate_issue.is_duplicate = True
        duplicate_issue.duplicate_of = original_issue.id
        original_issue.upvotes += 1
        
        # Trigger priority re-calculation
        from .priority_engine import priority_engine
        priority_engine.update_priority(original_issue)
        
        db.commit()

    def increment_upvotes(self, db: Session, original_issue: Issue):
        """Increment upvotes on an issue without marking a new one (used when a new report is a duplicate)"""
        original_issue.upvotes += 1
        
        # Trigger priority re-calculation
        from .priority_engine import priority_engine
        priority_engine.update_priority(original_issue)
        
        db.commit()


# Singleton instance
duplicate_checker = DuplicateChecker()

