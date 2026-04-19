import httpx
import base64
import json
import logging
from app.core.config import settings

logger = logging.getLogger(__name__)

async def analyze_ticket_with_gemini(file_content: bytes, mime_type: str) -> dict:
    """
    Analyzes a ticket image or PDF using OpenRouter (Gemini Flash 1.5 Free) and returns structured JSON data.
    """
    try:
        # Fix incomplete mime types for images
        if mime_type == 'image':
            mime_type = 'image/jpeg'
            
        if not settings.OPENROUTER_API_KEY:
            logger.error("OPENROUTER_API_KEY is not set")
            return {"error": "API Key is missing"}

        # Encode file to base64
        base64_content = base64.b64encode(file_content).decode('utf-8')
        
        # Multi-modal prompt in English for better extraction quality
        prompt = """
        Analyze this flight ticket image or PDF and extract the following information. 
        Return ONLY a raw JSON object with these exact keys:
        {
          "pnr": "PNR code (look for 6 characters alphanumeric code)",
          "airline": "Airline name (look for brand names, logos, or header text)",
          "flight_no": "Flight number (e.g., TK1234, LH456)",
          "departure": "Origin city/code",
          "arrival": "Destination city/code",
          "date": "Flight date (format: YYYY-MM-DD)",
          "departure_time": "Time of departure",
          "arrival_time": "Time of arrival",
          "status": "Ticket status",
          "passenger": "Passenger details"
        }
        
        IMPORTANT: If a value is missing, use an empty string. Return ONLY the JSON object. No explanations.
        """

        headers = {
            "Authorization": f"Bearer {settings.OPENROUTER_API_KEY}",
            "HTTP-Referer": "https://assistia.ai",
            "X-Title": "AssistiaAI",
            "Content-Type": "application/json"
        }

        payload = {
            "model": "google/gemini-2.0-flash-001",
            "messages": [
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "text",
                            "text": prompt
                        },
                        {
                            "type": "image_url",
                            "image_url": {
                                "url": f"data:{mime_type};base64,{base64_content}"
                            }
                        }
                    ]
                }
            ],
            "response_format": {"type": "json_object"} # Force JSON if supported
        }

        async with httpx.AsyncClient(timeout=60.0) as client:
            response = await client.post(
                "https://openrouter.ai/api/v1/chat/completions",
                headers=headers,
                json=payload
            )
            
            if response.status_code != 200:
                logger.error(f"OpenRouter Error: {response.status_code} - {response.text}")
                return {"error": f"API Error: {response.status_code}"}

            result = response.json()
            content = result['choices'][0]['message']['content']
            
            # Clean potential markdown formatting
            clean_json = content.replace('```json', '').replace('```', '').strip()
            
            try:
                data = json.loads(clean_json)
                return data
            except json.JSONDecodeError as e:
                logger.error(f"JSON parsing error: {e}, Content: {content}")
                return {"error": "JSON parsing error", "content": content}

    except Exception as e:
        logger.error(f"OpenRouter Analysis Error: {str(e)}")
        raise e

async def analyze_bus_ticket_with_gemini(file_content: bytes, mime_type: str) -> dict:
    """
    Analyzes a bus ticket image or PDF using OpenRouter (Gemini Flash) and returns structured JSON data.
    """
    try:
        if mime_type == 'image':
            mime_type = 'image/jpeg'
            
        if not settings.OPENROUTER_API_KEY:
            logger.error("OPENROUTER_API_KEY is not set")
            return {"error": "API Key is missing"}

        base64_content = base64.b64encode(file_content).decode('utf-8')
        
        prompt = """
        Analyze this bus ticket image or PDF and extract the following information. 
        Return ONLY a raw JSON object with these exact keys:
        {
          "pnr": "PNR code or Ticket Number",
          "bus_company": "Bus company name (e.g., Kamil Koç, Metro, Pamukkale)",
          "trip_no": "Trip or Bus number if any",
          "departure": "Origin city or terminal",
          "arrival": "Destination city or terminal",
          "date": "Date of trip (format: YYYY-MM-DD)",
          "departure_time": "Time of departure (e.g. 14:30)",
          "arrival_time": "Time of arrival if available",
          "seat_number": "Seat number(s)",
          "status": "Ticket status (confirmed, cancelled, etc.)",
          "passenger": "Passenger name(s)"
        }
        
        IMPORTANT: If a value is missing or not visible, use an empty string. Return ONLY the JSON object. No markdown, no explanations.
        """

        headers = {
            "Authorization": f"Bearer {settings.OPENROUTER_API_KEY}",
            "HTTP-Referer": "https://assistia.ai",
            "X-Title": "AssistiaAI",
            "Content-Type": "application/json"
        }

        payload = {
            "model": "google/gemini-2.0-flash-001",
            "messages": [
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "text",
                            "text": prompt
                        },
                        {
                            "type": "image_url",
                            "image_url": {
                                "url": f"data:{mime_type};base64,{base64_content}"
                            }
                        }
                    ]
                }
            ],
            "response_format": {"type": "json_object"}
        }

        async with httpx.AsyncClient(timeout=60.0) as client:
            response = await client.post(
                "https://openrouter.ai/api/v1/chat/completions",
                headers=headers,
                json=payload
            )
            
            if response.status_code != 200:
                logger.error(f"OpenRouter Error: {response.status_code} - {response.text}")
                return {"error": f"API Error: {response.status_code}"}

            result = response.json()
            content = result['choices'][0]['message']['content']
            
            clean_json = content.replace('```json', '').replace('```', '').strip()
            
            try:
                data = json.loads(clean_json)
                return data
            except json.JSONDecodeError as e:
                logger.error(f"JSON parsing error: {e}, Content: {content}")
                return {"error": "JSON parsing error", "content": content}

    except Exception as e:
        logger.error(f"OpenRouter Analysis Error: {str(e)}")
        raise e
