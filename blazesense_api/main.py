# main.py
import uuid
from fastapi import FastAPI, HTTPException, Request
from pydantic import BaseModel
from datetime import datetime
from dotenv import load_dotenv
from supabase import create_client, Client
import os
import uvicorn

load_dotenv()
from config import SUPABASE_URL, SUPABASE_KEY

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
app = FastAPI()

# === IN-MEMORY TEMP STORE ===
latest_activation_key_id: str | None = None

# === MODELS ===
class FireNotification(BaseModel):
    user_id: str
    camera_id: str
    message: str = "🔥 Fire Detected!"
    timestamp: datetime = datetime.utcnow()

class LoginRequest(BaseModel):
    user_id: uuid.UUID
    activation_key_id: uuid.UUID

class ActivationKeyUpdate(BaseModel):
    activation_key_id: uuid.UUID

# === ENDPOINTS ===
@app.get("/")
def root():
    return {"message": "🔥 BlazeSense API is up and running!"}

@app.post("/detect/fire")
def detect_fire(data: FireNotification):
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

@app.post("/login")
def login_user(data: LoginRequest):
    try:
        relation_response = supabase.table("activation_key_users") \
            .select("*") \
            .eq("user_id", str(data.user_id)) \
            .eq("activation_key_id", str(data.activation_key_id)) \
            .execute()

        if not relation_response.data:
            raise HTTPException(status_code=403, detail="User is not associated with this activation key.")

        return {
            "status": "success",
            "message": "User logged in.",
            "activation_key_id": str(data.activation_key_id)
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/update-activation")
def update_activation_key(data: ActivationKeyUpdate):
    global latest_activation_key_id
    latest_activation_key_id = str(data.activation_key_id)
    return {"status": "success", "activation_key_id": latest_activation_key_id}

@app.get("/get-latest-activation")
def get_latest_activation():
    if not latest_activation_key_id:
        raise HTTPException(status_code=404, detail="No activation key has been set.")
    return get_camera_info(latest_activation_key_id)

@app.get("/camera-info/{activation_key_id}")
def get_camera_info(activation_key_id: str):
    try:
        relation_response = supabase.table("activation_key_users") \
            .select("user_id") \
            .eq("activation_key_id", activation_key_id) \
            .limit(1) \
            .execute()

        if not relation_response.data:
            raise HTTPException(status_code=404, detail="No users tied to this activation key.")

        user_id = relation_response.data[0]["user_id"]

        user_response = supabase.table("users") \
            .select("username", "email") \
            .eq("id", user_id) \
            .single() \
            .execute()

        camera_response = supabase.table("ip_cameras") \
            .select("id", "ip_address") \
            .eq("activation_key_id", activation_key_id) \
            .execute()

        return {
            "user_id": user_id,
            "username": user_response.data["username"],
            "email": user_response.data["email"],
            "cameras": camera_response.data or []
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
    #çalıştırırken: uvicorn main:app --host 0.0.0.0 --port 8000 --reload
