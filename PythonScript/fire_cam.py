# Database ilişkileri API üzerinden kurulmamıştır!!! APIendpointler belirlenerek api ile veri alışverişi yapılacaktır 
# Bu kod demonstration için kullanılıp API endpoiitlerle bağlandıktan sonra son halini alabilecektir. Needs update
# Belirtilen importlar yolo, database veconfig dosyasıdır.
# SUPABASE_URL, SUPABASE_KEY, USER_ID, CAMERA_ID, IP_CAMERA_URL confidential bilgileri githuba gönderilmeyecek bir config dosyasında saklanmaktadır kod bu şekilde çalışmayacaktır

from supabase import create_client, Client
import cv2
from ultralytics import YOLO
import time
from config import SUPABASE_URL, SUPABASE_KEY, USER_ID, CAMERA_ID, IP_CAMERA_URL  # Credential import
from datetime import datetime

# Database bağlantısı için oluşturdum
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# Son gönderilen bildirim zamanını takip etmek için değişken
last_notification_time = 0  # Başlangıçta sıfır 
notification_delay = 5  # Bildirimler arasında 5 saniye bekleme süresi

def send_fire_notification(user_id, camera_id):
    global last_notification_time
    current_time = time.time()

    if current_time - last_notification_time >= notification_delay:
        data = {
            "user_id": user_id,
            "camera_id": camera_id,
            "message": "Review this 3 minutes. Is it a real fire?",
            "is_seen": False,
            "timestamp": datetime.utcnow().isoformat()
        }

        response = supabase.table("notifications").insert(data).execute()
        print("Notification sent to Supabase:", response)
        last_notification_time = current_time
        return response
    else:
        print("Skipping notification, waiting for 5 seconds delay to pass...")
        return None

# Load trained YOLOv8 model 
model = YOLO("runs/detect/train2/weights/best.pt")  

# Open IP camera stream
cap = cv2.VideoCapture(IP_CAMERA_URL)

if not cap.isOpened():
    print("Error: Could not open IP camera stream.")
    exit()

while cap.isOpened():
    success, frame = cap.read()
    if not success:
        print("Failed to capture frame from IP camera")
        break
    
    # Perform YOLOv8 inference on the frame
    results = model.predict(frame, conf=0.5)  # confidence threshold can be adjusted 0.5 yazan kısım
    
    # Draw detections on the frame
    for result in results:
        for box in result.boxes:
            x1, y1, x2, y2 = map(int, box.xyxy[0])  # Get bounding box coordinates
            conf = box.conf[0].item()  # Confidence score of detectsion
            cls = int(box.cls[0])  # Class index
            
            # Check if detected object is 'fire' fire tek class olduğu için 0 olacak
            if cls == 0:
                label = f"Fire: {conf:.2f}"
                cv2.rectangle(frame, (x1, y1), (x2, y2), (0, 0, 255), 3)  # Red box for fire
                cv2.putText(frame, label, (x1, y1 - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 0, 255), 2)
                
                # Supabase'e yangın algılandığı için bildirim gönder (5 saniyelik gecikme var)
                send_fire_notification(USER_ID, CAMERA_ID)

    # Display the frame with detections
    cv2.imshow("Fire Detection", frame)

    # Exit on pressing 'q'
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

# Release the IP camera stream and close all windows yapmayı sakın unutma
cap.release()
cv2.destroyAllWindows()
