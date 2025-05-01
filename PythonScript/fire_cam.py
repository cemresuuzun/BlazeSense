import cv2
from ultralytics import YOLO
import time
from config import USER_ID, CAMERA_ID, IP_CAMERA_URL, ACCOUNT_SID, AUTH_TOKEN
from datetime import datetime
import requests
from twilio.rest import Client
import os
from collections import deque
import threading

# === CLIP SAVING CONFIG ===
PRE_SECONDS = 5
POST_SECONDS = 5
FPS = 20
WIDTH, HEIGHT = 640, 480  # Lowered resolution for better speed
VIDEO_DIR = "saved_clips"

if not os.path.exists(VIDEO_DIR):
    os.makedirs(VIDEO_DIR)

frame_buffer = deque(maxlen=PRE_SECONDS * FPS)
post_fire_frames = []
fire_detected = False
fire_frame_count = 0
post_max_frames = POST_SECONDS * FPS

# Twilio client
twilio_client = Client(ACCOUNT_SID, AUTH_TOKEN)

def save_clip(frames, width, height):
    filename = os.path.join(VIDEO_DIR, f"fire_clip_{int(time.time())}.mp4")
    writer = cv2.VideoWriter(filename, cv2.VideoWriter_fourcc(*'XVID'), FPS, (width, height))
    for frame in frames:
        writer.write(frame)
    writer.release()
    print(f"✅ Fire clip saved: {filename}")

def send_whatsapp_message(to_number):
    try:
        message = twilio_client.messages.create(
            body='🔥 Fire Alert! A possible fire was detected by BlazeSense. Please check your app.',
            from_='whatsapp:+14155238886',
            to=f'whatsapp:{to_number}'
        )
        print(f"✅ WhatsApp message sent! SID: {message.sid}")
    except Exception as e:
        print(f"❌ WhatsApp error: {e}")

last_notification_time = 0
notification_delay = 5

def send_fire_notification_via_api(user_id, camera_id, message):
    global last_notification_time
    current_time = time.time()

    if current_time - last_notification_time >= notification_delay:
        payload = {
            "user_id": user_id,
            "camera_id": camera_id,
            "message": message,
            "timestamp": datetime.utcnow().isoformat() + "Z"
        }
        print("📤 Sending fire payload:", payload)
        try:
            res = requests.post("http://localhost:8000/detect/fire", json=payload)
            print("🔥 API yanıtı:", res.status_code)
            print("📦 İçerik:", res.json())
            threading.Thread(target=send_whatsapp_message, args=('+905335117541',)).start()
            last_notification_time = current_time
        except Exception as e:
            print("❌ API error:", e)
    else:
        print("⏳ Notification delay not met.")

# Load model
model = YOLO("Yolo/best.pt")

# Open camera
print(f"📹 Connecting to: {IP_CAMERA_URL}")
cap = cv2.VideoCapture(IP_CAMERA_URL)
time.sleep(2)

if not cap.isOpened():
    print("❌ Could not open camera stream.")
    exit()
else:
    print("✅ Camera stream opened!")

# Frame skipping
frame_skip = 2
frame_counter = 0

try:
    while True:
        success, frame = cap.read()
        if not success or frame is None:
            print("Failed to read frame.")
            continue

        frame_resized = cv2.resize(frame, (WIDTH, HEIGHT))
        frame_buffer.append(frame_resized.copy())

        results = []
        if frame_counter % frame_skip == 0:
            results = model(frame_resized, stream=True, conf=0.5)
        frame_counter += 1

        for result in results:
            if result.boxes is not None:
                for box in result.boxes:
                    x1, y1, x2, y2 = map(int, box.xyxy[0])
                    conf = box.conf[0].item()
                    cls = int(box.cls[0])
                    if cls == 0:
                        label = f"Fire: {conf:.2f}"
                        cv2.rectangle(frame_resized, (x1, y1), (x2, y2), (0, 0, 255), 3)
                        cv2.putText(frame_resized, label, (x1, y1 - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 0, 255), 2)

                        if not fire_detected:
                            print("🚨 Fire detected!")
                            fire_detected = True
                            fire_frame_count = 0
                            post_fire_frames = list(frame_buffer)

                        threading.Thread(target=send_fire_notification_via_api, args=(USER_ID, CAMERA_ID, "🔥 Fire detected!")).start()

        if fire_detected:
            post_fire_frames.append(frame_resized)
            fire_frame_count += 1
            if fire_frame_count >= post_max_frames:
                fire_detected = False
                save_clip(post_fire_frames, WIDTH, HEIGHT)
                post_fire_frames.clear()

        cv2.imshow("BlazeSense Fire Detection", frame_resized)
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break


except KeyboardInterrupt:
    print("🛑 Gracefully shutting down.")

finally:
    cap.release()
    cv2.destroyAllWindows()
