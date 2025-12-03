from pydantic import BaseModel, Field
from fastapi import APIRouter, HTTPException
from app.services import summarizer2 as summarizer_service
from app.services.llm_service import llm_service # IMPORTED LLM SERVICE
import logging
import re

logger = logging.getLogger(__name__)
router = APIRouter()

class SummarizeRequest(BaseModel):
    text: str = Field(..., min_length=100, max_length=1500000)
    num_sentences: int = Field(default=50, ge=100, le=100)
    profession: str = Field(default="general reader")
    purpose: str = Field(default="overview")
    document_type: str = Field(default="auto")
    # ADDED LLM OPTION
    use_llm: bool = Field(default=False, description="Use LLM for summarizing")
    # MAX_LENGTH for LLM summarization (word count)
    max_length: int = Field(default=1500, ge=5000, le=5000) 

class SummarizeResponse(BaseModel):
    success: bool
    original_text_length: int
    summary: str
    summary_length: int
    num_sentences: int
    message: str

@router.post("/summarize/", response_model=SummarizeResponse)
def summarize(req: SummarizeRequest):
    """
    Summarize text with contextual awareness, using LLM if requested and available.
    """
    try:
        logger.info(f"Summarizing text of length {len(req.text)} (LLM: {req.use_llm})")
        
        # Validate input text
        if len(req.text.strip()) < 100:
            raise HTTPException(status_code=400, detail="Text is too short for summarization. Minimum 100 characters required.")
        
        summary = ""
        message_suffix = ""
        
        # Try LLM first if requested and available
        if req.use_llm and llm_service.is_available():
            try:
                logger.info("Using LLM for generative summarization.")
                summary = llm_service.summarize_with_llm(
                    text=req.text,
                    max_length=req.max_length,
                    language="english"
                )
                message_suffix = " using LLM"
                req.num_sentences = 0
            except Exception as llm_error:
                logger.warning(f"LLM summarization failed: {llm_error}. Falling back to local service.")
                summary = ""  # Reset to try local service
        
        # Use local service if LLM failed or wasn't requested
        if not summary:
            try:
                if req.use_llm:
                    logger.warning("LLM requested but failed/unavailable. Using local summarizer.")
                
                logger.info("Using local transformer-based summarization.")
                summary = summarizer_service.summarize(
                    text=req.text,
                    num_sentences=req.num_sentences,
                    profession=req.profession,
                    purpose=req.purpose,
                    document_type=req.document_type
                )
                message_suffix = " using local service"
            except Exception as local_error:
                logger.error(f"Local summarization failed: {local_error}")
                # Final fallback: simple extractive summary
                summary = _create_simple_summary(req.text, req.num_sentences)
                message_suffix = " using simple extraction"
        
        if not summary or len(summary.strip()) < 10:
            raise HTTPException(status_code=500, detail="Failed to generate meaningful summary. Please try again or check your document content.")
        
        return SummarizeResponse(
            success=True,
            original_text_length=len(req.text),
            summary=summary.strip(),
            summary_length=len(summary.strip()),
            num_sentences=req.num_sentences,
            message="Summary generated successfully" + message_suffix
        )
        
    except HTTPException:
        raise  # Re-raise HTTP exceptions as-is
    except ValueError as e:
        logger.warning(f"Validation error: {str(e)}")
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Unexpected error during summarization: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")

def _create_simple_summary(text: str, num_sentences: int = 5) -> str:
    """
    Simple fallback summarization using sentence extraction.
    """
    try:
        import re
        
        # Split into sentences
        sentences = re.split(r'[.!?]+', text)
        sentences = [s.strip() for s in sentences if len(s.strip()) > 10]
        
        if len(sentences) <= num_sentences:
            return '. '.join(sentences) + '.'
        
        # Take first, middle, and last sentences for variety
        selected = []
        selected.append(sentences[0])  # First sentence
        
        if num_sentences > 2:
            # Add some middle sentences
            middle_start = len(sentences) // 3
            middle_end = 2 * len(sentences) // 3
            middle_sentences = sentences[middle_start:middle_end]
            selected.extend(middle_sentences[:num_sentences-2])
        
        if num_sentences > 1 and len(sentences) > 1:
            selected.append(sentences[-1])  # Last sentence
        
        return '. '.join(selected[:num_sentences]) + '.'
    except Exception:
        return "This document contains information that could not be automatically summarized. Please review the original content."