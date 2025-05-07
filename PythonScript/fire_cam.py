
# Database ilişkileri API üzerinden kurulmamıştır!!! APIendpointler belirlenerek api ile veri alışverişi yapılacaktır
# Bu kod demonstration için kullanılıp API endpointlerle bağlandıktan sonra son halini alabilecektir. Needs update
# Belirtilen importlar yolo, database ve config dosyasıdır.
# SUPABASE_URL, SUPABASE_KEY, USER_ID, CAMERA_ID, IP_CAMERA_URL confidential bilgileri githuba gönderilmeyecek bir config dosyasında saklanmaktadır kod bu şekilde çalışmayacaktır
import cv2
from ultralytics import YOLO
import time
from datetime import datetime
import requests
from twilio.rest import Client
import os
from collections import deque
import threading
from record import trigger_save_clip_and_get_url  #  S3 uploader 

# === SETTINGS ===
API_BASE_URL = "http://localhost:8000"
PRE_SECONDS = 5
POST_SECONDS = 5
FPS = 20
WIDTH, HEIGHT = 640, 480
frame_skip = 2
notification_delay = 5
whatsapp_number = '+905335117541'  # Optional

# === LOAD MODEL ===
model = YOLO("Yolo/new_best.pt")

# === BUFFERS ===
frame_buffer = deque(maxlen=PRE_SECONDS * FPS)
post_fire_frames = []
fire_detected = False
fire_frame_count = 0
post_max_frames = POST_SECONDS * FPS
last_notification_time = 0

# === TWILIO SETUP ===
ACCOUNT_SID = os.getenv("ACCOUNT_SID")
AUTH_TOKEN = os.getenv("AUTH_TOKEN")
twilio_client = Client(ACCOUNT_SID, AUTH_TOKEN)

# === API REQUEST: Get camera info ===
def get_camera_info():
    url = f"{API_BASE_URL}/get-latest-activation"
    response = requests.get(url)
    if response.status_code != 200:
        raise Exception(f"Camera info fetch failed: {response.text}")
    return response.json()

# === WHATSAPP NOTIFICATION ===
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

# === FIRE NOTIFICATION TO API + WhatsApp ===
def send_fire_notification_via_api(activation_key_id, camera_id, message):
    global last_notification_time
    current_time = time.time()

    if current_time - last_notification_time >= notification_delay:
        payload = {
            "activation_key_id": activation_key_id,
            "camera_id": camera_id,
            "message": message,
            "timestamp": datetime.utcnow().isoformat() + "Z"
        }
        print("📤 Sending fire payload:", payload)
        try:
            res = requests.post(f"{API_BASE_URL}/detect/fire", json=payload)
            res_data = res.json()
            print("🔥 API yanıtı:", res.status_code)
            print("📦 İçerik:", res_data)
            threading.Thread(target=send_whatsapp_message, args=(whatsapp_number,)).start()
            last_notification_time = current_time
            return res_data.get("uuid")  # Needed for video update
        except Exception as e:
            print("❌ API error:", e)
    else:
        print("⏳ Notification delay not met.")
    return None

# === UPDATE VIDEO URL ===
def update_video_url(notification_id, video_url):
    try:
        requests.post(f"{API_BASE_URL}/update-video-url", json={
            "id": notification_id,
            "video_url": video_url
        })
        print(f"🔗 Updated notification {notification_id} with video URL.")
    except Exception as e:
        print("❌ Failed to update video URL:", e)

# === MAIN LOOP ===
try:
    while True:
        try:
            info = get_camera_info()
            break
        except Exception as e:
            print(f"❌ Error: {e}")
            print("🕐 Waiting for activation key to be set from Flutter...")
            time.sleep(5)

    activation_key_id = info["activation_key_id"]
    cameras = info["cameras"]

    if not cameras:
        print("❌ No cameras found for this activation key.")
        exit()

    camera_id = cameras[0]["id"]
    ip_address = cameras[0]["ip_address"]

    print(f"📹 Connecting to: {ip_address}")
    cap = cv2.VideoCapture(ip_address)
    time.sleep(2)

    if not cap.isOpened():
        print("❌ Could not open camera stream.")
        exit()
    else:
        print("✅ Camera stream opened!")

    frame_counter = 0

    while True:
        success, frame = cap.read()
        if not success or frame is None:
            print("❌ Failed to read frame.")
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

                        def full_notify_and_upload():
                            notif_id = send_fire_notification_via_api(activation_key_id, camera_id, "🔥 Fire detected!")
                            if notif_id:
                                video_url = trigger_save_clip_and_get_url()
                                if video_url:
                                    update_video_url(notif_id, video_url)

                        threading.Thread(target=full_notify_and_upload).start()

        if fire_detected:
            post_fire_frames.append(frame_resized)
            fire_frame_count += 1
            if fire_frame_count >= post_max_frames:
                fire_detected = False
                post_fire_frames.clear()

        cv2.imshow("BlazeSense Fire Detection", frame_resized)
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

except KeyboardInterrupt:
    print("🛑 Gracefully shutting down.")
except Exception as e:
    print(f"❌ General error: {e}")
finally:
    cap.release()
    cv2.destroyAllWindows()
