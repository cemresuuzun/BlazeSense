import coremltools as ct
import tensorflow as tf

# Load the CoreML model
model = ct.models.MLModel('YOLOv3Tiny.mlmodel')

# Convert to TFLite
converter = tf.lite.TFLiteConverter.from_coreml_model(model)
tflite_model = converter.convert()

# Save the TFLite model
with open('assets/models/yolov3-tiny.tflite', 'wb') as f:
    f.write(tflite_model) 