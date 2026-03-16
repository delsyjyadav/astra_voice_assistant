from fastapi import APIRouter, HTTPException
from app.models.chat_models import ChatRequest, ChatResponse
from app.services.gemini_service import GeminiService

router = APIRouter()
gemini_service = GeminiService()

@router.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
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
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/health")
async def health_check():
    return {"status": "healthy", "service": "ASTRA Voice Assistant"}