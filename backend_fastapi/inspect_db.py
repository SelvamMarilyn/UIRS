import os
import pandas as pd
from sqlalchemy import create_engine, text
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")
if DATABASE_URL and DATABASE_URL.startswith("postgres://"):
    DATABASE_URL = DATABASE_URL.replace("postgres://", "postgresql://", 1)

engine = create_engine(DATABASE_URL)

def summary():
    with engine.connect() as connection:
        print("\n--- 📋 RECENT ISSUES ---")
        print(f"{'ID':<4} | {'Status':<10} | {'Score':<8} | {'Category':<20} | {'Title'}")
        print("-" * 70)
        result = connection.execute(text("SELECT id, title, category, status, priority_score FROM issues ORDER BY reported_at DESC LIMIT 10"))
        for row in result:
            print(f"{row[0]:<4} | {row[3]:<10} | {row[4]:<8} | {row[2]:<20} | {row[1]}")

        print("\n--- 👥 REGISTERED USERS ---")
        try:
            users = pd.read_sql('SELECT id, username, email, is_admin FROM users', engine)
            print(users.to_string(index=False))
        except Exception as e:
            print(f"Error fetching users: {e}")

        print("\n--- 📊 SUMMARY ---")
        result = connection.execute(text("SELECT category, COUNT(*) FROM issues GROUP BY category"))
        for row in result:
            print(f"{row[0]:<20}: {row[1]}")

def promote_user(username):
    with engine.connect() as connection:
        try:
            result = connection.execute(text("UPDATE users SET is_admin = TRUE WHERE username = :u"), {"u": username})
            connection.commit()
            if result.rowcount > 0:
                print(f"✅ User '{username}' has been promoted to ADMIN.")
            else:
                print(f"❌ User '{username}' not found.")
        except Exception as e:
            print(f"Error promoting user: {e}")

def demote_user(username):
    with engine.connect() as connection:
        try:
            result = connection.execute(text("UPDATE users SET is_admin = FALSE WHERE username = :u"), {"u": username})
            connection.commit()
            if result.rowcount > 0:
                print(f"✅ User '{username}' has been demoted to CITIZEN.")
            else:
                print(f"❌ User '{username}' not found.")
        except Exception as e:
            print(f"Error demoting user: {e}")

if __name__ == "__main__":
    import sys
    if "--promote" in sys.argv:
        idx = sys.argv.index("--promote")
        if len(sys.argv) > idx + 1:
            promote_user(sys.argv[idx + 1])
        else:
            print("Please provide a username: python inspect_db.py --promote <username>")
    elif "--demote" in sys.argv:
        idx = sys.argv.index("--demote")
        if len(sys.argv) > idx + 1:
            demote_user(sys.argv[idx + 1])
        else:
            print("Please provide a username: python inspect_db.py --demote <username>")
    elif "--summary" in sys.argv or len(sys.argv) == 1:
        summary()
