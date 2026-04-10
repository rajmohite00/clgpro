# ════════════════════════════════════════════════════════════════
# api.py  — FastAPI wrapper for the free Voice RAG pipeline
# Exposes REST endpoints so the Flutter chatbot can consume it.
# ════════════════════════════════════════════════════════════════

import os
import base64
from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from dotenv import load_dotenv

from rag_engine import RAGEngine
from voice_service import text_to_speech

load_dotenv()

print("🚀 Starting Voice RAG API...")

app = FastAPI(title="Voice RAG API")
print("✅ FastAPI app initialized")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Global engine instance
_rag_engine = None

def get_rag():
    global _rag_engine
    if not _rag_engine:
        q_url = os.getenv("QDRANT_URL")
        q_key = os.getenv("QDRANT_API_KEY")
        hf_token = os.getenv("HF_TOKEN")
        if not q_url or not hf_token:
            raise HTTPException(status_code=500, detail="Server missing HF_TOKEN or QDRANT config")
        
        _rag_engine = RAGEngine(
            qdrant_url=q_url,
            qdrant_api_key=q_key,
            hf_token=hf_token
        )
        _rag_engine.ensure_collection()
    return _rag_engine

class QueryRequest(BaseModel):
    text: str

@app.get("/")
async def root():
    return {"message": "Voice RAG API is running! Use the Flutter app to chat or go to /docs for the API swagger."}

@app.post("/api/index_pdf")
async def index_pdf(file: UploadFile = File(...)):
    """Uploads a PDF, chunks it, and indexes it into Qdrant."""
    rag = get_rag()
    content = await file.read()
    try:
        n_chunks = rag.index_pdf(content, file.filename or "uploaded.pdf")
        return {"status": "success", "filename": file.filename, "chunks": n_chunks}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/ask")
async def ask_question(req: QueryRequest):
    """
    RAG Query -> Semantic search -> HuggingFace Answer -> gTTS Audio
    Returns answer text, sources, and base64 encoded audio (MP3).
    """
    rag = get_rag()
    query = req.text.strip()
    if not query:
        raise HTTPException(status_code=400, detail="Empty query")

    # 1. RAG pipeline
    answer, chunks = rag.ask(query)

    # 2. TTS
    audio_b64 = ""
    try:
        audio_bytes = text_to_speech(answer, lang="en")
        audio_b64 = base64.b64encode(audio_bytes).decode("utf-8")
    except Exception as e:
        print(f"TTS error: {e}")

    return {
        "answer": answer,
        "sources": [c["source"] for c in chunks],
        "audio_base64": audio_b64
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
