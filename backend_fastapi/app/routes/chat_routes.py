from fastapi import APIRouter, HTTPException
from app.models.chat_models import ChatRequest, ChatResponse
from app.services.gemini_service import GeminiService

router = APIRouter()
gemini_service = GeminiService()

@router.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    if not request.user_message or len(request.user_message.strip()) < 2:
        return ChatResponse(
            message="I'm listening, please say something.",
            session_id=request.session_id,
            is_voice_response=True
        )

    try:
        ai_response = await gemini_service.generate_response(
            user_message=request.user_message,
            context=request.context,
            field_name=request.field_name
        )

        return ChatResponse(
            message=ai_response,
            session_id=request.session_id,
            is_voice_response=True
        )

    except Exception as e:
        print(f"Route Error: {str(e)}")
        raise HTTPException(status_code=500, detail="Astra server encountered an error.")

@router.get("/health")
async def health_check():
    return {"status": "healthy", "service": "ASTRA Voice Assistant"}