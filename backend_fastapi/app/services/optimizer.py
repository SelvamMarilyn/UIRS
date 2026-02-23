"""
Resource optimization service using PuLP for crew assignment
"""
from pulp import LpProblem, LpMinimize, LpVariable, lpSum, LpStatus
from typing import List, Dict, Tuple
from datetime import datetime
from geopy.distance import geodesic
from sqlalchemy.orm import Session
from ..models.issue import Issue
from ..models.crew import Crew, Assignment, CrewStatus


class Optimizer:
    def __init__(self):
        self.max_distance_km = 50.0  # Maximum distance for assignment
    
    def calculate_distance(
        self,
        crew_lat: float,
        crew_lon: float,
        issue_lat: float,
        issue_lon: float
    ) -> float:
        """Calculate distance between crew and issue in kilometers"""
        try:
            return geodesic((crew_lat, crew_lon), (issue_lat, issue_lon)).kilometers
        except:
            return float('inf')
    
    def optimize_assignments(
        self,
        db: Session,
        issues: List[Issue],
        crews: List[Crew]
    ) -> List[Tuple[Issue, Crew]]:
        """
        Optimize crew assignments using Linear Programming
        
        Returns:
            List of (issue, crew) tuples for optimal assignments
        """
        if not issues or not crews:
            return []
        
        # Filter available crews
        available_crews = [c for c in crews if c.status == CrewStatus.AVAILABLE]
        if not available_crews:
            return []
        
        # Create optimization problem
        prob = LpProblem("Crew_Assignment", LpMinimize)
        
        # Decision variables: x[i][j] = 1 if crew j is assigned to issue i
        assignments = {}
        for i, issue in enumerate(issues):
            for j, crew in enumerate(available_crews):
                # Check if crew can handle this issue type
                if self._can_handle_issue(crew, issue):
                    # Calculate cost (distance + priority penalty)
                    distance = self.calculate_distance(
                        crew.current_latitude or 0,
                        crew.current_longitude or 0,
                        issue.latitude,
                        issue.longitude
                    )
                    # Cost = distance + (100 - priority_score) / 10
                    # Lower priority issues get higher cost
                    cost = distance + (100 - issue.priority_score) / 10
                    assignments[(i, j)] = LpVariable(f"x_{i}_{j}", cat='Binary')
        
        # Objective: Minimize total cost
        prob += lpSum([
            assignments[(i, j)] * (
                self.calculate_distance(
                    available_crews[j].current_latitude or 0,
                    available_crews[j].current_longitude or 0,
                    issues[i].latitude,
                    issues[i].longitude
                ) + (100 - issues[i].priority_score) / 10
            )
            for (i, j) in assignments.keys()
        ])
        
        # Constraints
        
        # 1. Each issue assigned to at most one crew
        for i in range(len(issues)):
            prob += lpSum([assignments.get((i, j), 0) for j in range(len(available_crews))]) <= 1
        
        # 2. Each crew capacity constraint
        for j, crew in enumerate(available_crews):
            prob += lpSum([
                assignments.get((i, j), 0)
                for i in range(len(issues))
            ]) <= (crew.max_capacity - crew.current_load)
        
        # 3. Distance constraint
        for (i, j) in assignments.keys():
            distance = self.calculate_distance(
                available_crews[j].current_latitude or 0,
                available_crews[j].current_longitude or 0,
                issues[i].latitude,
                issues[i].longitude
            )
            if distance > self.max_distance_km:
                prob += assignments[(i, j)] == 0
        
        # Solve
        prob.solve()
        
        # Extract assignments
        result = []
        for (i, j), var in assignments.items():
            if var.varValue == 1:
                result.append((issues[i], available_crews[j]))
        
        return result
    
    def _can_handle_issue(self, crew: Crew, issue: Issue) -> bool:
        """Check if crew can handle the issue based on department"""
        dept_map = {
            "road_damage": "Road Maintenance",
            "waste_overflow": "Sanitation",
            "streetlight_failure": "Electrical"
        }
        
        required_dept = dept_map.get(issue.category.value, "General")
        return crew.department == required_dept or crew.department == "General"
    
    def create_assignments(
        self,
        db: Session,
        assignments: List[Tuple[Issue, Crew]]
    ):
        """Create assignment records in database"""
        for issue, crew in assignments:
            assignment = Assignment(
                issue_id=issue.id,
                crew_id=crew.id,
                estimated_duration=60  # Default 1 hour
            )
            db.add(assignment)
            
            # Update issue status
            issue.status = "assigned"
            issue.assigned_at = datetime.utcnow()
            
            # Update crew status
            crew.current_load += 1
            if crew.current_load >= crew.max_capacity:
                crew.status = CrewStatus.BUSY
        
        db.commit()


# Singleton instance
optimizer = Optimizer()

