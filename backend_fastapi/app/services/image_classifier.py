"""
Image classification service using MobileNetV2 for issue category detection
"""
import tensorflow as tf
import numpy as np
from PIL import Image
import io
import os
from typing import Tuple, Dict

# Model will be loaded from saved path
MODEL_PATH = os.getenv("IMAGE_MODEL_PATH", "ml_training/image_model/mobilenetv2_issue_classifier.keras")

class ImageClassifier:
    def __init__(self):
        self.model = None
        self.load_model()
        self.category_map = {
            0: "road_damage",
            1: "streetlight_failure",
            2: "waste_overflow"
        }
    
    def load_model(self):
        """Load the pre-trained MobileNetV2 model"""
        try:
            if os.path.exists(MODEL_PATH):
                self.model = tf.keras.models.load_model(MODEL_PATH)
            else:
                # Initialize a placeholder model structure for development
                # In production, this should be a trained model
                print(f"Warning: Model not found at {MODEL_PATH}. Using placeholder.")
                self.model = self._create_placeholder_model()
        except Exception as e:
            print(f"Error loading model: {e}. Using placeholder.")
            self.model = self._create_placeholder_model()
    
    def _create_placeholder_model(self):
        """Create a placeholder model for development/testing without downloading weights"""
        try:
            # Try to use MobileNetV2 without weights (faster, no download)
            base_model = tf.keras.applications.MobileNetV2(
                input_shape=(224, 224, 3),
                include_top=False,
                weights=None  # No weights download - random initialization
            )
            base_model.trainable = False
        except Exception as e:
            print(f"Warning: Could not create MobileNetV2 base. Using simple CNN: {e}")
            # Fallback to simple CNN if MobileNetV2 fails
            base_model = tf.keras.Sequential([
                tf.keras.layers.Conv2D(32, (3, 3), activation='relu', input_shape=(224, 224, 3)),
                tf.keras.layers.MaxPooling2D(2, 2),
                tf.keras.layers.Conv2D(64, (3, 3), activation='relu'),
                tf.keras.layers.MaxPooling2D(2, 2),
                tf.keras.layers.GlobalAveragePooling2D()
            ])
        
        model = tf.keras.Sequential([
            base_model,
            tf.keras.layers.GlobalAveragePooling2D(),
            tf.keras.layers.Dense(128, activation='relu'),
            tf.keras.layers.Dropout(0.2),
            tf.keras.layers.Dense(3, activation='softmax')  # 3 categories
        ])
        
        model.compile(
            optimizer='adam',
            loss='categorical_crossentropy',
            metrics=['accuracy']
        )
        
        return model
    
    def preprocess_image(self, image_bytes: bytes) -> np.ndarray:
        """Preprocess image for model input"""
        try:
            image = Image.open(io.BytesIO(image_bytes))
            image = image.convert('RGB')
            image = image.resize((224, 224))
            image_array = np.array(image) / 255.0
            image_array = np.expand_dims(image_array, axis=0)
            return image_array
        except Exception as e:
            raise ValueError(f"Error preprocessing image: {e}")
    
    def classify(self, image_bytes: bytes) -> Tuple[str, float]:
        """
        Classify image and return category and confidence
        
        Returns:
            Tuple of (category, confidence_score)
        """
        try:
            processed_image = self.preprocess_image(image_bytes)
            predictions = self.model.predict(processed_image, verbose=0)
            
            predicted_class = np.argmax(predictions[0])
            confidence = float(predictions[0][predicted_class])
            category = self.category_map.get(predicted_class, "road_damage")
            
            return category, confidence
        except Exception as e:
            print(f"Error in classification: {e}")
            return "road_damage", 0.5  # Default fallback


# Singleton instance
image_classifier = ImageClassifier()

