# 🎙️ Voice-Enabled RAG Chatbot

A fully cloud-based, **voice-enabled RAG (Retrieval-Augmented Generation) chatbot** that runs entirely on **free-tier services** — no local LLMs, no paid APIs required.

## ✨ Features

| Feature | Technology | Cost |
|---|---|---|
| **LLM Answers** | HuggingFace Inference API (Mistral-7B) | Free |
| **Speech-to-Text** | Google Web Speech API | Free |
| **STT Fallback** | HuggingFace Whisper | Free |
| **Text-to-Speech** | gTTS (Google TTS) | Free |
| **Vector Database** | Qdrant Cloud | Free (1 GB) |
| **Embeddings** | sentence-transformers MiniLM | Free |

## 🚀 Quick Start (Local)

```bash
# 1. Clone/navigate to this folder
cd voice_rag_openaisdk

# 2. Install dependencies
pip install -r requirements.txt

# 3. Set up environment
cp .env.example .env
# Edit .env with your HuggingFace token + Qdrant credentials

# 4. Run
streamlit run app.py
```

## 🌐 Free API Keys You Need

### 1. HuggingFace Token (Free)
- Go to [huggingface.co/settings/tokens](https://huggingface.co/settings/tokens)
- Create a **Read** token (free account)
- Enables: Mistral-7B LLM + Whisper STT

### 2. Qdrant Cloud (Free 1 GB)
- Go to [cloud.qdrant.io](https://cloud.qdrant.io)
- Create a free cluster
- Copy the **Cluster URL** and **API Key**

## ☁️ Deploy to Render (Free)

1. Push this folder to a GitHub repo
2. Go to [render.com](https://render.com) → New Web Service
3. Connect your repo
4. **Build Command:** `pip install -r requirements.txt`
5. **Start Command:** `streamlit run app.py --server.port=$PORT --server.address=0.0.0.0 --server.headless=true`
6. Add **Environment Variables:** `HF_TOKEN`, `QDRANT_URL`, `QDRANT_API_KEY`

## ☁️ Deploy to HuggingFace Spaces (Free)

1. Create a new **Streamlit** Space at [huggingface.co/spaces](https://huggingface.co/spaces)
2. Upload all files
3. Add Secrets: `HF_TOKEN`, `QDRANT_URL`, `QDRANT_API_KEY`

## 🏗️ Architecture

```
User (text/audio)
       │
       ▼
 Streamlit UI
       │
   ┌───┴──────────────────┐
   │                      │
   ▼                      ▼
Voice Input          Text Input
(WAV upload)         (Type query)
   │                      │
   ▼                      │
Google STT / HF Whisper   │
   │                      │
   └──────────┬───────────┘
              │
              ▼
    sentence-transformers
       (embed query)
              │
              ▼
       Qdrant Cloud
    (semantic search)
              │
              ▼
    Top-K relevant chunks
              │
              ▼
  HuggingFace Mistral-7B
    (generate answer)
              │
              ▼
           gTTS
    (text → speech MP3)
              │
              ▼
   Text + Audio Response
```

## 📁 Project Structure

```
voice_rag_openaisdk/
├── app.py              # Main Streamlit application
├── rag_engine.py       # PDF → chunks → embed → Qdrant → LLM pipeline
├── voice_service.py    # STT (Google/Whisper) + TTS (gTTS)
├── requirements.txt    # Python dependencies
├── Procfile            # Render/Railway deployment
├── .streamlit/
│   └── config.toml     # Streamlit dark theme config
├── .env.example        # Environment variable template
└── README.md           # This file
```

## 💡 Notes

- **HuggingFace free tier**: Model cold start may take ~20s on first request. Retry once if this happens.
- **Google Web Speech**: Works without any key; limited to ~60 requests/hour per IP.
- **Qdrant free tier**: 1 GB storage, enough for hundreds of PDFs.
- **gTTS**: Uses Google's TTS endpoint, no key needed, excellent quality.
