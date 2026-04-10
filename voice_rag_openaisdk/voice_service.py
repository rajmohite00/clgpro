# ════════════════════════════════════════════════════════════════
# voice_service.py — STT + TTS using 100% free cloud/local services
#
# STT: Google Web Speech API via SpeechRecognition (free, no key needed)
#      OR HuggingFace Whisper (if google fails)
# TTS: gTTS (Google Text-to-Speech, free, no key needed)
# ════════════════════════════════════════════════════════════════

from __future__ import annotations

import io
import logging
import tempfile
import os
from typing import Optional

logger = logging.getLogger(__name__)


# ── TTS: gTTS ────────────────────────────────────────────────
def text_to_speech(text: str, lang: str = "en") -> bytes:
    """
    Convert text to MP3 bytes using gTTS (free, no key needed).
    Returns raw MP3 bytes ready for st.audio() or download.
    """
    from gtts import gTTS

    # Clean text for better TTS (remove markdown bold/italic etc.)
    clean = (
        text.replace("**", "")
            .replace("*", "")
            .replace("__", "")
            .replace("`", "")
            .replace("#", "")
            .strip()
    )

    tts = gTTS(text=clean, lang=lang, slow=False)
    buf = io.BytesIO()
    tts.write_to_fp(buf)
    buf.seek(0)
    return buf.read()


# ── STT: SpeechRecognition (Google Web Speech API) ───────────
def speech_to_text_from_bytes(audio_bytes: bytes, sample_rate: int = 16000) -> str:
    """
    Transcribe audio bytes (WAV recommended) using the free
    Google Web Speech API via the SpeechRecognition library.
    No API key needed for the free tier (~60 requests/hr).
    """
    import speech_recognition as sr

    recognizer = sr.Recognizer()

    try:
        # Write bytes to temp WAV file so SR can read it
        with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
            tmp.write(audio_bytes)
            tmp_path = tmp.name

        with sr.AudioFile(tmp_path) as source:
            audio_data = recognizer.record(source)

        # Use Google Web Speech (free, no key)
        transcript = recognizer.recognize_google(audio_data)
        return transcript.strip()

    except sr.UnknownValueError:
        return ""  # could not understand audio
    except sr.RequestError as e:
        logger.warning("Google STT request failed: %s", e)
        return f"[STT error: {e}]"
    except Exception as exc:
        logger.error("STT unexpected error: %s", exc)
        return f"[STT error: {exc}]"
    finally:
        try:
            os.unlink(tmp_path)
        except Exception:
            pass


# ── HuggingFace Whisper as fallback STT ──────────────────────
def whisper_stt_hf(audio_bytes: bytes, hf_token: str) -> str:
    """
    Use HuggingFace Whisper via Inference API as fallback.
    Free with HF token (rate limits apply).
    """
    import requests

    headers = {"Authorization": f"Bearer {hf_token}"}
    model = "openai/whisper-small"

    try:
        resp = requests.post(
            f"https://api-inference.huggingface.co/models/{model}",
            headers=headers,
            data=audio_bytes,
            timeout=30,
        )
        if resp.status_code == 200:
            data = resp.json()
            if isinstance(data, dict):
                return data.get("text", "").strip()
            return str(data)
        else:
            return f"[Whisper API error {resp.status_code}]"
    except Exception as exc:
        return f"[Whisper error: {exc}]"
