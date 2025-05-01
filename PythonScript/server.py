from flask import Flask, request, jsonify
from flask_cors import CORS  # Import CORS
from fire_cam import send_whatsapp_message

app = Flask(__name__)
CORS(app)  # Allow all origins (you can restrict this later)

@app.route('/send-message', methods=['POST'])
def send_message():
    try:
        # Get JSON data from Flutter
        data = request.get_json()
        phone_number = data.get('phone')

        if not phone_number:
            return jsonify({'status': 'error', 'message': 'Phone number missing!'}), 400

        # Call the function to send WhatsApp message
        send_whatsapp_message(phone_number)

        return jsonify({'status': 'success', 'message': 'WhatsApp message sent!'})
    
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
