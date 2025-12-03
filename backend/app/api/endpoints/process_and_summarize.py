from fastapi import APIRouter, UploadFile, File, HTTPException
from pydantic import BaseModel, Field
from app.services.document_parser import extract_text
from app.services.llm_service import llm_service
from app.services import summarizer2 as summarizer_service
import os
import tempfile
import logging

logger = logging.getLogger(__name__)
router = APIRouter()

class ProcessAndSummarizeRequest(BaseModel):
    num_sentences: int = Field(default=10, ge=10, le=20)
    use_llm: bool = Field(default=True)
    max_length: int = Field(default=500, ge=500, le=1000)

class ProcessAndSummarizeResponse(BaseModel):
    success: bool
    filename: str
    file_type: str
    extracted_text_length: int
    summary: str
    summary_length: int
    message: str

@router.post("/process_and_summarize/", response_model=ProcessAndSummarizeResponse)
async def process_and_summarize(
    file: UploadFile = File(...),
    num_sentences: int = 10,
    use_llm: bool = True,
    max_length: int = 500
):
    """
    Upload a file, extract text, and generate summary in one step.
    """
    try:
        # Validate file type
        filename = file.filename or "unknown"
        file_ext = filename.split(".")[-1].lower() if "." in filename else ""
        
        if file_ext not in ["pdf", "docx", "txt"]:
            raise HTTPException(
                status_code=400,
                detail="Unsupported file type. Allowed: .pdf, .docx, .txt"
            )

        # Read and save file temporarily
        file_content = await file.read()
        
        if len(file_content) > 10 * 1024 * 1024:  # 10MB limit
            raise HTTPException(
                status_code=400,
                detail="File too large. Maximum size is 10MB."
            )

        # Create temporary file
        with tempfile.NamedTemporaryFile(delete=False, suffix=f".{file_ext}") as temp_file:
            temp_file.write(file_content)
            temp_path = temp_file.name

        try:
            # Extract text
            extracted_text = extract_text(temp_path, file_ext)
            
            if not extracted_text or len(extracted_text.strip()) < 100:
                raise HTTPException(
                    status_code=400,
                    detail="Could not extract sufficient text from document (minimum 100 characters required)."
                )

            # Generate summary
            summary = ""
            message_suffix = ""
            
            # Try LLM first if requested and available
            if use_llm and llm_service.is_available():
                try:
                    logger.info("Using LLM for generative summarization.")
                    summary = llm_service.summarize_with_llm(
                        text=extracted_text,
                        max_length=max_length,
                        language="english"
                    )
                    message_suffix = " using LLM"
                except Exception as llm_error:
                    logger.warning(f"LLM summarization failed: {llm_error}. Falling back to local service.")
                    summary = ""

            # Use local service if LLM failed or wasn't requested
            if not summary:
                try:
                    logger.info("Using local transformer-based summarization.")
                    summary = summarizer_service.summarize(
                        text=extracted_text,
                        num_sentences=num_sentences,
                        profession="general reader",
                        purpose="detailed analysis",
                        document_type="auto"
                    )
                    message_suffix = " using local service"
                except Exception as local_error:
                    logger.error(f"Local summarization failed: {local_error}")
                    # Simple fallback
                    sentences = extracted_text.split('. ')[:num_sentences]
                    summary = '. '.join(sentences) + '.'
                    message_suffix = " using simple extraction"

            if not summary or len(summary.strip()) < 10:
                raise HTTPException(
                    status_code=500,
                    detail="Failed to generate meaningful summary."
                )

            return ProcessAndSummarizeResponse(
                success=True,
                filename=filename,
                file_type=file_ext,
                extracted_text_length=len(extracted_text),
                summary=summary.strip(),
                summary_length=len(summary.strip()),
                message=f"File processed and summary generated successfully{message_suffix}"
            )

        finally:
            # Clean up temp file
            if os.path.exists(temp_path):
                os.remove(temp_path)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")