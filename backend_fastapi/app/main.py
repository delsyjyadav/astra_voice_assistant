from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routes import chat_routes


app = FastAPI(title="ASTRA Voice Assistant API")

app.add_middleware(

    CORSMiddleware,

    allow_origins=["*"],

    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(chat_routes.router, prefix="/api/v1", tags=["chat"])

@app.get("/")
async def root():
    return {"message": "ASTRA Backend is Online"}

if __name__ == "__main__":
    import uvicorn

    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)