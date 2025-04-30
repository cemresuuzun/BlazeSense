# Database ilişkileri API üzerinden kurulmamıştır!!! APIendpointler belirlenerek api ile veri alışverişi yapılacaktır
# Bu kod demonstration için kullanılıp API endpointlerle bağlandıktan sonra son halini alabilecektir. Needs update
# Belirtilen importlar yolo, database ve config dosyasıdır.
# SUPABASE_URL, SUPABASE_KEY, USER_ID, CAMERA_ID, IP_CAMERA_URL confidential bilgileri githuba gönderilmeyecek bir config dosyasında saklanmaktadır kod bu şekilde çalışmayacaktır

import cv2
from ultralytics import YOLO
import time
from config import USER_ID, CAMERA_ID, IP_CAMERA_URL,IP_CAMERA_URL1,ACCOUNT_SID,AUTH_TOKEN  # Updated: Supabase bağlantısı artık kullanılmadığı için gereksiz olanlar çıkarıldı
from datetime import datetime
import requests
from twilio.rest import Client  # Twilio import

# Twilio credentials
twilio_client = Client(ACCOUNT_SID, AUTH_TOKEN)

# WhatsApp message sender
def send_whatsapp_message(to_number):
    """Function to send WhatsApp message using Twilio."""
    try:
        message = twilio_client.messages.create(
            body='🔥 Fire Alert! A possible fire was detected by BlazeSense. Please check your app.',
            from_='whatsapp:+14155238886',  # Twilio sandbox number
            to=f'whatsapp:{to_number}'
        )
        print(f"✅ WhatsApp message sent successfully! Message SID: {message.sid}")
    except Exception as e:
        print(f"❌ Failed to send WhatsApp message: {e}")

# Son gönderilen bildirim zamanını takip etmek için değişken
last_notification_time = 0  # Başlangıçta sıfır
notification_delay = 5  # Bildirimler arasında 5 saniye bekleme süresi

# API Üzerinden Bildirim Gönderimi
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

            # API başarılı ise WhatsApp bildirimi de gönder
            send_whatsapp_message('+905335117541')  # Replace with your WhatsApp number

            last_notification_time = current_time
        except requests.exceptions.RequestException as e:
            print("❌ API'ye bağlanılamadı:", e)
        except Exception as e:
            print("❌ Diğer hata:", e)
    else:
        print("⏳ 5 saniyelik bekleme süresi dolmadı.")

# Load trained YOLOv8 model
model = YOLO(r"C:\BlazeSense\BlazeSense\Yolo\best.pt")

# Open IP camera stream (RTSP protokolü)
cap = cv2.VideoCapture(IP_CAMERA_URL1)

# Kamera açılamazsa hata mesajı ver
if not cap.isOpened():
    print("Error: Could not open IP camera stream.")
    exit()

# Sonsuz döngüyle kamerayı ve inference'ı çalıştır
try:
    while True:
        success, frame = cap.read()
        if not success or frame is None:
            print("Failed to capture frame from IP camera")
            continue

        # Perform YOLOv8 inference on the frame
        results = model.predict(frame, conf=0.5)  # confidence threshold can be adjusted

        # Draw detections on the frame
        for result in results:
            for box in result.boxes:
                x1, y1, x2, y2 = map(int, box.xyxy[0])  # Get bounding box coordinates
                conf = box.conf[0].item()              # Confidence score of detection
                cls = int(box.cls[0])                  # Class index

                # Check if detected object is 'fire' (fire tek class olduğu için 0 olacak)
                if cls == 0:
                    label = f"Fire: {conf:.2f}"
                    cv2.rectangle(frame, (x1, y1), (x2, y2), (0, 0, 255), 3)  # Red box for fire
                    cv2.putText(frame, label, (x1, y1 - 10), cv2.FONT_HERSHEY_SIMPLEX,
                                0.5, (0, 0, 255), 2)

                    # API üzerinden yangın bildirimi gönderimi (5 saniyelik gecikme var)
                    send_fire_notification_via_api(USER_ID, CAMERA_ID, "🔥 Fire detected by YOLO and sent by API!")

        # Display the frame with the detection results
        frame_resized = cv2.resize(frame, (960, 540))  
        cv2.imshow("Fire Detection Camera Feed", frame_resized)

        # Wait for 1 ms for key press; if the user presses 'q', stop the video feed
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

        time.sleep(0.05)  # CPU yükünü azaltmak için kısa bir gecikme

except KeyboardInterrupt:
    print("🛑 Gracefully stopping...")

finally:
    cap.release()
    cv2.destroyAllWindows()
