import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
import pandas as pd
import os

# 1. Setup
script_dir = os.path.dirname(os.path.abspath(__file__))
CREDENTIALS_PATH = os.path.join(script_dir, "firebase_credentials.json")
OUTPUT_FILE = os.path.join(script_dir, "analytics_report.csv")

if not os.path.exists(CREDENTIALS_PATH):
    print(f"Error: {CREDENTIALS_PATH} not found. Download it from Firebase Console > Project Settings > Service Accounts.")
    exit(1)

# 2. Initialize Firebase
cred = credentials.Certificate(CREDENTIALS_PATH)
firebase_admin.initialize_app(cred)
db = firestore.client()

print("Fetching data from Firestore...")

# 3. Fetch Data
all_events = []

print("Searching for events in all sessions (using collection_group)...")

# collection_group finds all collections named "events" anywhere in the database
# This is better because it finds events even if the parent session document 
# is a "phantom" document (has subcollections but no data itself).
events = db.collection_group("events").stream()

for event in events:
    event_data = event.to_dict()
    # Path is: sessions/SESSION_ID/events/EVENT_ID
    # We can extract the session_id from the document path
    path_parts = event.reference.path.split("/")
    if len(path_parts) >= 2:
        event_data["session_id"] = path_parts[1]
    
    event_data["event_id"] = event.id
    all_events.append(event_data)

# 4. Process and Save
if not all_events:
    print("No events found in Firestore!")
else:
    df = pd.DataFrame(all_events)
    
    # Clean up column order if desired
    cols = ["timestamp", "event", "puzzle_id", "level_id", "time_spent_seconds", "reason", "session_id"]
    # Only include columns that actually exist in the data
    existing_cols = [c for c in cols if c in df.columns]
    df = df[existing_cols]
    
    # Sort by timestamp
    if "timestamp" in df.columns:
        df = df.sort_values(by="timestamp", ascending=False)

    df.to_csv(OUTPUT_FILE, index=False)
    print(f"Success! Exported {len(all_events)} events to {OUTPUT_FILE}")
