
To run - uvicorn main:app --reload


Upload a file (PDF, DOCX, TXT)
POST → http://127.0.0.1:8000/api/upload_file/
Go to Body → form-data
Key = file, Type = File, Value = (choose a PDF/DOCX/TXT file)


Summarize text
POST → http://127.0.0.1:8000/api/summarize/
Go to Body → raw → JSON and paste:
{
  "text": "Your extracted text or any long text here...",
  "num_sentences": 5
}


Generate Flashcards
POST → http://127.0.0.1:8000/api/flashcards/
Go to Body → raw → JSON and paste:
{
  "text": "Your extracted document text here..."
}

