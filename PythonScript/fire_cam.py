# Database ilişkileri API üzerinden kurulmamıştır!!! APIendpointler belirlenerek api ile veri alışverişi yapılacaktır 
# Bu kod demonstration için kullanılıp API endpoiitlerle bağlandıktan sonra son halini alabilecektir. Needs update
# Belirtilen importlar yolo, database veconfig dosyasıdır.
# SUPABASE_URL, SUPABASE_KEY, USER_ID, CAMERA_ID, IP_CAMERA_URL confidential bilgileri githuba gönderilmeyecek bir config dosyasında saklanmaktadır kod bu şekilde çalışmayacaktır

from supabase import create_client, Client
import cv2
from ultralytics import YOLO
import time
import asyncio
from config import SUPABASE_URL, SUPABASE_KEY, USER_ID, CAMERA_ID, IP_CAMERA_URL  # Confidential bilgileri içe aktar 

# Database bağlantısı için oluşturdum
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# Son gönderilen bildirim zamanını takip etmek için değişken
last_notification_time = 0  # Başlangıçta sıfır 
notification_delay = 5  # Bildirimler arasında 5 saniye bekleme süresi

# Supabase Realtime Bildirim Gönderme Fonksiyonu
async def send_fire_notification(user_id, camera_id):
    global last_notification_time
    current_time = time.time()
    
    if current_time - last_notification_time >= notification_delay:
        data = {
            "user_id": user_id,
            "camera_id": camera_id,
            "message": "Review this 3 minutes. Is it a real fire?",
            "created_at": time.strftime('%Y-%m-%d %H:%M:%S')  # Timestamp ekleyelim
        }
        response = await supabase.table("notifications").insert(data).execute()
        print("Notification sent to Supabase:", response)
        last_notification_time = current_time
    else:
        print("⏳ Skipping notification due to delay...")

# YOLO Modelini Yükle
model = YOLO("runs/detect/train2/weights/best.pt")  

# IP Kamera Bağlantısını Aç
cap = cv2.VideoCapture(IP_CAMERA_URL)

if not cap.isOpened():
    print("Error: Could not open IP camera stream.")
    exit()

# Sürekli Kamera Görüntüsünü İşle
while cap.isOpened():
    success, frame = cap.read()
    if not success:
        print("Failed to capture frame from IP camera")
        break
    
    # YOLO Modeli ile Algılama Yap
    results = model.predict(frame, conf=0.5)  
    
    # Çerçeveleri Çiz ve Fire Detection Kontrolü Yap
    for result in results:
        for box in result.boxes:
            x1, y1, x2, y2 = map(int, box.xyxy[0])  
            conf = box.conf[0].item()  
            cls = int(box.cls[0])  

            if cls == 0:  # Eğer Algılanan Obje Yangınsa
                label = f"🔥 Fire: {conf:.2f}"
                cv2.rectangle(frame, (x1, y1), (x2, y2), (0, 0, 255), 3)  
                cv2.putText(frame, label, (x1, y1 - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 0, 255), 2)
                
                # Asenkron Bildirim Gönder
                asyncio.run(send_fire_notification(USER_ID, CAMERA_ID))
                #Burada asenkron kullanılmasının sebebi senkron(blocking) olsaydı execute olana kadar kod durdurulurdu
                #asenkron olduğu için real time fire detection bu delay zamanında da aynı şekilde devam ediyor

    # Görüntüyü Ekranda Göster
    cv2.imshow("🔥 Fire Detection", frame)

    # 'q' Tuşuna Basınca Çıkış Yap
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

# Kaynakları Serbest Bırak
cap.release()
cv2.destroyAllWindows()
