# ════════════════════════════════════════════════════════════════
# rag_engine.py  — RAG pipeline (PDF → chunks → embed → Qdrant)
# Uses: HuggingFace Inference API + Qdrant Cloud + sentence-transformers
# 100% free-tier cloud, no local LLMs
# ════════════════════════════════════════════════════════════════

from __future__ import annotations

import uuid
import re
import logging
from typing import Optional
import requests
import numpy as np

from qdrant_client import QdrantClient
from qdrant_client.http.models import (
    Distance,
    VectorParams,
    PointStruct,
    Filter,
    FieldCondition,
    MatchValue,
)
from sentence_transformers import SentenceTransformer

logger = logging.getLogger(__name__)

# ── constants ────────────────────────────────────────────────
EMBED_MODEL   = "all-MiniLM-L6-v2"   # free, fast, 384-dim
EMBED_DIM     = 384
COLLECTION    = "voice_rag_kb"
HF_API_BASE   = "https://api-inference.huggingface.co/models"
HF_LLM_MODEL  = "mistralai/Mistral-7B-Instruct-v0.2"  # free HF Inference API


# ── RAG Engine ───────────────────────────────────────────────
class RAGEngine:
    """
    Manages:
      - PDF extraction + chunking
      - Embedding via sentence-transformers (runs locally but lightweight)
      - Vector storage in Qdrant Cloud
      - Semantic retrieval
      - Answer generation via HuggingFace Inference API (free tier)
    """

    def __init__(self, qdrant_url: str, qdrant_api_key: str, hf_token: str) -> None:
        self.hf_token = hf_token
        self.qdrant_url = qdrant_url
        self.qdrant_api_key = qdrant_api_key

        # Qdrant cloud client
        self.qd = QdrantClient(url=qdrant_url, api_key=qdrant_api_key)

        # Embedding model (small, ~90 MB, runs on CPU in seconds)
        self._embedder: Optional[SentenceTransformer] = None

        # Track indexed doc names
        self.indexed_docs: list[str] = []

    # ── lazy-load embedder ────────────────────────────────────
    def _get_embedder(self) -> SentenceTransformer:
        if self._embedder is None:
            logger.info("Loading embedding model %s …", EMBED_MODEL)
            self._embedder = SentenceTransformer(EMBED_MODEL)
        return self._embedder

    def embed(self, texts: list[str]) -> list[list[float]]:
        """Return list of embedding vectors."""
        model = self._get_embedder()
        vecs = model.encode(texts, show_progress_bar=False, normalize_embeddings=True)
        return vecs.tolist()

    # ── Qdrant collection bootstrap ───────────────────────────
    def ensure_collection(self) -> None:
        """Create Qdrant collection if it does not exist yet."""
        existing = [c.name for c in self.qd.get_collections().collections]
        if COLLECTION not in existing:
            self.qd.create_collection(
                collection_name=COLLECTION,
                vectors_config=VectorParams(size=EMBED_DIM, distance=Distance.COSINE),
            )
            logger.info("Created Qdrant collection '%s'", COLLECTION)

    # ── PDF text extraction ───────────────────────────────────
    @staticmethod
    def extract_text_from_pdf(pdf_bytes: bytes) -> str:
        """Extract all text from a PDF byte-string."""
        try:
            import pypdf
            from io import BytesIO
            reader = pypdf.PdfReader(BytesIO(pdf_bytes))
            pages = []
            for page in reader.pages:
                text = page.extract_text() or ""
                pages.append(text)
            return "\n".join(pages)
        except Exception as exc:
            logger.error("PDF extraction failed: %s", exc)
            return ""

    # ── Chunking ──────────────────────────────────────────────
    @staticmethod
    def chunk_text(text: str, chunk_size: int = 600, overlap: int = 120) -> list[str]:
        """
        Split text into overlapping chunks by sentence boundary awareness.
        chunk_size and overlap are measured in characters.
        """
        # Normalize whitespace
        text = re.sub(r"\s+", " ", text).strip()
        if not text:
            return []

        chunks: list[str] = []
        start = 0
        length = len(text)

        while start < length:
            end = min(start + chunk_size, length)

            # Extend to a sentence boundary if possible
            if end < length:
                boundary = max(
                    text.rfind(".", start, end),
                    text.rfind("!", start, end),
                    text.rfind("?", start, end),
                    text.rfind("\n", start, end),
                )
                if boundary > start + overlap:
                    end = boundary + 1

            chunk = text[start:end].strip()
            if chunk:
                chunks.append(chunk)
            start = end - overlap

        return chunks

    # ── Index a PDF ───────────────────────────────────────────
    def index_pdf(self, pdf_bytes: bytes, filename: str) -> int:
        """
        Extract → chunk → embed → upsert into Qdrant.
        Returns the number of chunks stored.
        """
        self.ensure_collection()

        text = self.extract_text_from_pdf(pdf_bytes)
        if not text.strip():
            raise ValueError(f"No extractable text found in '{filename}'.")

        chunks = self.chunk_text(text)
        if not chunks:
            raise ValueError("Text chunking produced no usable chunks.")

        vectors = self.embed(chunks)

        points = [
            PointStruct(
                id=str(uuid.uuid4()),
                vector=vec,
                payload={"text": chunk, "source": filename, "chunk_idx": i},
            )
            for i, (chunk, vec) in enumerate(zip(chunks, vectors))
        ]

        # Qdrant upsert (batched for reliability)
        batch_size = 64
        for i in range(0, len(points), batch_size):
            self.qd.upsert(collection_name=COLLECTION, points=points[i : i + batch_size])

        if filename not in self.indexed_docs:
            self.indexed_docs.append(filename)

        logger.info("Indexed '%s': %d chunks", filename, len(chunks))
        return len(chunks)

    # ── Semantic search ───────────────────────────────────────
    def search(self, query: str, top_k: int = 5) -> list[dict]:
        """Return top-k relevant chunks from Qdrant."""
        q_vec = self.embed([query])[0]
        results = self.qd.search(
            collection_name=COLLECTION,
            query_vector=q_vec,
            limit=top_k,
            with_payload=True,
        )
        return [
            {
                "text": r.payload["text"],
                "source": r.payload.get("source", "unknown"),
                "score": round(r.score, 3),
            }
            for r in results
        ]

    # ── LLM answer via HuggingFace Inference API ─────────────
    def generate_answer(self, query: str, context_chunks: list[dict]) -> str:
        """
        Call HuggingFace Inference API (free tier) with Mistral-7B-Instruct.
        Falls back gracefully if rate-limited.
        """
        context = "\n\n---\n\n".join(
            [f"[Source: {c['source']}]\n{c['text']}" for c in context_chunks]
        )

        prompt = f"""<s>[INST] You are a helpful document assistant. Answer the question using ONLY the context below.
Be concise (3-5 sentences), accurate, and friendly. If the answer is not in the context, say so.

Context:
{context}

Question: {query} [/INST]"""

        headers = {
            "Authorization": f"Bearer {self.hf_token}",
            "Content-Type": "application/json",
        }
        payload = {
            "inputs": prompt,
            "parameters": {
                "max_new_tokens": 400,
                "temperature": 0.4,
                "return_full_text": False,
                "do_sample": True,
            },
        }

        try:
            resp = requests.post(
                f"{HF_API_BASE}/{HF_LLM_MODEL}",
                headers=headers,
                json=payload,
                timeout=60,
            )

            if resp.status_code == 200:
                data = resp.json()
                if isinstance(data, list) and data:
                    return data[0].get("generated_text", "").strip()
                elif isinstance(data, dict):
                    # Handle loading / rate-limit message
                    if "error" in data:
                        wait = data.get("estimated_time", 20)
                        return f"⏳ HuggingFace model is loading (est. {wait:.0f}s). Please retry in a moment."
                    return str(data)
            elif resp.status_code == 503:
                return "⏳ HuggingFace model is currently loading. Please wait ~20s and ask again."
            else:
                return f"❌ HuggingFace API error {resp.status_code}: {resp.text[:200]}"

        except requests.Timeout:
            return "⏰ Request timed out. HuggingFace free tier can be slow — please retry."
        except Exception as exc:
            return f"❌ Unexpected error: {exc}"

    # ── Full RAG pipeline ─────────────────────────────────────
    def ask(self, query: str, top_k: int = 5) -> tuple[str, list[dict]]:
        """
        Full pipeline: embed query → search Qdrant → generate answer.
        Returns (answer_text, source_chunks).
        """
        chunks = self.search(query, top_k=top_k)
        if not chunks:
            return (
                "⚠️ No relevant documents found. Please upload and index some PDFs first.",
                [],
            )
        answer = self.generate_answer(query, chunks)
        return answer, chunks

    # ── Clear collection ──────────────────────────────────────
    def clear_knowledge_base(self) -> None:
        """Delete and recreate the Qdrant collection."""
        collections = [c.name for c in self.qd.get_collections().collections]
        if COLLECTION in collections:
            self.qd.delete_collection(COLLECTION)
        self.indexed_docs.clear()
        logger.info("Knowledge base cleared.")
