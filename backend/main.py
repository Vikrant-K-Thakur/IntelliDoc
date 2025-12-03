from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

app = FastAPI(title="IntelliDoc API")

# Configure CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Import endpoints
# NOTE: Added 'chat' router here
from app.api.endpoints import documents, flashcards, summarize, chat, process_and_summarize 

# Include Routers with the consistent '/api' prefix
app.include_router(documents.router, prefix="/api", tags=["Documents"])
app.include_router(flashcards.router, prefix="/api", tags=["Flashcards"])
app.include_router(summarize.router, prefix="/api", tags=["Summarize"])

# Include the new chat router. 
# The endpoints in chat.py start with /chat/, so the final path will be /api/chat/...
app.include_router(chat.router, prefix="/api", tags=["Document Chat"])
app.include_router(process_and_summarize.router, prefix="/api", tags=["Process and Summarize"])

@app.get("/")
def root():
    return {"message": "IntelliDoc API", "status": "running"}

if __name__ == "__main__":
    import uvicorn
    # Use the correct module path for uvicorn run
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)