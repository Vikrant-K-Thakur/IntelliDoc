import os
import shutil
import uuid
from datetime import datetime
from typing import Optional, Dict
from fastapi import APIRouter, UploadFile, File, HTTPException
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field
from app.services.document_parser import extract_text
import logging

logger = logging.getLogger(__name__)
router = APIRouter()

UPLOAD_DIR = "temp_uploads"
STORAGE_DIR = "document_storage"  # NEW: For storing documents
os.makedirs(UPLOAD_DIR, exist_ok=True)
os.makedirs(STORAGE_DIR, exist_ok=True)

# In-memory document storage (replace with database in production)
documents_db: Dict[str, dict] = {}

# ============= REQUEST/RESPONSE MODELS =============

class DocumentUploadResponse(BaseModel):
    success: bool
    document_id: str
    filename: str
    file_type: str
    file_size_bytes: int
    word_count: int
    character_count: int
    extraction_preview: str  # First 500 chars
    uploaded_at: str
    message: str

class DocumentInfoResponse(BaseModel):
    document_id: str
    filename: str
    file_type: str
    file_size_bytes: int
    word_count: int
    character_count: int
    uploaded_at: str
    text_preview: str

class AllDocumentsResponse(BaseModel):
    success: bool
    total_documents: int
    documents: list

# ============= HELPER FUNCTIONS =============

def save_document_metadata(doc_id: str, filename: str, file_ext: str, 
                          extracted_text: str, file_size: int):
    """Save document metadata to in-memory storage"""
    documents_db[doc_id] = {
        "document_id": doc_id,
        "filename": filename,
        "file_type": file_ext,
        "file_size_bytes": file_size,
        "extracted_text": extracted_text,
        "word_count": len(extracted_text.split()),
        "character_count": len(extracted_text),
        "uploaded_at": datetime.now().isoformat(),
        "storage_path": os.path.join(STORAGE_DIR, f"{doc_id}.txt")
    }
    
    # Save full text to file
    with open(documents_db[doc_id]["storage_path"], "w", encoding="utf-8") as f:
        f.write(extracted_text)
    
    return documents_db[doc_id]

# ============= API ENDPOINTS =============

@router.post("/upload_file/", response_model=DocumentUploadResponse)
async def upload_file(file: UploadFile = File(...)):
    """
    Upload and parse a document file (PDF, DOCX, TXT).
    Returns document ID for future reference.
    """
    try:
        # 1. Validate file type
        filename = file.filename or "unknown"
        file_ext = filename.split(".")[-1].lower() if "." in filename else ""
        
        if file_ext not in ["pdf", "docx", "txt"]:
            raise HTTPException(
                status_code=400, 
                detail="Unsupported file type. Allowed: .pdf, .docx, .txt"
            )

        # 2. Read file content and check size
        file_content = await file.read()
        file_size = len(file_content)
        
        # Limit file size to 10MB
        if file_size > 10 * 1024 * 1024:  # 10MB
            raise HTTPException(
                status_code=400,
                detail="File too large. Maximum size is 10MB."
            )

        # 3. Save file temporarily
        doc_id = str(uuid.uuid4())
        temp_path = os.path.join(UPLOAD_DIR, f"{doc_id}.{file_ext}")
        
        with open(temp_path, "wb") as buffer:
            buffer.write(file_content)

        # 4. Extract text
        try:
            extracted_text = extract_text(temp_path, file_ext)
        except Exception as e:
            os.remove(temp_path)
            logger.error(f"Failed to parse document: {str(e)}")
            raise HTTPException(
                status_code=500, 
                detail=f"Failed to parse document: {str(e)}"
            )

        # 5. Validate extracted text
        if not extracted_text or len(extracted_text.strip()) < 10:
            os.remove(temp_path)
            raise HTTPException(
                status_code=400,
                detail="Could not extract meaningful text from document."
            )

        # 6. Save document metadata
        doc_metadata = save_document_metadata(
            doc_id, filename, file_ext, extracted_text, file_size
        )

        # 7. Clean up temp file
        os.remove(temp_path)

        # 8. Return response
        return DocumentUploadResponse(
            success=True,
            document_id=doc_id,
            filename=filename,
            file_type=file_ext,
            file_size_bytes=file_size,
            word_count=doc_metadata["word_count"],
            character_count=doc_metadata["character_count"],
            extraction_preview=extracted_text[:500] + "..." if len(extracted_text) > 500 else extracted_text,
            uploaded_at=doc_metadata["uploaded_at"],
            message=f"Document '{filename}' uploaded successfully. Use document_id '{doc_id}' for future operations."
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Unexpected error during upload: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Unexpected error: {str(e)}"
        )


@router.get("/documents/", response_model=AllDocumentsResponse)
async def get_all_documents():
    """
    Get list of all uploaded documents with metadata.
    """
    try:
        docs_list = []
        for doc_id, doc_data in documents_db.items():
            docs_list.append({
                "document_id": doc_id,
                "filename": doc_data["filename"],
                "file_type": doc_data["file_type"],
                "file_size_bytes": doc_data["file_size_bytes"],
                "word_count": doc_data["word_count"],
                "uploaded_at": doc_data["uploaded_at"],
                "preview": doc_data["extracted_text"][:200] + "..."
            })
        
        return AllDocumentsResponse(
            success=True,
            total_documents=len(docs_list),
            documents=docs_list
        )
    
    except Exception as e:
        logger.error(f"Error getting documents: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/documents/{document_id}/", response_model=DocumentInfoResponse)
async def get_document_info(document_id: str):
    """
    Get detailed information about a specific document.
    """
    if document_id not in documents_db:
        raise HTTPException(status_code=404, detail="Document not found")
    
    doc = documents_db[document_id]
    
    return DocumentInfoResponse(
        document_id=document_id,
        filename=doc["filename"],
        file_type=doc["file_type"],
        file_size_bytes=doc["file_size_bytes"],
        word_count=doc["word_count"],
        character_count=doc["character_count"],
        uploaded_at=doc["uploaded_at"],
        text_preview=doc["extracted_text"][:1000] + "..."
    )


@router.get("/documents/{document_id}/full_text/")
async def get_document_full_text(document_id: str):
    """
    Get the full extracted text of a document.
    WARNING: Can be very large!
    """
    if document_id not in documents_db:
        raise HTTPException(status_code=404, detail="Document not found")
    
    doc = documents_db[document_id]
    
    # Read from stored file
    try:
        with open(doc["storage_path"], "r", encoding="utf-8") as f:
            full_text = f.read()
        
        return {
            "success": True,
            "document_id": document_id,
            "filename": doc["filename"],
            "full_text": full_text,
            "word_count": doc["word_count"]
        }
    except Exception as e:
        logger.error(f"Error reading document file: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to read document")


@router.delete("/documents/{document_id}/")
async def delete_document(document_id: str):
    """
    Delete a document and its stored data.
    """
    if document_id not in documents_db:
        raise HTTPException(status_code=404, detail="Document not found")
    
    doc = documents_db[document_id]
    
    # Delete stored file
    try:
        if os.path.exists(doc["storage_path"]):
            os.remove(doc["storage_path"])
    except Exception as e:
        logger.warning(f"Could not delete file: {str(e)}")
    
    # Remove from database
    del documents_db[document_id]
    
    return {
        "success": True,
        "message": f"Document '{doc['filename']}' deleted successfully",
        "document_id": document_id
    }


@router.get("/documents/stats/")
async def get_document_stats():
    """
    Get statistics about uploaded documents.
    """
    if not documents_db:
        return {
            "total_documents": 0,
            "total_size_bytes": 0,
            "total_words": 0,
            "file_types": {}
        }
    
    total_size = sum(doc["file_size_bytes"] for doc in documents_db.values())
    total_words = sum(doc["word_count"] for doc in documents_db.values())
    
    file_types = {}
    for doc in documents_db.values():
        ft = doc["file_type"]
        file_types[ft] = file_types.get(ft, 0) + 1
    
    return {
        "total_documents": len(documents_db),
        "total_size_bytes": total_size,
        "total_size_mb": round(total_size / (1024 * 1024), 2),
        "total_words": total_words,
        "file_types": file_types,
        "average_document_size": round(total_size / len(documents_db)) if documents_db else 0
    }