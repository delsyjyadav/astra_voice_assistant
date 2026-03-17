from pydantic import BaseModel
from typing import Optional

class ChatRequest(BaseModel):
    user_message: str
    session_id: str

    context: Optional[str] = ""
    field_name: Optional[str] = None
    voice_input: Optional[bool] = False

class ChatResponse(BaseModel):
    message: str
    session_id: str
    is_voice_response: Optional[bool] = False