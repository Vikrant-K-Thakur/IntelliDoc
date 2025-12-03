"""
LLM Service for IntelliDoc API
Supports multiple LLM providers (OpenAI, Groq, Gemini)
"""

import os
import logging
import json
from typing import Optional, List, Dict, Any
import google.generativeai as genai
# from groq import Groq
# try:
#     from openai import OpenAI
# except ImportError:
#     OpenAI = None

logger = logging.getLogger(__name__)


class LLMService:
    """
    Unified LLM service for translation, chat, and flashcard generation.
    Supports multiple providers with fallback options.
    """
    
    def __init__(self):
        self.provider = None
        self.client = None
        self.model = None
        self._initialize_provider()
    
    def _initialize_provider(self):
        """Initialize LLM provider based on .env configuration"""
        
        provider_choice = os.getenv("LLM_PROVIDER", "gemini").lower()
        
        # # OpenAI
        # if provider_choice == "openai":
        #     if OpenAI is None:
        #         logger.error("❌ OpenAI package not installed. Run: pip install openai")
        #     else:
        #         openai_key = os.getenv("OPENAI_API_KEY")
        #         if openai_key:
        #             try:
        #                 self.client = OpenAI(api_key=openai_key)
        #                 self.provider = "openai"
        #                 self.model = os.getenv("LLM_MODEL", "gpt-3.5-turbo")
        #                 logger.info(f"✅ OpenAI LLM initialized with model: {self.model}")
        #                 return
        #             except Exception as e:
        #                 logger.error(f"❌ Failed to initialize OpenAI: {e}")
        #         else:
        #             logger.error("❌ OPENAI_API_KEY not found in .env")
        
        # Groq
        if provider_choice == "groq":
            groq_key = os.getenv("GROQ_API_KEY")
            if groq_key:
                try:
                    self.client = Groq(api_key=groq_key)
                    self.provider = "groq"
                    self.model = os.getenv("LLM_MODEL", "llama-3.1-8b-instant")
                    logger.info(f"✅ Groq LLM initialized with model: {self.model}")
                    return
                except ImportError:
                    logger.error("❌ Groq package not installed. Run: pip install groq")
                except Exception as e:
                    logger.error(f"❌ Failed to initialize Groq: {e}")
            else:
                logger.error("❌ GROQ_API_KEY not found in .env")
        
        # Google Gemini
        elif provider_choice == "gemini":
            gemini_key = os.getenv("GOOGLE_API_KEY")
            if gemini_key:
                try:
                    genai.configure(api_key=gemini_key)
                    self.model = os.getenv("LLM_MODEL", "gemini-pro")
                    self.client = genai.GenerativeModel(self.model)
                    
                    self.provider = "gemini"
                    logger.info(f"✅ Gemini LLM initialized with model: {self.model}")
                    return
                except ImportError:
                    logger.error("❌ Google GenAI package not installed. Run: pip install google-generativeai")
                except Exception as e:
                    logger.error(f"❌ Failed to initialize Gemini: {e}")
            else:
                logger.error("❌ GOOGLE_API_KEY not found in .env")
        
        else:
            logger.error(f"❌ Unknown LLM_PROVIDER: {provider_choice}. Use: openai, groq, or gemini")
        
        logger.warning("⚠️ No LLM provider initialized. Check your .env configuration.")
    
    def is_available(self) -> bool:
        """Check if LLM service is available"""
        return self.client is not None and self.provider is not None
    
    def _prepare_messages(self, system_instruction: str, user_prompt: str, history: Optional[List[Dict]] = None) -> List[Dict[str, str]]:
        """Prepares the messages array for chat models (OpenAI/Groq/Gemini)."""
        messages = [{"role": "system", "content": system_instruction}]
        
        if history:
            for entry in history:
                messages.append({"role": "user", "content": entry.get('question', '')})
                # If the answer was structured JSON from a previous LLM call, extract the plain text answer
                answer_content = entry.get('answer', '')
                if answer_content.startswith('{') and answer_content.endswith('}'):
                    try:
                        parsed_answer = json.loads(answer_content).get('answer', answer_content)
                    except json.JSONDecodeError:
                        parsed_answer = answer_content
                else:
                    parsed_answer = answer_content
                
                messages.append({"role": "assistant", "content": parsed_answer})

        messages.append({"role": "user", "content": user_prompt})
        return messages

    def _call_llm(self, system_instruction: str, user_prompt: str, history: Optional[List[Dict]] = None, 
                  temperature: float = 0.7, max_tokens: int = 1000) -> str:
        """
        Internal method to call the LLM provider, handling different APIs.
        """
        if not self.is_available():
            # NOTE: We should not raise ValueError here; the caller (chat.py/flashcards.py) should handle the check
            # but we allow it to proceed for consistency with the original code structure.
            raise ValueError("LLM service not available. Please configure an API key.")
        
        messages = self._prepare_messages(system_instruction, user_prompt, history)
        
        try:
            if self.provider in ["openai", "groq"]:
                response = self.client.chat.completions.create(
                    model=self.model,
                    messages=messages,
                    temperature=temperature,
                    max_tokens=max_tokens
                )
                return response.choices[0].message.content.strip()
            
            elif self.provider == "gemini":
                # Convert messages to Gemini format
                conversation_parts = []
                user_content = ""
                
                for msg in messages:
                    if msg["role"] == "system":
                        # System instruction will be handled separately
                        continue
                    elif msg["role"] == "user":
                        user_content += msg["content"] + "\n"
                    elif msg["role"] == "assistant":
                        conversation_parts.append(f"Assistant: {msg['content']}")
                
                # Combine system instruction with user content
                full_prompt = f"{system_instruction}\n\n{user_content}"
                if conversation_parts:
                    full_prompt = f"{system_instruction}\n\nPrevious conversation:\n" + "\n".join(conversation_parts) + f"\n\nCurrent request:\n{user_content}"
                
                response = self.client.generate_content(full_prompt)
                return response.text.strip()
            
            else:
                raise ValueError(f"Unknown provider: {self.provider}")
        
        except Exception as e:
            # UPDATED LOGGING: Log specific API call failure
            logger.error(f"LLM API CALL FAILED for provider {self.provider}: {type(e).__name__}: {str(e)}")
            
            # For Gemini, provide more specific error handling
            if self.provider == "gemini":
                if "API_KEY" in str(e).upper():
                    logger.error("❌ Gemini API key is invalid or missing")
                elif "QUOTA" in str(e).upper() or "LIMIT" in str(e).upper():
                    logger.error("❌ Gemini API quota exceeded or rate limit hit")
                elif "MODEL" in str(e).upper():
                    logger.error(f"❌ Gemini model '{self.model}' not found or not accessible")
                else:
                    logger.error(f"❌ Gemini API error: {str(e)}")
            
            raise # Re-raise to be caught by flashcards.py/chat.py
    
    # ============= TRANSLATION METHODS =============
    
    def translate_text(self, text: str, target_language: str, source_language: str = "auto") -> str:
        """
        Translate text to target language using LLM.
        """
        system_instruction = f"You are an expert translator. Your sole purpose is to translate the user's text into {target_language}. Do not include any commentary or additional text."
        
        user_prompt = f"""Translate the following text to {target_language}.
Text: "{text}"
Translation:"""
        
        return self._call_llm(system_instruction, user_prompt, temperature=0.3, max_tokens=2000)
    
    # ============= CHAT METHODS (RAG/Q&A) =============
    
    def chat_with_llm(
        self, 
        document_context: str, 
        question: str, 
        language: str = "english",
        conversation_history: Optional[List[Dict]] = None
    ) -> str:
        """
        Answer questions about a document using LLM and return structured JSON output
        (Strategy 3D).
        """
        # SYSTEM INSTRUCTION: MANDATES JSON and provides RAG rules
        system_instruction = f"""You are a helpful and expert document analysis assistant.
Your task is to answer the user's question STRICTLY based on the provided "DOCUMENT CONTEXT".
Be concise and accurate. If the answer cannot be found in the context, your response MUST state that explicitly.
Format your final response as a JSON object with two keys:
1. "answer": The generated answer in {language}.
2. "confidence_score": A self-assessed float score (0.0 to 1.0) indicating your confidence that the answer is fully supported by the document context (1.0 is 100% supported).
DO NOT include any text outside the JSON object."""
        
        # USER PROMPT: Provides all necessary context
        user_prompt = f"""
DOCUMENT CONTEXT:
{document_context[:5000]}

CONVERSATION HISTORY (Last 3 Exchanges):
{json.dumps(conversation_history[-3:]) if conversation_history else "[]"}

CURRENT QUESTION: {question}

Your JSON response (in {language}):"""
        
        # Call the unified LLM method
        return self._call_llm(system_instruction, user_prompt, conversation_history, temperature=0.2, max_tokens=500)
    
    # ============= FLASHCARD METHODS =============
    
    def generate_flashcards_with_llm(
        self,
        text: str,
        num_cards: int = 10,
        card_type: str = "question_answer",
        language: str = "english",
        difficulty: Optional[str] = None
    ) -> List[Dict[str, str]]:
        """
        Generate flashcards from text using LLM.
        """
        
        difficulty_text = f" at {difficulty} difficulty level" if difficulty else ""
        
        system_instruction = "You are a helpful flashcard generation assistant. Your output must be a valid JSON array of flashcard objects."
        prompt = f"""Generate {num_cards} {card_type} flashcards from the following text in {language}{difficulty_text}.

Text:
{text[:2000]}

Create exactly {num_cards} flashcards in JSON format:
[
  {{"question": "...", "answer": "...", "topic": "...", "hint": "..."}},
  ...
]

Only return the JSON array, nothing else."""
        
        response = self._call_llm(system_instruction, prompt, temperature=0.7, max_tokens=2000)
        
        # Parse JSON response
        try:
            # Extract JSON from response
            start_idx = response.find('[')
            end_idx = response.rfind(']') + 1
            if start_idx != -1 and end_idx > start_idx:
                json_str = response[start_idx:end_idx]
                flashcards = json.loads(json_str)
                return flashcards[:num_cards]
            else:
                # Fallback: create simple flashcards
                return self._generate_fallback_flashcards(text, num_cards)
        except Exception as e:
            logger.error(f"Failed to parse flashcards JSON: {e}")
            return self._generate_fallback_flashcards(text, num_cards)
    
    def _generate_fallback_flashcards(self, text: str, num_cards: int) -> List[Dict[str, str]]:
        """Generate simple fallback flashcards when JSON parsing fails"""
        words = text.split()
        flashcards = []
        
        for i in range(min(num_cards, 5)):
            flashcards.append({
                "question": f"What is covered in section {i+1}?",
                "answer": " ".join(words[i*20:(i+1)*20]),
                "topic": f"Section {i+1}",
                "hint": "Review the document content"
            })
        
        return flashcards
    
    # ============= SUMMARIZATION METHODS =============
    
    def summarize_with_llm(
        self,
        text: str,
        max_length: int = 150,
        language: str = "english"
    ) -> str:
        """
        Summarize text using LLM.
        """
        system_instruction = "You are an expert summarizer. Your task is to provide a concise summary of the text provided by the user."
        prompt = f"""Summarize the following text in approximately {max_length} words in {language}.
Be concise and capture the main points.

Text:
{text[:4000]}

Summary:"""
        
        return self._call_llm(system_instruction, prompt, temperature=0.5, max_tokens=max_length * 2)
    
    # ============= UTILITY METHODS =============
    
    def get_info(self) -> Dict[str, Any]:
        """Get information about the LLM service"""
        return {
            "available": self.is_available(),
            "provider": self.provider,
            "model": self.model,
            "capabilities": {
                "translation": True,
                "chat": True,
                "flashcards": True,
                "summarization": True,
                "multilingual": True
            } if self.is_available() else {}
        }


# ============= GLOBAL INSTANCE =============
# Create a singleton instance
llm_service = LLMService()


# ============= CONVENIENCE FUNCTIONS =============
def is_llm_available() -> bool:
    """Quick check if LLM is available"""
    return llm_service.is_available()


def get_llm_info() -> Dict[str, Any]:
    """Get LLM service information"""
    return llm_service.get_info()