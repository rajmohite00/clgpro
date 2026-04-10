# ════════════════════════════════════════════════════════════════
# app.py — Voice-Enabled RAG Chatbot (Streamlit)
#
# Free Stack:
#   LLM      → HuggingFace Inference API (Mistral-7B, free tier)
#   STT      → Google Web Speech via SpeechRecognition (free)
#   STT alt  → HuggingFace Whisper (free with HF token)
#   TTS      → gTTS / Google TTS (free, no key)
#   Vectors  → Qdrant Cloud (free tier, 1GB)
#   Embeds   → sentence-transformers all-MiniLM-L6-v2 (free local)
#
# Deployable on: Render · Railway · HuggingFace Spaces
# ════════════════════════════════════════════════════════════════

import streamlit as st
import os
import time
import base64
import io
import logging
from datetime import datetime

from dotenv import load_dotenv

from rag_engine import RAGEngine
from voice_service import text_to_speech, speech_to_text_from_bytes, whisper_stt_hf

# ── setup ─────────────────────────────────────────────────────
load_dotenv()
logging.basicConfig(level=logging.INFO)

st.set_page_config(
    page_title="🎙️ Voice RAG Chatbot",
    page_icon="🎙️",
    layout="wide",
    initial_sidebar_state="expanded",
)

# ── custom CSS ────────────────────────────────────────────────
st.markdown("""
<style>
    /* Global font */
    @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap');
    html, body, [class*="css"] { font-family: 'Inter', sans-serif; }

    /* Main background */
    .stApp { background: #0f172a; }

    /* Sidebar */
    [data-testid="stSidebar"] {
        background: #1e293b !important;
        border-right: 1px solid #334155;
    }

    /* Section headers */
    .section-header {
        font-size: 11px;
        font-weight: 700;
        letter-spacing: 1.2px;
        color: #64748b;
        text-transform: uppercase;
        margin: 18px 0 8px 0;
    }

    /* Chat container */
    .chat-container {
        background: #1e293b;
        border-radius: 16px;
        padding: 20px;
        min-height: 420px;
        max-height: 520px;
        overflow-y: auto;
        border: 1px solid #334155;
        margin-bottom: 16px;
    }

    /* Message bubbles */
    .msg-user {
        background: linear-gradient(135deg, #3b82f6, #2563eb);
        color: white;
        padding: 12px 16px;
        border-radius: 18px 18px 4px 18px;
        margin: 8px 0 8px 80px;
        font-size: 14px;
        line-height: 1.5;
        box-shadow: 0 4px 12px rgba(59,130,246,0.3);
    }
    .msg-bot {
        background: #0f172a;
        color: #e2e8f0;
        padding: 12px 16px;
        border-radius: 18px 18px 18px 4px;
        margin: 8px 80px 8px 0;
        font-size: 14px;
        line-height: 1.5;
        border: 1px solid #334155;
    }
    .msg-label {
        font-size: 10px;
        font-weight: 700;
        letter-spacing: 0.5px;
        margin-bottom: 4px;
        opacity: 0.6;
    }

    /* Source chips */
    .source-chip {
        display: inline-block;
        background: rgba(99,102,241,0.15);
        color: #818cf8;
        border: 1px solid rgba(99,102,241,0.35);
        border-radius: 20px;
        padding: 3px 10px;
        font-size: 11px;
        font-weight: 600;
        margin: 3px 2px;
    }

    /* Status badge */
    .badge-green { color: #10b981; font-weight: 700; }
    .badge-yellow { color: #f59e0b; font-weight: 700; }
    .badge-red { color: #ef4444; font-weight: 700; }

    /* Audio player */
    audio { width: 100%; border-radius: 8px; margin-top: 8px; }

    /* Gradient title */
    .title-gradient {
        background: linear-gradient(135deg, #6366f1, #3b82f6, #0ea5e9);
        -webkit-background-clip: text;
        -webkit-text-fill-color: transparent;
        font-size: 32px;
        font-weight: 800;
    }
    .subtitle { color: #64748b; font-size: 14px; margin-top: -8px; }

    /* Hide default Streamlit elements */
    #MainMenu, footer { visibility: hidden; }
    .stDeployButton { display: none; }

    /* Button overrides */
    .stButton>button {
        border-radius: 10px !important;
        font-weight: 600 !important;
    }
</style>
""", unsafe_allow_html=True)


# ════════════════════════════════════════════════════════════════
# SESSION STATE
# ════════════════════════════════════════════════════════════════
def init_state():
    defaults = {
        "rag": None,
        "messages": [],           # [{"role": "user"|"bot", "text": ..., "audio": ..., "sources": []}]
        "indexed_docs": [],
        "hf_token": os.getenv("HF_TOKEN", ""),
        "qdrant_url": os.getenv("QDRANT_URL", ""),
        "qdrant_key": os.getenv("QDRANT_API_KEY", ""),
        "initialized": False,
        "stt_mode": "Google Web Speech (free)",
        "tts_lang": "en",
        "voice_input_text": "",
    }
    for k, v in defaults.items():
        if k not in st.session_state:
            st.session_state[k] = v

init_state()


# ════════════════════════════════════════════════════════════════
# SIDEBAR
# ════════════════════════════════════════════════════════════════
with st.sidebar:
    st.markdown('<p class="title-gradient" style="font-size:22px;">🎙️ Voice RAG</p>', unsafe_allow_html=True)
    st.markdown('<p class="subtitle">PDF Knowledge Base + Voice Answers</p>', unsafe_allow_html=True)
    st.markdown("---")

    # ── API Configuration ─────────────────────────────────────
    st.markdown('<p class="section-header">🔑 API Configuration</p>', unsafe_allow_html=True)

    hf_input = st.text_input(
        "HuggingFace Token",
        value=st.session_state.hf_token,
        type="password",
        help="Get free token at huggingface.co/settings/tokens",
        placeholder="hf_xxxxxxxxxxxxxxxxxxxx",
    )
    qdrant_url_input = st.text_input(
        "Qdrant Cloud URL",
        value=st.session_state.qdrant_url,
        placeholder="https://xxxx.aws.cloud.qdrant.io:6333",
        help="Free tier at cloud.qdrant.io",
    )
    qdrant_key_input = st.text_input(
        "Qdrant API Key",
        value=st.session_state.qdrant_key,
        type="password",
    )

    if st.button("⚡ Connect", type="primary", use_container_width=True):
        if hf_input and qdrant_url_input and qdrant_key_input:
            try:
                with st.spinner("Connecting to Qdrant …"):
                    rag = RAGEngine(
                        qdrant_url=qdrant_url_input,
                        qdrant_api_key=qdrant_key_input,
                        hf_token=hf_input,
                    )
                    rag.ensure_collection()
                    st.session_state.rag = rag
                    st.session_state.hf_token = hf_input
                    st.session_state.qdrant_url = qdrant_url_input
                    st.session_state.qdrant_key = qdrant_key_input
                    st.session_state.initialized = True
                st.success("✅ Connected!")
            except Exception as e:
                st.error(f"Connection failed: {e}")
        else:
            st.warning("Please fill in all API credentials.")

    # ── Status ────────────────────────────────────────────────
    st.markdown("---")
    st.markdown('<p class="section-header">📊 System Status</p>', unsafe_allow_html=True)
    if st.session_state.initialized:
        st.markdown('<span class="badge-green">● Connected</span>', unsafe_allow_html=True)
        n = len(st.session_state.indexed_docs)
        st.markdown(f"**{n} document{'s' if n != 1 else ''}** indexed")
        if st.session_state.indexed_docs:
            for doc in st.session_state.indexed_docs:
                st.markdown(f"  📄 `{doc}`")
    else:
        st.markdown('<span class="badge-yellow">● Not connected</span>', unsafe_allow_html=True)
        st.caption("Enter credentials and click Connect.")

    # ── Voice Settings ────────────────────────────────────────
    st.markdown("---")
    st.markdown('<p class="section-header">🎤 Voice Settings</p>', unsafe_allow_html=True)
    st.session_state.stt_mode = st.selectbox(
        "Speech-to-Text Engine",
        ["Google Web Speech (free)", "HuggingFace Whisper (free, slower)"],
        help="Google is faster. Whisper uses your HF token.",
    )
    st.session_state.tts_lang = st.selectbox(
        "TTS Language",
        {"en": "English", "hi": "Hindi", "fr": "French", "de": "German", "es": "Spanish"}.keys(),
        format_func=lambda k: {"en": "🇬🇧 English", "hi": "🇮🇳 Hindi", "fr": "🇫🇷 French", "de": "🇩🇪 German", "es": "🇪🇸 Spanish"}[k],
    )

    # ── Clear KB ──────────────────────────────────────────────
    st.markdown("---")
    if st.button("🗑️ Clear Knowledge Base", use_container_width=True):
        if st.session_state.rag:
            st.session_state.rag.clear_knowledge_base()
            st.session_state.indexed_docs = []
            st.success("Knowledge base cleared.")
        else:
            st.warning("Not connected yet.")


# ════════════════════════════════════════════════════════════════
# MAIN AREA
# ════════════════════════════════════════════════════════════════
st.markdown('<h1 class="title-gradient">🎙️ Voice RAG Chatbot</h1>', unsafe_allow_html=True)
st.markdown('<p class="subtitle">Upload PDFs → Ask anything → Get text + spoken answers (100% free cloud)</p>', unsafe_allow_html=True)
st.markdown("")

# ── Split layout ──────────────────────────────────────────────
col_left, col_right = st.columns([3, 2], gap="large")

# ═══════════════════════════════════
# LEFT — Chat Interface
# ═══════════════════════════════════
with col_left:
    st.markdown("### 💬 Chat")

    # ── Chat bubbles ─────────────────────────────────────────
    chat_html = '<div class="chat-container">'
    if not st.session_state.messages:
        chat_html += """
        <div style="text-align:center; padding:60px 20px; color:#475569;">
            <div style="font-size:40px; margin-bottom:12px;">🤖</div>
            <div style="font-size:16px; font-weight:600;">Hello! I'm your Voice RAG Assistant</div>
            <div style="font-size:13px; margin-top:6px;">Upload PDFs → Connect → Ask anything</div>
        </div>
        """
    else:
        for msg in st.session_state.messages:
            ts = msg.get("time", "")
            if msg["role"] == "user":
                chat_html += f"""
                <div>
                  <div class="msg-label" style="text-align:right; color:#60a5fa;">YOU · {ts}</div>
                  <div class="msg-user">{msg['text']}</div>
                </div>
                """
            else:
                sources_html = ""
                for src in msg.get("sources", []):
                    sources_html += f'<span class="source-chip">📄 {src["source"]} ({src["score"]})</span>'
                chat_html += f"""
                <div>
                  <div class="msg-label" style="color:#818cf8;">🤖 ASSISTANT · {ts}</div>
                  <div class="msg-bot">{msg['text']}</div>
                  {f'<div style="margin:4px 0 8px 0;">{sources_html}</div>' if sources_html else ""}
                </div>
                """
    chat_html += "</div>"
    st.markdown(chat_html, unsafe_allow_html=True)

    # ── Text input ────────────────────────────────────────────
    with st.form("chat_form", clear_on_submit=True):
        user_input = st.text_area(
            "Your question",
            placeholder="Type your question here…" if st.session_state.initialized else "⚠️ Connect to backend first (sidebar)",
            label_visibility="collapsed",
            height=80,
            disabled=not st.session_state.initialized,
        )
        # Pre-fill from voice transcription
        if st.session_state.voice_input_text:
            user_input = st.session_state.voice_input_text
            st.session_state.voice_input_text = ""

        send_col, clear_col = st.columns([3, 1])
        with send_col:
            submitted = st.form_submit_button("➤ Send", type="primary", use_container_width=True, disabled=not st.session_state.initialized)
        with clear_col:
            clear = st.form_submit_button("🗑", use_container_width=True)

    if clear:
        st.session_state.messages = []
        st.rerun()

    # ── Handle text submit ────────────────────────────────────
    if submitted and user_input.strip():
        rag: RAGEngine = st.session_state.rag
        ts = datetime.now().strftime("%H:%M")

        # Add user message
        st.session_state.messages.append({
            "role": "user",
            "text": user_input.strip(),
            "time": ts,
        })

        # RAG pipeline
        with st.spinner("🔍 Searching knowledge base & generating answer…"):
            answer, chunks = rag.ask(user_input.strip())

        # TTS
        audio_bytes = None
        try:
            with st.spinner("🔊 Generating speech…"):
                audio_bytes = text_to_speech(answer, lang=st.session_state.tts_lang)
        except Exception as e:
            st.warning(f"TTS failed: {e}")

        # Store bot message
        st.session_state.messages.append({
            "role": "bot",
            "text": answer,
            "sources": chunks,
            "audio": audio_bytes,
            "time": ts,
        })
        st.rerun()

    # ── Latest audio player ───────────────────────────────────
    bot_msgs = [m for m in st.session_state.messages if m["role"] == "bot" and m.get("audio")]
    if bot_msgs:
        latest = bot_msgs[-1]
        st.markdown("#### 🔊 Audio Response")
        st.audio(latest["audio"], format="audio/mp3")

        b64 = base64.b64encode(latest["audio"]).decode()
        dl_link = f'<a href="data:audio/mp3;base64,{b64}" download="voice_response.mp3" style="text-decoration:none;"><button style="background:#6366f1;color:white;border:none;padding:8px 18px;border-radius:8px;font-weight:600;cursor:pointer;">📥 Download Audio</button></a>'
        st.markdown(dl_link, unsafe_allow_html=True)


# ═══════════════════════════════════
# RIGHT — Voice Input + PDF Upload
# ═══════════════════════════════════
with col_right:

    # ── Voice Input ───────────────────────────────────────────
    st.markdown("### 🎤 Voice Input")
    st.caption("Record your question and let the STT engine transcribe it.")

    audio_file = st.file_uploader(
        "Upload audio file (WAV / MP3)",
        type=["wav", "mp3", "ogg", "m4a"],
        key="audio_upload",
        disabled=not st.session_state.initialized,
        help="Record on your phone / mic, then upload the file here.",
    )

    if audio_file and st.session_state.initialized:
        st.audio(audio_file)
        if st.button("🎙️ Transcribe & Send", type="primary", use_container_width=True):
            with st.spinner("Transcribing…"):
                audio_bytes_raw = audio_file.read()
                stt_mode = st.session_state.stt_mode

                if "Whisper" in stt_mode:
                    transcript = whisper_stt_hf(audio_bytes_raw, st.session_state.hf_token)
                else:
                    transcript = speech_to_text_from_bytes(audio_bytes_raw)

            if transcript and not transcript.startswith("[STT"):
                st.success(f"📝 Transcribed: **{transcript}**")
                # Auto-ask via RAG
                rag: RAGEngine = st.session_state.rag
                ts = datetime.now().strftime("%H:%M")
                st.session_state.messages.append({
                    "role": "user",
                    "text": f"🎤 {transcript}",
                    "time": ts,
                })
                with st.spinner("Generating answer…"):
                    answer, chunks = rag.ask(transcript)
                audio_resp = None
                try:
                    audio_resp = text_to_speech(answer, lang=st.session_state.tts_lang)
                except Exception:
                    pass
                st.session_state.messages.append({
                    "role": "bot",
                    "text": answer,
                    "sources": chunks,
                    "audio": audio_resp,
                    "time": ts,
                })
                st.rerun()
            else:
                st.warning(f"Could not transcribe: {transcript}")

    st.markdown("---")

    # ── PDF Upload + Indexing ──────────────────────────────────
    st.markdown("### 📑 Document Upload")
    st.caption("Upload PDFs to build the knowledge base.")

    pdf_files = st.file_uploader(
        "Upload PDF documents",
        type=["pdf"],
        accept_multiple_files=True,
        key="pdf_upload",
        disabled=not st.session_state.initialized,
    )

    if pdf_files and st.session_state.initialized:
        if st.button("📥 Index All PDFs", type="primary", use_container_width=True):
            rag: RAGEngine = st.session_state.rag
            success_count = 0
            for pdf in pdf_files:
                if pdf.name in st.session_state.indexed_docs:
                    st.info(f"⏭️ {pdf.name} already indexed — skipping.")
                    continue
                with st.spinner(f"Indexing **{pdf.name}** …"):
                    try:
                        n_chunks = rag.index_pdf(pdf.read(), pdf.name)
                        st.session_state.indexed_docs.append(pdf.name)
                        st.success(f"✅ {pdf.name} → {n_chunks} chunks")
                        success_count += 1
                    except Exception as e:
                        st.error(f"❌ {pdf.name}: {e}")
            if success_count:
                st.balloons()

    # ── Indexed docs summary ──────────────────────────────────
    if st.session_state.indexed_docs:
        st.markdown("**Indexed Documents:**")
        for doc in st.session_state.indexed_docs:
            st.markdown(f"  ✅ `{doc}`")

    st.markdown("---")

    # ── Chat History Export ───────────────────────────────────
    st.markdown("### 📜 Chat History")
    if st.session_state.messages:
        history_txt = "\n\n".join(
            [f"[{m['role'].upper()} · {m.get('time','')}]\n{m['text']}" for m in st.session_state.messages]
        )
        st.download_button(
            label="📥 Export Chat History",
            data=history_txt,
            file_name=f"chat_history_{datetime.now().strftime('%Y%m%d_%H%M')}.txt",
            mime="text/plain",
            use_container_width=True,
        )
        st.caption(f"{len(st.session_state.messages)} messages in history")
    else:
        st.caption("No messages yet.")

    # ── Quick help ────────────────────────────────────────────
    st.markdown("---")
    with st.expander("ℹ️ How to use"):
        st.markdown("""
**Step 1** — Enter your API keys in the sidebar and click **Connect**.

**Step 2** — Upload one or more PDFs and click **Index All PDFs**.

**Step 3** — Type your question OR upload an audio recording and click **Transcribe & Send**.

**Step 4** — Get a text answer + auto-played voice response!

---
**Free Services Used:**
| Service | Purpose |
|---|---|
| HuggingFace Inference API | LLM (Mistral-7B, free) |
| Google Web Speech | STT (free, no key) |
| HuggingFace Whisper | STT fallback (free HF token) |
| gTTS | Text-to-Speech (free) |
| Qdrant Cloud | Vector DB (free 1GB tier) |
| sentence-transformers | Embeddings (free local) |
        """)
