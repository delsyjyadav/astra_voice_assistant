import google.generativeai as genai
import random
from app.config.settings import settings


class GeminiService:
    def __init__(self):

        genai.configure(api_key=settings.GEMINI_API_KEY)


        generation_config = {
            "temperature": 0.7,
            "top_p": 0.95,
            "top_k": 40,
            "max_output_tokens": 150,
        }


        self.model = genai.GenerativeModel(
            model_name="gemini-2.5-flash",

            generation_config=generation_config,
        )

    async def generate_response(self, user_message: str, context: str = "", field_name: str = None) -> str:
        try:
            print(f"Requesting ASTRA Response for: {user_message}")


            full_prompt = f"System: You are ASTRA, a friendly voice assistant. Answer in 1-2 short sentences.\nUser: {user_message}"


            response = self.model.generate_content(full_prompt)

            if response and response.text:
                return response.text.strip()
            else:
                return self._get_fallback_response()

        except Exception as e:
            print(f"Gemini SDK Error: {str(e)}")

            return self._get_fallback_response()

    def _get_fallback_response(self) -> str:
        fallbacks = [
            "I'm sorry, I'm having a bit of trouble connecting right now.",
            "I missed that. Could you please repeat your question?",
            "Technical glitch lag raha hai, please try again."
        ]
        return random.choice(fallbacks)