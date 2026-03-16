# backend_fastapi/app/services/gemini_service.py
import requests
import json
from app.config.settings import settings


class GeminiService:
    def __init__(self):
        self.api_key = settings.GEMINI_API_KEY
        self.model_name = "gemini-1.5-flash"  # Using latest stable model
        self.url = f"https://generativelanguage.googleapis.com/v1/models/{self.model_name}:generateContent?key={self.api_key}"

    async def generate_response(self, user_message: str, context: str = "", field_name: str = None) -> str:
        try:
            print(f"Sending request to Gemini with message: {user_message}")

            prompt = f"""
            You are ASTRA, a friendly and intelligent voice assistant.

            Context from previous conversation: {context}
            Current task/field: {field_name or 'general chat'}
            User message: {user_message}

            Please provide a helpful, friendly, and concise response. Keep it under 3 sentences.
            Be conversational and warm in your tone.
            """

            payload = {
                "contents": [{
                    "parts": [{"text": prompt}]
                }],
                "generationConfig": {
                    "temperature": 0.7,
                    "maxOutputTokens": 150,
                    "topP": 0.8,
                    "topK": 40
                }
            }

            headers = {
                "Content-Type": "application/json"
            }

            response = requests.post(
                self.url,
                json=payload,
                headers=headers,
                timeout=15
            )

            print(f"Gemini Response Status: {response.status_code}")

            if response.status_code != 200:
                print(f"Gemini Error Response: {response.text}")
                return self._get_fallback_response(user_message)

            data = response.json()

            try:
                ai_text = data["candidates"][0]["content"]["parts"][0]["text"]
                print(f"Gemini Response: {ai_text[:100]}...")
                return ai_text.strip()
            except (KeyError, IndexError) as e:
                print(f"Parse error: {e}")
                print(f"Response data: {data}")
                return self._get_fallback_response(user_message)

        except requests.exceptions.Timeout:
            print("Gemini API timeout")
            return self._get_fallback_response(user_message)
        except requests.exceptions.ConnectionError:
            print("Gemini API connection error")
            return "I'm having trouble connecting to the internet. Please check your connection."
        except Exception as e:
            print(f"Gemini Service Error: {e}")
            return self._get_fallback_response(user_message)

    def _get_fallback_response(self, user_message: str) -> str:
        """Provide fallback responses when API fails"""
        fallbacks = [
            "I'm here to help! What would you like to know?",
            "That's interesting! Tell me more about it.",
            "I understand. How can I assist you further?",
            "Thanks for sharing that. Is there anything specific you'd like to ask?",
            "I'm listening. Please go ahead with your question."
        ]
        import random
        return random.choice(fallbacks)