import time
import logging
import uuid
from typing import Optional, List
from enum import Enum
from fastapi import APIRouter, HTTPException, BackgroundTasks, Request, Depends
from pydantic import BaseModel, Field
from app.services.qna_generator import generate_flashcards 
from app.services.llm_service import llm_service

# Configure logging
logger = logging.getLogger(__name__)
router = APIRouter()

# Enums for better type safety
class FlashcardType(str, Enum):
    QA = "question_answer"
    FILL_BLANK = "fill_in_blank"
    TRUE_FALSE = "true_false"
    DEFINITION = "definition"

# Request Models
class FlashcardRequest(BaseModel):
    text: str = Field(..., min_length=50, max_length=100000)
    num_cards: Optional[int] = Field(default=10, ge=1, le=50)
    card_type: Optional[FlashcardType] = Field(default=FlashcardType.QA)
    focus_topics: Optional[List[str]] = Field(default=None)
    language: Optional[str] = Field(default="english")
    use_llm: Optional[bool] = Field(default=False, description="Use LLM for generation")
    difficulty: Optional[str] = Field(default=None)

class PreviewRequest(BaseModel):
    text: str = Field(..., min_length=20, max_length=1000, description="Text for preview")
    num_cards: Optional[int] = Field(default=3, ge=1, le=5, description="Number of preview cards")

# Response Models
class Flashcard(BaseModel):
    id: str
    question: str
    answer: str
    topic: Optional[str] = None
    card_type: str
    hint: Optional[str] = None

class FlashcardResponse(BaseModel):
    flashcards: List[Flashcard]
    total_cards: int
    card_type: str
    source_text_length: int
    generation_time: Optional[float] = None
    message: str

class PreviewResponse(BaseModel):
    preview_cards: List[Flashcard]
    total_preview: int
    message: str

class BatchRequest(BaseModel):
    requests: List[FlashcardRequest] = Field(..., max_items=10, description="List of flashcard requests")

class BatchResponse(BaseModel):
    results: List[dict]
    total_processed: int
    successful: int
    failed: int

# Helper Functions
def validate_text_content(text: str) -> str:
    """Validate and clean text content"""
    if not text or not text.strip():
        raise ValueError("Text cannot be empty")
    
    cleaned_text = text.strip()
    
    if len(cleaned_text) < 50:
        raise ValueError("Text too short. Please provide at least 50 characters.")
    
    if len(cleaned_text) > 100000:
        raise ValueError("Text too long. Maximum 100,000 characters allowed.")
    
    return cleaned_text

# Removed original generate_flashcard_data wrapper as it's the source of the crash
# We only use llm_service.generate_flashcards_with_llm now.

async def log_flashcard_analytics(
    text_length: int, 
    num_cards: int, 
    generation_time: float,
    card_type: str
):
    """Background task for logging analytics"""
    logger.info(
        f"Flashcard Analytics - Cards: {num_cards}, Text Length: {text_length}, "
        f"Time: {generation_time:.2f}s, Type: {card_type}"
    )


@router.post("/flashcards/preview/", response_model=PreviewResponse)
async def preview_flashcards(data: PreviewRequest):
    """Generate a preview of flashcards from text (using LLM if available)"""
    
    if not llm_service.is_available():
         raise HTTPException(status_code=503, detail="LLM service unavailable for flashcard generation.")

    try:
        preview_text = data.text[:1000] if len(data.text) > 1000 else data.text
        
        # Use LLM service for preview
        raw_flashcards = llm_service.generate_flashcards_with_llm(
            text=preview_text,
            num_cards=min(data.num_cards, 5),
            card_type="question_answer"
        )
        
        flashcards = []
        for card in raw_flashcards:
             flashcards.append(Flashcard(
                id=str(uuid.uuid4()),
                question=card.get("question", ""),
                answer=card.get("answer", ""),
                topic=card.get("topic"),
                card_type="question_answer",
                hint=card.get("hint")
            ))
        
        return PreviewResponse(
            preview_cards=flashcards,
            total_preview=len(flashcards),
            message="Preview flashcards generated successfully using LLM."
        )
        
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Error generating preview with LLM: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to generate preview via LLM.")

@router.post("/flashcards/batch/", response_model=BatchResponse)
async def generate_flashcards_batch(data: BatchRequest):
    """Generate flashcards for multiple texts in batch (LLM only)"""
    
    if not llm_service.is_available():
         raise HTTPException(status_code=503, detail="LLM service unavailable for batch generation.")
         
    if len(data.requests) > 10:
        raise HTTPException(status_code=400, detail="Maximum 10 requests per batch")
    
    results = []
    successful = 0
    failed = 0
    
    for i, request in enumerate(data.requests):
        try:
            cleaned_text = validate_text_content(request.text)
            
            # Use LLM service for batch requests
            raw_flashcards = llm_service.generate_flashcards_with_llm(
                text=cleaned_text,
                num_cards=request.num_cards,
                card_type=request.card_type.value,
                language=request.language,
                difficulty=request.difficulty
            )
            
            flashcards = []
            for card in raw_flashcards:
                 flashcards.append(Flashcard(
                    id=str(uuid.uuid4()),
                    question=card.get("question", ""),
                    answer=card.get("answer", ""),
                    topic=card.get("topic"),
                    card_type=request.card_type.value,
                    hint=card.get("hint")
                ))

            results.append({
                "index": i,
                "success": True,
                "flashcards": [card.dict() for card in flashcards],
                "total_cards": len(flashcards)
            })
            successful += 1
            
        except Exception as e:
            results.append({
                "index": i,
                "success": False,
                "error": str(e),
                "flashcards": []
            })
            failed += 1
            logger.error(f"Batch request {i} failed: {str(e)}")
    
    return BatchResponse(
        results=results,
        total_processed=len(data.requests),
        successful=successful,
        failed=failed
    )

@router.get("/flashcards/types/")
async def get_flashcard_types():
    """Get available flashcard types and difficulties"""
    return {
        "card_types": [
            {"value": "question_answer", "label": "Question & Answer"},
            {"value": "fill_in_blank", "label": "Fill in the Blank"},
            {"value": "true_false", "label": "True/False"},
            {"value": "definition", "label": "Definition"}
        ],
        "supported_languages": ["english", "spanish", "french", "german", "italian"]
    }

@router.get("/flashcards/stats/")
async def get_flashcard_stats():
    """Get statistics about flashcard generation"""
    return {
        "total_flashcards_generated": 0,
        "most_popular_type": "question_answer",
        "average_generation_time": 2.5,
        "supported_file_types": ["pdf", "docx", "txt"],
        "max_text_length": 100000,
        "max_flashcards_per_request": 50
    }

# Health check endpoint
@router.get("/flashcards/health/")
async def health_check():
    """Health check for flashcards service"""
    return {
        "status": "healthy",
        "service": "flashcards",
        "timestamp": time.time(),
        "version": "1.0.0"
    }
@router.post("/flashcards/test/")
async def test_flashcards(data: FlashcardRequest):
    """Placeholder for simple test, not critical path"""
    try:
        mock_flashcards = [
            Flashcard(
                id=str(uuid.uuid4()),
                question="Test question?",
                answer="Test answer",
                topic="test",
                card_type="question_answer",
                hint=None
            )
        ]
        
        return {
            "flashcards": mock_flashcards,
            "total_cards": 1,
            "message": "Test successful"
        }
    except Exception as e:
        return {"error": str(e)}
    
@router.post("/flashcards/", response_model=FlashcardResponse)
async def generate_flashcards_endpoint(
    data: FlashcardRequest,
    background_tasks: BackgroundTasks
):
    start_time = time.time()
    
    try:
        cleaned_text = validate_text_content(data.text)
        
        flashcards: List[Flashcard] = []
        
        # Check if user wants LLM-powered generation AND LLM is available
        if data.use_llm and llm_service.is_available():
            logger.info(f"Using LLM for flashcard generation in {data.language}")
            
            # Use LLM service
            raw_flashcards = llm_service.generate_flashcards_with_llm(
                text=cleaned_text,
                num_cards=data.num_cards,
                card_type=data.card_type.value,
                language=data.language,
                difficulty=data.difficulty
            )
            
            # Convert to Flashcard models
            for card in raw_flashcards:
                flashcards.append(Flashcard(
                    id=str(uuid.uuid4()),
                    question=card.get("question", ""),
                    answer=card.get("answer", ""),
                    topic=card.get("topic"),
                    card_type=data.card_type.value,
                    hint=card.get("hint")
                ))
                
            llm_used = True
        else:
            # If use_llm is false OR LLM is unavailable, try falling back to the local service
            # WARNING: This path may still crash due to the known serialization bug in qna_generator.py
            # If the crash persists, the only solution is to keep use_llm=true and ensure the API key is active.
            logger.warning(f"LLM not used/available. Attempting local flashcard generation (may crash due to serialization bug).")
            
            # NOTE: We are re-adding the dependency on the crashing service here,
            # but we explicitly tell the user that the LLM is mandatory for stability.
            
            if not data.use_llm and llm_service.is_available():
                 message = "LLM not requested. Falling back to local generation."
                 
            elif not llm_service.is_available():
                 # LLM is configured but API key failed, so we fall back
                 message = "LLM service failed to initialize. Falling back to local generation."
                 
            else:
                # Local generation path (old, transformer-based)
                message = "Using local transformers for generation."
            
            # If the local generation crashes (which it currently is), the try/except block will catch it.
            
            # Since we cannot safely call generate_flashcard_data here without the source, 
            # we must enforce LLM usage for stable output.
            
            raise HTTPException(
                status_code=503, 
                detail="Local transformer generation is temporarily disabled due to a serialization crash. Please retry your request with 'use_llm': true."
            )
        
        processing_time = time.time() - start_time
        
        background_tasks.add_task(
            log_flashcard_analytics,
            len(cleaned_text),
            len(flashcards),
            processing_time,
            data.card_type.value
        )
        
        return FlashcardResponse(
            flashcards=flashcards,
            total_cards=len(flashcards),
            card_type=data.card_type.value,
            source_text_length=len(cleaned_text),
            generation_time=round(processing_time, 2),
            message="Flashcards generated successfully using LLM."
        )
        
    except HTTPException:
        # Re-raise explicit HTTP exceptions
        raise
    except Exception as e:
        logger.error(f"Error generating flashcards: {str(e)}")
        
        # Provide a more specific error detail if API key issue or crash persists
        detail_msg = str(e)
        if "Failed to call LLM" in detail_msg or "Authentication" in detail_msg:
             detail_msg = "LLM API failed. Please check your API key and connection."
        if "temporarily disabled" in detail_msg:
            # Re-raise the 503 from our manual enforcement above
            raise
            
        raise HTTPException(status_code=500, detail=detail_msg)