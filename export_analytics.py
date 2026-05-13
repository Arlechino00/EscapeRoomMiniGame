import firebase_admin
from firebase_admin import credentials, firestore
import pandas as pd
import os

script_dir       = os.path.dirname(os.path.abspath(__file__))
CREDENTIALS_PATH = os.path.join(script_dir, "firebase_credentials.json")

SESSIONS_CSV = os.path.join(script_dir, "sessions.csv")
EVENTS_CSV   = os.path.join(script_dir, "events.csv")
PUZZLE_CSV   = os.path.join(script_dir, "puzzle_summary.csv")

if not os.path.exists(CREDENTIALS_PATH):
    print(f"Error: {CREDENTIALS_PATH} not found.")
    exit(1)

try:
    cred = credentials.Certificate(CREDENTIALS_PATH)
    firebase_admin.initialize_app(cred)
except ValueError:
    pass

db = firestore.client()

print("Fetching data from Firestore via collection group query...")

session_ids = set()
event_rows = []

# Fetch all events across all sessions
events_ref = db.collection_group("events").stream()
for ev in events_ref:
    d = ev.to_dict() or {}
    # Path is usually 'sessions/{session_id}/events/{event_id}'
    path_parts = ev.reference.path.split('/')
    sid = "unknown"
    if len(path_parts) >= 2:
        sid = path_parts[1]
    
    session_ids.add(sid)
    
    event_rows.append({
        "session_id":     sid,
        "event_doc_id":   ev.id,
        "event_id":       d.get("event_id",       ""),
        "timestamp":      d.get("timestamp",      ""),
        "puzzle_id":      d.get("puzzle_id",      ""),
        "completed":      d.get("completed",      ""),
        "time_spent":     d.get("time_spent",     ""),
        "wrong_attempts": d.get("wrong_attempts", ""),
        "hints_used":     d.get("hints_used",     ""),
        "reason":         d.get("reason",         ""),
    })

print(f"Found {len(event_rows)} events across {len(session_ids)} sessions.")

# Fetch session metadata
session_rows = []
for sid in session_ids:
    sdoc = db.collection("sessions").document(sid).get()
    meta = sdoc.to_dict() if sdoc.exists else {}
    session_rows.append({
        "session_id":     sid,
        "player_name":    meta.get("player_name",    ""),
        "start_time":     meta.get("start_time",     ""),
        "end_time":       meta.get("end_time",       ""),
        "total_time":     meta.get("total_time",     ""),
        "completed_game": meta.get("completed_game", False),
        "ending_id":      meta.get("ending_id",      ""),
    })

# ── 1. Sessions ─────────────────────────────────────────────────────────────
if not session_rows:
    print("No sessions found.")
else:
    df_sessions = pd.DataFrame(session_rows)
    df_sessions.sort_values("start_time", ascending=False, inplace=True, ignore_index=True)
    df_sessions.to_csv(SESSIONS_CSV, index=False)
    print(f"[sessions.csv]  {len(df_sessions)} sessions saved.")

# ── 2. Events ───────────────────────────────────────────────────────────────
if not event_rows:
    print("No events found.")
else:
    df_events = pd.DataFrame(event_rows)
    df_events.sort_values(["session_id", "timestamp"], ascending=[True, True],
                          inplace=True, ignore_index=True)
    df_events.to_csv(EVENTS_CSV, index=False)
    print(f"[events.csv]    {len(df_events)} events saved.")

    # ── 3. Puzzle summary ────────────
    solved = df_events[df_events["event_id"] == "puzzle_solved"].copy()
    if not solved.empty:
        player_map = {r["session_id"]: r["player_name"] for r in session_rows}
        solved["player_name"] = solved["session_id"].map(player_map)
        df_puzzle = solved[[
            "session_id", "player_name", "puzzle_id",
            "time_spent", "wrong_attempts", "hints_used", "completed",
        ]].copy()
        df_puzzle.to_csv(PUZZLE_CSV, index=False)
        print(f"[puzzle_summary.csv]  {len(df_puzzle)} rows saved.")
