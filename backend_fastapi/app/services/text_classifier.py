"""
Text classification service using TF-IDF + SVM for severity and department classification
"""
import pickle
import os
from typing import Tuple, Dict
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.svm import SVC
import nltk
from nltk.corpus import stopwords
from nltk.tokenize import word_tokenize
from nltk.stem import WordNetLemmatizer
import re

# Download NLTK data if not present
try:
    nltk.data.find('tokenizers/punkt')
except LookupError:
    nltk.download('punkt', quiet=True)

try:
    nltk.data.find('corpora/stopwords')
except LookupError:
    nltk.download('stopwords', quiet=True)

try:
    nltk.data.find('corpora/wordnet')
except LookupError:
    nltk.download('wordnet', quiet=True)

MODEL_PATH = os.getenv("TEXT_MODEL_PATH", "ml_training/text_model/text_classifier.pkl")
VECTORIZER_PATH = os.getenv("VECTORIZER_PATH", "ml_training/text_model/tfidf_vectorizer.pkl")


class TextClassifier:
    def __init__(self):
        self.lemmatizer = WordNetLemmatizer()
        self.stop_words = set(stopwords.words('english'))
        self.vectorizer = None
        self.severity_model = None
        self.department_model = None
        self.load_models()
    
    def load_models(self):
        """Load pre-trained models and vectorizer"""
        try:
            if os.path.exists(MODEL_PATH) and os.path.exists(VECTORIZER_PATH):
                with open(VECTORIZER_PATH, 'rb') as f:
                    self.vectorizer = pickle.load(f)
                with open(MODEL_PATH, 'rb') as f:
                    models = pickle.load(f)
                    self.severity_model = models.get('severity')
                    self.department_model = models.get('department')
            else:
                print(f"Warning: Models not found. Using placeholder models.")
                self._create_placeholder_models()
        except Exception as e:
            print(f"Error loading models: {e}. Using placeholder models.")
            self._create_placeholder_models()
    
    def _create_placeholder_models(self):
        """Create placeholder models for development"""
        from sklearn.feature_extraction.text import TfidfVectorizer
        from sklearn.svm import SVC
        
        # Placeholder training data
        sample_texts = [
            "pothole on road", "garbage overflow", "streetlight not working",
            "severe road damage", "critical waste issue", "urgent light failure"
        ]
        
        self.vectorizer = TfidfVectorizer(max_features=1000, ngram_range=(1, 2))
        X = self.vectorizer.fit_transform(sample_texts)
        
        # Placeholder severity model
        severity_labels = [0, 1, 2, 2, 2, 2]  # low, medium, high
        self.severity_model = SVC(kernel='linear', probability=True)
        self.severity_model.fit(X, severity_labels)
        
        # Placeholder department model
        dept_labels = [0, 1, 2, 0, 1, 2]  # road, waste, streetlight
        self.department_model = SVC(kernel='linear', probability=True)
        self.department_model.fit(X, dept_labels)
    
    def preprocess_text(self, text: str) -> str:
        """Preprocess text: lowercase, remove special chars, lemmatize"""
        if not text:
            return ""
        
        # Convert to lowercase
        text = text.lower()
        
        # Remove special characters and digits
        text = re.sub(r'[^a-zA-Z\s]', '', text)
        
        # Tokenize
        tokens = word_tokenize(text)
        
        # Remove stopwords and lemmatize
        tokens = [
            self.lemmatizer.lemmatize(token)
            for token in tokens
            if token not in self.stop_words and len(token) > 2
        ]
        
        return ' '.join(tokens)
    
    def classify_severity(self, text: str) -> Tuple[str, float]:
        """
        Classify text severity
        
        Returns:
            Tuple of (severity_level, confidence)
        """
        try:
            processed_text = self.preprocess_text(text)
            if not processed_text:
                return "medium", 0.5
            
            text_vector = self.vectorizer.transform([processed_text])
            prediction = self.severity_model.predict(text_vector)[0]
            probabilities = self.severity_model.predict_proba(text_vector)[0]
            confidence = float(max(probabilities))
            
            severity_map = {0: "low", 1: "medium", 2: "high", 3: "critical"}
            severity = severity_map.get(prediction, "medium")
            
            return severity, confidence
        except Exception as e:
            print(f"Error in severity classification: {e}")
            return "medium", 0.5
    
    def classify_department(self, text: str, category: str) -> str:
        """
        Classify department based on text and category using a hybrid approach.
        """
        try:
            # 1. Start with Category-based mapping (Fixed source of truth)
            dept_map = {
                "road_damage": "Road Maintenance",
                "waste_overflow": "Sanitation",
                "streetlight_failure": "Electrical"
            }
            category_dept = dept_map.get(category, "General")

            # 2. Try Text-based classification as a "Secondary Vote"
            processed_text = self.preprocess_text(text)
            if not processed_text:
                return category_dept
            
            text_vector = self.vectorizer.transform([processed_text])
            prediction = self.department_model.predict(text_vector)[0]
            
            department_map = {
                0: "Road Maintenance",
                1: "Sanitation",
                2: "Electrical"
            }
            text_dept = department_map.get(prediction, "General")

            # 3. Hybrid Logic: 
            # If text classification matches category, return it.
            # If they conflict, prioritize the category-based routing (Visual Evidence)
            # unless the text is extremely clear (this can be expanded later).
            return category_dept
            
        except Exception as e:
            print(f"Error in department classification: {e}")
            dept_map = {
                "road_damage": "Road Maintenance",
                "waste_overflow": "Sanitation",
                "streetlight_failure": "Electrical"
            }
            return dept_map.get(category, "General")


# Singleton instance
text_classifier = TextClassifier()

