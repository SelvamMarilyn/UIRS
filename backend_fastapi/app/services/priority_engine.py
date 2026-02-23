"""
Dynamic priority scoring engine
"""
from datetime import datetime, timedelta
from typing import Dict
from ..models.issue import Issue, IssueSeverity


class PriorityEngine:
    def __init__(self):
        # Weight configuration for priority components
        self.weights = {
            'severity': 0.35,
            'age': 0.25,
            'upvotes': 0.20,
            'risk': 0.20
        }
        
        # Severity scores
        self.severity_scores = {
            IssueSeverity.LOW: 10,
            IssueSeverity.MEDIUM: 30,
            IssueSeverity.HIGH: 60,
            IssueSeverity.CRITICAL: 100
        }
    
    def calculate_age_score(self, reported_at: datetime) -> float:
        """
        Calculate age-based score (older issues get higher priority)
        
        Returns:
            Score from 0-100
        """
        if not reported_at:
            return 0.0
        
        now = datetime.utcnow()
        age_hours = (now - reported_at).total_seconds() / 3600
        
        # Exponential increase: 0-24h = 0-30, 24-72h = 30-60, 72h+ = 60-100
        if age_hours < 24:
            score = (age_hours / 24) * 30
        elif age_hours < 72:
            score = 30 + ((age_hours - 24) / 48) * 30
        else:
            score = min(60 + ((age_hours - 72) / 24) * 10, 100)
        
        return score
    
    def calculate_upvote_score(self, upvotes: int) -> float:
        """
        Calculate score based on number of upvotes (duplicate reports)
        
        Returns:
            Score from 0-100 (capped)
        """
        # Each upvote adds 10 points, max 100
        return min(upvotes * 10, 100)
    
    def calculate_risk_score(
        self,
        category: str,
        severity: IssueSeverity,
        latitude: float,
        longitude: float
    ) -> float:
        """
        Calculate risk score based on category, severity, and location
        
        Returns:
            Score from 0-100
        """
        base_risk = 0.0
        
        # Category-based risk
        category_risk = {
            "road_damage": 40,  # High risk for accidents
            "waste_overflow": 30,  # Health risk
            "streetlight_failure": 25  # Safety risk
        }
        base_risk = category_risk.get(category, 20)
        
        # Severity multiplier
        severity_multiplier = {
            IssueSeverity.LOW: 0.5,
            IssueSeverity.MEDIUM: 0.75,
            IssueSeverity.HIGH: 1.0,
            IssueSeverity.CRITICAL: 1.5
        }
        multiplier = severity_multiplier.get(severity, 1.0)
        
        # Location-based risk (could be enhanced with population density data)
        # For now, using a simple heuristic
        risk_score = base_risk * multiplier
        
        return min(risk_score, 100)
    
    def calculate_priority_score(self, issue: Issue) -> Dict[str, float]:
        """
        Calculate comprehensive priority score for an issue
        """
        try:
            # Calculate component scores
            severity_score = self.severity_scores.get(issue.severity, 30)
            age_score = self.calculate_age_score(issue.reported_at)
            upvote_score = self.calculate_upvote_score(issue.upvotes)
            
            category_val = issue.category.value if hasattr(issue.category, 'value') else str(issue.category)
            risk_score = self.calculate_risk_score(
                category_val,
                issue.severity,
                issue.latitude,
                issue.longitude
            )
            
            # Weighted total score
            total_score = (
                severity_score * self.weights['severity'] +
                age_score * self.weights['age'] +
                upvote_score * self.weights['upvotes'] +
                risk_score * self.weights['risk']
            )
            
            # Ensure a minimum floor for any valid issue (at least 5.0)
            total_score = max(total_score, 5.0)
            
            print(f"Priority Calc for Issue {issue.id}: Total={total_score} (Sev={severity_score}, Age={age_score}, Up={upvote_score}, Risk={risk_score})")
            
            return {
                'severity_score': float(severity_score),
                'age_score': float(age_score),
                'upvote_score': float(upvote_score),
                'risk_score': float(risk_score),
                'total_score': round(float(total_score), 2)
            }
        except Exception as e:
            print(f"Error calculating priority score: {e}")
            # Reliable fallback
            return {
                'severity_score': 0.0, 'age_score': 0.0, 'upvote_score': 0.0, 'risk_score': 0.0, 'total_score': 0.0
            }
    
    def update_priority(self, issue: Issue) -> float:
        """
        Update priority score for an issue
        
        Returns:
            Updated total priority score
        """
        scores = self.calculate_priority_score(issue)
        issue.priority_score = scores['total_score']
        return scores['total_score']


# Singleton instance
priority_engine = PriorityEngine()

