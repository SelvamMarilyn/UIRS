import os
import argparse
import tensorflow as tf
from tensorflow.keras import layers, models
from tensorflow.keras.applications import MobileNetV2
from tensorflow.keras.preprocessing.image import ImageDataGenerator
import numpy as np

# Default settings matching the backend service
IMG_SIZE = (224, 224)
BATCH_SIZE = 32
MODEL_NAME = "mobilenetv2_issue_classifier.keras"

def create_model(num_classes=3):
    """
    Creates a MobileNetV2-based model with transfer learning.
    Uses ImageNet weights to achieve high accuracy quickly.
    """
    base_model = MobileNetV2(
        input_shape=(*IMG_SIZE, 3),
        include_top=False,
        weights='imagenet'
    )
    # Start with base model frozen for initial training
    base_model.trainable = False 

    model = models.Sequential([
        base_model,
        layers.GlobalAveragePooling2D(),
        layers.Dense(256, activation='relu'),
        layers.Dropout(0.3),
        layers.Dense(num_classes, activation='softmax')
    ])

    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=0.001),
        loss='categorical_crossentropy',
        metrics=['accuracy']
    )
    
    return model, base_model

def train_dummy(target_path):
    """Generates a dummy model for verification when real data isn't available yet."""
    print("Generating dummy model for verification...")
    # Use a simpler model for dummy to avoid issues
    model = models.Sequential([
        layers.Conv2D(32, (3, 3), activation='relu', input_shape=(*IMG_SIZE, 3)),
        layers.GlobalAveragePooling2D(),
        layers.Dense(3, activation='softmax')
    ])
    model.compile(optimizer='adam', loss='categorical_crossentropy', metrics=['accuracy'])
    
    # Create dummy data
    X_train = np.random.rand(1, *IMG_SIZE, 3).astype(np.float32)
    y_train = np.eye(3)[np.random.choice(3, 1)]
    
    model.fit(X_train, y_train, epochs=1, verbose=1)
    
    if os.path.exists(target_path):
        os.remove(target_path)
    
    os.makedirs(os.path.dirname(target_path), exist_ok=True)
    model.save(target_path)
    print(f"Dummy model saved to {target_path}")

def train_real(data_dir, target_path, epochs=10):
    """
    Trains the model on real data using transfer learning and fine-tuning.
    """
    print(f"Training on real data from {data_dir}...")
    
    # Advanced Data augmentation for high accuracy
    train_datagen = ImageDataGenerator(
        rescale=1./255,
        rotation_range=30,
        width_shift_range=0.2,
        height_shift_range=0.2,
        shear_range=0.2,
        zoom_range=0.2,
        horizontal_flip=True,
        fill_mode='nearest',
        validation_split=0.2
    )

    train_generator = train_datagen.flow_from_directory(
        data_dir,
        target_size=IMG_SIZE,
        batch_size=BATCH_SIZE,
        class_mode='categorical',
        subset='training'
    )

    validation_generator = train_datagen.flow_from_directory(
        data_dir,
        target_size=IMG_SIZE,
        batch_size=BATCH_SIZE,
        class_mode='categorical',
        subset='validation'
    )

    model, base_model = create_model(num_classes=train_generator.num_classes)
    
    # Phase 1: Train top layers
    print("Phase 1: Training top layers...")
    model.fit(
        train_generator,
        epochs=epochs // 2,
        validation_data=validation_generator
    )
    
    # Save checkpoint after Phase 1
    model.save(target_path)
    print(f"Checkpoint saved to {target_path}")

    # Phase 2: Fine-tuning
    print("Phase 2: Fine-tuning base model...")
    base_model.trainable = True
    # Recompile with very low learning rate
    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=0.0001),
        loss='categorical_crossentropy',
        metrics=['accuracy']
    )
    
    model.fit(
        train_generator,
        epochs=epochs,
        validation_data=validation_generator
    )

    os.makedirs(os.path.dirname(target_path), exist_ok=True)
    model.save(target_path)
    print(f"Model saved to {target_path}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Train Urban AI Image Classifier")
    parser.add_argument("--data_dir", type=str, help="Path to dataset directory")
    parser.add_argument("--output", type=str, default=MODEL_NAME, help="Path to save model")
    parser.add_argument("--epochs", type=int, default=10, help="Number of epochs")
    parser.add_argument("--dummy", action="store_true", help="Generate dummy model for testing")
    
    args = parser.parse_args()
    
    output_path = os.path.join(os.path.dirname(__file__), args.output)
    
    if args.dummy:
        train_dummy(output_path)
    elif args.data_dir:
        train_real(args.data_dir, output_path, args.epochs)
    else:
        print("Please provide --data_dir or use --dummy")
