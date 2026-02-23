from app.database import SessionLocal
from app.services.forecasting_service import forecasting_service

def test_forecast():
    db = SessionLocal()
    try:
        print("Testing Current Hotspots...")
        hotspots = forecasting_service.get_location_hotspots(db)
        print(f"Found {len(hotspots)} hotspots")
        for hs in hotspots:
            print(hs)
            
        print("\nTesting Forecasted Hotspots...")
        # Note: Prophet might still fail if all 30 issues have the same 'ds' (date)
        # and we seeded them random over 15 days, so it should be fine.
        predictions = forecasting_service.predict_hotspots(db)
        print(f"Generated {len(predictions)} predictions")
        if predictions:
            print("First 3 predictions:")
            for p in predictions[:3]:
                print(p)
        else:
            print("No predictions generated (likely due to date clustering).")
            
    finally:
        db.close()

if __name__ == "__main__":
    test_forecast()
