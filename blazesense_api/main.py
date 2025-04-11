from fastapi import FastAPI
from pydantic import BaseModel
from datetime import datetime
from dotenv import load_dotenv
from supabase import create_client, Client
import os

# Load .env variables
load_dotenv()

# Connect to Supabase
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# Create FastAPI app
app = FastAPI()

# Data model for fire detection
class FireNotification(BaseModel):
    user_id: str
    camera_id: str
    message: str = "🔥 Fire Detected!"
    timestamp: datetime = datetime.utcnow()

@app.get("/")
def root():
    return {"message": "🔥 BlazeSense API is up and running!"}

@app.post("/detect/fire")
def detect_fire(data: FireNotification):
    # Send to Supabase DB
    try:
        response = supabase.table("notifications").insert({
            "user_id": data.user_id,
            "camera_id": data.camera_id,
            "message": data.message,
            "timestamp": data.timestamp.isoformat(),
            "is_reviewed": False  
        }).execute()
        return {"status": "success", "data": response.data}
    except Exception as e:
        return {"status": "error", "message": str(e)}

@app.get("/notifications")
def get_notifications():
    try:
        response = supabase.table("notifications").select("*").order("timestamp", desc=True).execute()
        return response.data
    except Exception as e:
        return {"status": "error", "message": str(e)}
