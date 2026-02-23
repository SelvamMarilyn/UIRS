"""
Forecasting service using Prophet for hotspot prediction
"""
import pandas as pd
from prophet import Prophet
from typing import List, Dict, Tuple
from datetime import datetime, timedelta
from sqlalchemy.orm import Session
from sqlalchemy import func
from ..models.issue import Issue


class ForecastingService:
    def __init__(self):
        self.model = None
    
    def prepare_time_series_data(
        self,
        db: Session,
        category: str = None,
        days_back: int = 90
    ) -> pd.DataFrame:
        """
        Prepare time series data from historical issues
        
        Returns:
            DataFrame with columns: ds (date), y (count)
        """
        start_date = datetime.utcnow() - timedelta(days=days_back)
        
        query = db.query(
            func.date(Issue.reported_at).label('date'),
            func.count(Issue.id).label('count')
        ).filter(
            Issue.reported_at >= start_date,
            Issue.is_duplicate == False
        )
        
        if category:
            query = query.filter(Issue.category == category)
        
        results = query.group_by('date').all()
        
        # Convert to DataFrame
        data = []
        for date, count in results:
            data.append({'ds': date, 'y': count})
        
        if not data:
            # Return empty DataFrame with correct structure
            return pd.DataFrame(columns=['ds', 'y'])
        
        df = pd.DataFrame(data)
        df['ds'] = pd.to_datetime(df['ds'])
        df = df.sort_values('ds')
        
        return df
    
    def train_model(self, df: pd.DataFrame) -> Prophet:
        """Train Prophet model on historical data"""
        if df.empty or len(df) < 7:  # Need at least 7 days of data
            return None
        
        try:
            model = Prophet(
                yearly_seasonality=False,
                weekly_seasonality=True,
                daily_seasonality=False,
                changepoint_prior_scale=0.05
            )
            model.fit(df)
            return model
        except Exception as e:
            print(f"Prophet training failed: {e}")
            return None

    def predict_hotspots(
        self,
        db: Session,
        category: str = None,
        forecast_days: int = 30
    ) -> List[Dict]:
        """
        Predict future hotspots for the next N days
        """
        try:
            # Prepare historical data
            df = self.prepare_time_series_data(db, category=category)
            
            if df.empty or len(df) < 7:
                return []
            
            # Train model
            model = self.train_model(df)
            if not model:
                return []
            
            # Create future dataframe
            future = model.make_future_dataframe(periods=forecast_days)
            
            # Make predictions
            forecast = model.predict(future)
            
            # Get only forecasted period
            forecasted = forecast.tail(forecast_days)
            
            # Format results
            predictions = []
            for _, row in forecasted.iterrows():
                predictions.append({
                    'date': row['ds'].isoformat(),
                    'predicted_count': int(max(0, row['yhat'])),  # Ensure non-negative
                    'lower_bound': int(max(0, row['yhat_lower'])),
                    'upper_bound': int(max(0, row['yhat_upper']))
                })
            
            return predictions
        except Exception as e:
            print(f"Prediction failed: {e}")
            return []
    
    def get_location_hotspots(
        self,
        db: Session,
        category: str = None,
        days_back: int = 30
    ) -> List[Dict]:
        """
        Get current location-based hotspots (clusters of issues)
        
        Returns:
            List of hotspot locations with coordinates and issue counts
        """
        start_date = datetime.utcnow() - timedelta(days=days_back)
        
        query = db.query(Issue).filter(
            Issue.reported_at >= start_date,
            Issue.is_duplicate == False
        )
        
        if category:
            query = query.filter(Issue.category == category)
        
        issues = query.all()
        
        # Simple clustering: group by rounded coordinates (0.01 degree ≈ 1km)
        from collections import defaultdict
        clusters = defaultdict(list)
        
        for issue in issues:
            # Round to ~1km precision
            lat_rounded = round(issue.latitude, 2)
            lon_rounded = round(issue.longitude, 2)
            key = f"{lat_rounded},{lon_rounded}"
            clusters[key].append(issue)
        
        # Format hotspots
        hotspots = []
        for key, cluster_issues in clusters.items():
            if len(cluster_issues) >= 3:  # At least 3 issues to be a hotspot
                lat, lon = map(float, key.split(','))
                hotspots.append({
                    'latitude': lat,
                    'longitude': lon,
                    'issue_count': len(cluster_issues),
                    'category': category or 'all'
                })
        
        # Sort by issue count
        hotspots.sort(key=lambda x: x['issue_count'], reverse=True)
        
        return hotspots[:20]  # Return top 20 hotspots


# Singleton instance
forecasting_service = ForecastingService()

