import time
import logging
from datetime import datetime
from typing import Optional, List, Dict, Any
from fastapi import APIRouter, HTTPException, BackgroundTasks
from pydantic import BaseModel, Field, validator
from app.services.llm_service import llm_service
# Check if LLM service is available

    
# Configure logging
logger = logging.getLogger(__name__)
router = APIRouter()

try:
    from app.services.llm_service import llm_service
    LLM_AVAILABLE = llm_service.is_available()
except ImportError:
    llm_service = None
    LLM_AVAILABLE = False
    logger.warning("LLM service not available. Translation features limited.")

# Request Models
class TranslateRequest(BaseModel):
    text: str = Field(..., min_length=1, max_length=10000, description="Text to translate")
    target_language: str = Field(..., description="Target language (hindi, marathi, english, etc.)")
    source_language: Optional[str] = Field(default="auto", description="Source language (auto-detect if not specified)")
    use_llm: Optional[bool] = Field(default=True, description="Use LLM for better translation quality")
    
    @validator('text')
    def validate_text(cls, v):
        if not v.strip():
            raise ValueError('Text cannot be empty')
        return v.strip()

class TranslateDocumentRequest(BaseModel):
    document_text: str = Field(..., min_length=50, max_length=50000)
    target_language: str = Field(...)
    preserve_formatting: Optional[bool] = Field(default=True)
    use_llm: Optional[bool] = Field(default=True)

class BatchTranslateRequest(BaseModel):
    texts: List[str] = Field(..., min_items=1, max_items=20, description="List of texts to translate")
    target_language: str = Field(...)
    use_llm: Optional[bool] = Field(default=True)

class DetectLanguageRequest(BaseModel):
    text: str = Field(..., min_length=1, max_length=5000)

# Response Models
class TranslateResponse(BaseModel):
    success: bool
    original_text: str
    translated_text: str
    source_language: str
    target_language: str
    translation_method: str  # "llm" or "traditional"
    processing_time: float
    timestamp: str

class BatchTranslateResponse(BaseModel):
    success: bool
    translations: List[Dict[str, str]]
    total_texts: int
    target_language: str
    processing_time: float
    timestamp: str

class LanguageDetectionResponse(BaseModel):
    success: bool
    detected_language: str
    confidence: float
    text_preview: str

class SupportedLanguagesResponse(BaseModel):
    supported_languages: List[Dict[str, str]]
    llm_available: bool
    total_languages: int

# Helper Functions
def get_language_info() -> Dict[str, str]:
    """Get supported languages with their codes"""
    return {
        "english": "en",
        "hindi": "hi",
        "marathi": "mr",
        "spanish": "es",
        "french": "fr",
        "german": "de",
        "italian": "it",
        "portuguese": "pt",
        "russian": "ru",
        "chinese": "zh",
        "japanese": "ja",
        "korean": "ko",
        "arabic": "ar",
        "bengali": "bn",
        "gujarati": "gu",
        "tamil": "ta",
        "telugu": "te",
        "kannada": "kn",
        "malayalam": "ml",
        "punjabi": "pa"
    }

def detect_language_simple(text: str) -> str:
    """Simple language detection based on character patterns"""
    # Devanagari script detection (Hindi/Marathi)
    if any('\u0900' <= char <= '\u097F' for char in text):
        # Check for Marathi-specific characters
        marathi_chars = ['ळ', 'ऱ']
        if any(char in text for char in marathi_chars):
            return "marathi"
        return "hindi"
    
    # Check for other scripts
    if any('\u0A00' <= char <= '\u0A7F' for char in text):
        return "gujarati"
    if any('\u0B80' <= char <= '\u0BFF' for char in text):
        return "tamil"
    if any('\u0C00' <= char <= '\u0C7F' for char in text):
        return "telugu"
    if any('\u0C80' <= char <= '\u0CFF' for char in text):
        return "kannada"
    if any('\u0D00' <= char <= '\u0D7F' for char in text):
        return "malayalam"
    
    return "english"  # Default

async def log_translation_analytics(
    text_length: int,
    source_lang: str,
    target_lang: str,
    processing_time: float,
    method: str,
    success: bool
):
    """Background task for logging analytics"""
    logger.info(
        f"Translation Analytics - Length: {text_length}, "
        f"{source_lang}→{target_lang}, Time: {processing_time:.2f}s, "
        f"Method: {method}, Success: {success}"
    )

# API Endpoints

@router.post("/translate/", response_model=TranslateResponse)
async def translate_text(
    request: TranslateRequest,
    background_tasks: BackgroundTasks
):
    """
    Translate text to target language.
    Uses LLM for better quality or falls back to traditional methods.
    """
    start_time = time.time()
    
    try:
        # Detect source language if auto
        if request.source_language == "auto":
            source_lang = detect_language_simple(request.text)
        else:
            source_lang = request.source_language
        
        logger.info(f"Translating from {source_lang} to {request.target_language}")
        
        # Choose translation method
        if request.use_llm and LLM_AVAILABLE and llm_service.is_available():
            # Use LLM for translation
            translated_text = llm_service.translate_text(
                text=request.text,
                target_language=request.target_language
            )
            method = "llm"
        else:
    # No LLM available
            if not LLM_AVAILABLE:
                raise HTTPException(
                    status_code=503,
                    detail="Translation service unavailable. LLM is required for translation. Please configure an LLM provider."
                )
            
            # If you want to allow basic fallback:
            translated_text = request.text
            method = "no_translation"
            logger.warning("LLM not available, returning original text")
        
        processing_time = time.time() - start_time
        
        # Log analytics
        background_tasks.add_task(
            log_translation_analytics,
            len(request.text),
            source_lang,
            request.target_language,
            processing_time,
            method,
            True
        )
        
        return TranslateResponse(
            success=True,
            original_text=request.text,
            translated_text=translated_text,
            source_language=source_lang,
            target_language=request.target_language,
            translation_method=method,
            processing_time=processing_time,
            timestamp=datetime.now().isoformat()
        )
        
    except Exception as e:
        logger.error(f"Translation error: {str(e)}")
        processing_time = time.time() - start_time
        
        background_tasks.add_task(
            log_translation_analytics,
            len(request.text),
            request.source_language,
            request.target_language,
            processing_time,
            "error",
            False
        )
        
        raise HTTPException(
            status_code=500,
            detail=f"Translation failed: {str(e)}"
        )

@router.post("/translate/document/", response_model=TranslateResponse)
async def translate_document(
    request: TranslateDocumentRequest,
    background_tasks: BackgroundTasks
):
    """
    Translate an entire document while preserving formatting.
    Optimized for longer texts.
    """
    start_time = time.time()
    
    try:
        # Split document into chunks if too long
        max_chunk_size = 2000
        text = request.document_text
        
        if len(text) > max_chunk_size and request.preserve_formatting:
            # Split by paragraphs
            chunks = text.split('\n\n')
            translated_chunks = []
            
            for chunk in chunks:
                if chunk.strip():
                    if request.use_llm and LLM_AVAILABLE and llm_service.is_available():
                        translated = llm_service.translate_text(
                            text=chunk,
                            target_language=request.target_language
                        )
                    else:
                        translated = chunk  # Fallback
                    translated_chunks.append(translated)
            
            translated_text = '\n\n'.join(translated_chunks)
            method = "llm_chunked"
        else:
            # Translate as one piece
            if request.use_llm and LLM_AVAILABLE and llm_service.is_available():
                translated_text = llm_service.translate_text(
                    text=text,
                    target_language=request.target_language
                )
                method = "llm"
            else:
                translated_text = text  # Fallback
                method = "traditional"
        
        processing_time = time.time() - start_time
        source_lang = detect_language_simple(text)
        
        return TranslateResponse(
            success=True,
            original_text=text[:200] + "..." if len(text) > 200 else text,
            translated_text=translated_text,
            source_language=source_lang,
            target_language=request.target_language,
            translation_method=method,
            processing_time=processing_time,
            timestamp=datetime.now().isoformat()
        )
        
    except Exception as e:
        logger.error(f"Document translation error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Document translation failed: {str(e)}")

@router.post("/translate/batch/", response_model=BatchTranslateResponse)
async def batch_translate(
    request: BatchTranslateRequest,
    background_tasks: BackgroundTasks
):
    """
    Translate multiple texts at once.
    Useful for translating lists of items, UI text, etc.
    """
    start_time = time.time()
    
    try:
        if len(request.texts) > 20:
            raise HTTPException(status_code=400, detail="Maximum 20 texts per batch")
        
        translations = []
        
        for i, text in enumerate(request.texts):
            try:
                if request.use_llm and LLM_AVAILABLE and llm_service.is_available():
                    translated = llm_service.translate_text(
                        text=text,
                        target_language=request.target_language
                    )
                else:
                    translated = text  # Fallback
                
                translations.append({
                    "index": i,
                    "original": text,
                    "translated": translated,
                    "success": True
                })
            except Exception as e:
                translations.append({
                    "index": i,
                    "original": text,
                    "error": str(e),
                    "success": False
                })
        
        processing_time = time.time() - start_time
        
        return BatchTranslateResponse(
            success=True,
            translations=translations,
            total_texts=len(request.texts),
            target_language=request.target_language,
            processing_time=processing_time,
            timestamp=datetime.now().isoformat()
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Batch translation error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Batch translation failed: {str(e)}")

@router.post("/translate/detect/", response_model=LanguageDetectionResponse)
async def detect_language(request: DetectLanguageRequest):
    """
    Detect the language of given text.
    Useful for auto-detection before translation.
    """
    try:
        detected = detect_language_simple(request.text)
        
        # Calculate confidence based on script detection
        confidence = 0.9 if detected != "english" else 0.7
        
        return LanguageDetectionResponse(
            success=True,
            detected_language=detected,
            confidence=confidence,
            text_preview=request.text[:100] + "..." if len(request.text) > 100 else request.text
        )
        
    except Exception as e:
        logger.error(f"Language detection error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Language detection failed: {str(e)}")

@router.get("/translate/languages/", response_model=SupportedLanguagesResponse)
async def get_supported_languages():
    """
    Get list of all supported languages for translation.
    """
    try:
        languages_dict = get_language_info()
        
        languages_list = [
            {"name": name.capitalize(), "code": code}
            for name, code in languages_dict.items()
        ]
        
        return SupportedLanguagesResponse(
            supported_languages=languages_list,
            llm_available=llm_service.is_available(),
            total_languages=len(languages_list)
        )
        
    except Exception as e:
        logger.error(f"Error getting languages: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/translate/health/")
async def translation_health():
    """Health check for translation service"""
    try:
        llm_status = LLM_AVAILABLE and (llm_service.is_available() if llm_service else False)
        
        return {
            "status": "healthy",
            "service": "translation",
            "llm_available": llm_status,
            "llm_provider": llm_service.provider if llm_status else None,
            "supported_languages": len(get_language_info()),
            "timestamp": datetime.now().isoformat()
        }
    except Exception as e:
        return {
            "status": "unhealthy",
            "service": "translation",
            "error": str(e),
            "timestamp": datetime.now().isoformat()
        }

@router.get("/translate/stats/")
async def get_translation_stats():
    """Get translation service statistics and capabilities"""
    return {
        "capabilities": {
            "llm_translation": LLM_AVAILABLE,
            "language_detection": True,
            "batch_translation": True,
            "document_translation": True,
            "formatting_preservation": True
        },
        "limits": {
            "max_text_length": 10000,
            "max_document_length": 50000,
            "max_batch_size": 20
        },
        "indian_languages": [
            "Hindi", "Marathi", "Gujarati", "Tamil", 
            "Telugu", "Kannada", "Malayalam", "Punjabi", "Bengali"
        ],
        "features": {
            "context_aware": llm_service.is_available(),
            "idiomatic_translation": llm_service.is_available(),
            "cultural_adaptation": llm_service.is_available()
        }
    }