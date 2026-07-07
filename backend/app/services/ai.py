import base64
import json
import logging
import os
import uuid
from datetime import date, timedelta
from typing import Dict, List, Any, Optional
import httpx
from fastapi import HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.repositories.food import FoodLogEntryRepository
from app.repositories.water import WaterLogRepository
from app.repositories.exercise import ExerciseLogRepository
from app.repositories.weight import WeightEntryRepository
from app.repositories.goal import GoalRepository
from app.schemas.ai import ChatMessage

logger = logging.getLogger("nutritrack.ai_service")

# Registry of known-valid Gemini model identifiers.
# Any model stored in DB or .env is validated against this set;
# an unrecognised name is auto-corrected to the safe default.
VALID_GEMINI_MODELS = {
    "gemini-2.0-flash",
    "gemini-2.5-flash",
    "gemini-2.5-pro",
    "gemini-1.5-flash",
    "gemini-1.5-pro",
    "gemini-pro",
}
# Safe default used when the configured model name is invalid.
SAFE_DEFAULT_MODEL = "gemini-2.0-flash"

# Ordered fallback chain for Gemini vision calls.
# The configured model is prepended at runtime, so this list is only
# consulted when the primary model fails.
GEMINI_VISION_FALLBACKS = ["gemini-2.0-flash", "gemini-2.5-flash", "gemini-1.5-flash"]

# Claude models that support vision (image input).
CLAUDE_VISION_MODELS = {
    "claude-3-5-sonnet-20241022",
    "claude-3-5-haiku-20241022",
    "claude-3-opus-20240229",
    "claude-opus-4-5",
    "claude-sonnet-4-5",
}

class AIService:
    def __init__(self, db: AsyncSession):
        self.db = db
        # Initial defaults loaded from settings (can be overridden dynamically by database)
        self.provider = "gemini"
        raw_key = settings.GEMINI_API_KEY
        if raw_key == "your-gemini-api-key-here" or not raw_key:
            self.api_key = None
        else:
            self.api_key = raw_key
        self.model = settings.GEMINI_MODEL

    async def _load_settings(self) -> None:
        """
        Dynamically load AI settings from the database (app_settings table)
        and fall back to config settings if not present or database fails.
        """
        self.provider = "gemini"
        raw_key = settings.GEMINI_API_KEY
        self.api_key = None if (raw_key == "your-gemini-api-key-here" or not raw_key) else raw_key
        # Validate the configured model name and fall back to safe default if unknown
        configured_model = settings.GEMINI_MODEL
        self.model = configured_model if configured_model in VALID_GEMINI_MODELS else SAFE_DEFAULT_MODEL
        if self.model != configured_model:
            logger.warning(
                f"Configured GEMINI_MODEL '{configured_model}' is not in VALID_GEMINI_MODELS. "
                f"Auto-corrected to '{self.model}'."
            )

        if self.db is None:
            return

        try:
            from app.models.app_settings import AppSettings
            from sqlalchemy import select
            
            stmt = select(AppSettings).where(AppSettings.id == "active_settings")
            result = await self.db.execute(stmt)
            db_settings = result.scalars().first()

            if db_settings:
                self.provider = db_settings.ai_provider
                if self.provider == "claude":
                    self.model = db_settings.claude_model or "claude-3-5-sonnet-20241022"
                    self.api_key = db_settings.claude_api_key or os.getenv("CLAUDE_API_KEY") or None
                else:
                    # Validate DB-stored model name
                    db_model = db_settings.gemini_model or SAFE_DEFAULT_MODEL
                    self.model = db_model if db_model in VALID_GEMINI_MODELS else SAFE_DEFAULT_MODEL
                    if self.model != db_model:
                        logger.warning(
                            f"DB gemini_model '{db_model}' is invalid. Auto-corrected to '{self.model}'."
                        )
                    self.api_key = db_settings.gemini_api_key or raw_key or None
        except Exception as e:
            logger.error(f"Failed to load dynamic settings from database: {e}. Using .env config values.")

    def _clean_json(self, raw_text: str) -> str:
        """Strip markdown codeblock wrappers and clean JSON string from AI model output."""
        cleaned = raw_text.strip()
        if cleaned.startswith("```json"):
            cleaned = cleaned[7:]
        elif cleaned.startswith("```"):
            cleaned = cleaned[3:]
        if cleaned.endswith("```"):
            cleaned = cleaned[:-3]
        cleaned = cleaned.strip()

        # Find first '{' and last '}'
        start_idx = cleaned.find("{")
        end_idx = cleaned.rfind("}")
        if start_idx != -1 and end_idx != -1:
            cleaned = cleaned[start_idx:end_idx + 1]

        # Clean trailing commas before closing braces/brackets
        import re
        cleaned = re.sub(r',\s*([\]}])', r'\1', cleaned)
        return cleaned

    async def _call_llm(
        self,
        messages: List[Dict[str, Any]],
        response_format: Optional[Dict[str, Any]] = None,
        max_tokens: Optional[int] = 2000
    ) -> str:
        """Route request to active provider (Gemini or Claude) based on database settings."""
        await self._load_settings()

        if self.provider == "claude":
            return await self._call_claude(messages, max_tokens)
        else:
            return await self._call_gemini(messages, response_format, max_tokens)

    async def _call_claude(
        self,
        messages: List[Dict[str, Any]],
        max_tokens: Optional[int] = 2000
    ) -> str:
        """Helper to invoke Claude API via Anthropic Messages endpoint."""
        if not self.api_key:
            raise ValueError("CLAUDE_API_KEY is not configured.")

        url = "https://api.anthropic.com/v1/messages"
        
        # Convert system and user messages into Anthropic structure
        system_prompt = ""
        claude_messages = []

        for msg in messages:
            role = msg.get("role")
            content = msg.get("content")

            if role == "system":
                system_prompt = content
            elif role in ("user", "assistant"):
                # Map role labels: assistant in OpenAI/Gemini is assistant in Claude
                claude_role = "assistant" if role == "assistant" else "user"
                
                parts = []
                if isinstance(content, str):
                    parts.append({"type": "text", "text": content})
                elif isinstance(content, list):
                    for part in content:
                        part_type = part.get("type")
                        if part_type == "text":
                            parts.append({"type": "text", "text": part.get("text")})
                        elif part_type == "image_url":
                            url_val = part.get("image_url", {}).get("url", "")
                            if url_val.startswith("data:"):
                                header_part, base64_data = url_val.split(",", 1)
                                mime_type = header_part.split(";")[0].split(":")[1]
                                parts.append({
                                    "type": "image",
                                    "source": {
                                        "type": "base64",
                                        "media_type": mime_type,
                                        "data": base64_data
                                    }
                                })
                            else:
                                parts.append({"type": "text", "text": f"[Image URL: {url_val}]"})
                
                claude_messages.append({
                    "role": claude_role,
                    "content": parts
                })

        payload = {
            "model": self.model,
            "max_tokens": max_tokens,
            "messages": claude_messages
        }
        if system_prompt:
            payload["system"] = system_prompt

        headers = {
            "x-api-key": self.api_key,
            "anthropic-version": "2023-06-01",
            "content-type": "application/json"
        }

        async with httpx.AsyncClient(timeout=60.0) as client:
            response = await client.post(url, headers=headers, json=payload)
            if response.status_code == 429:
                logger.warning(f"Claude API returned rate limit error (429): {response.text}")
                raise HTTPException(
                    status_code=429,
                    detail="Claude API rate limit exceeded. Please try again in a few moments."
                )
            elif response.status_code != 200:
                logger.error(f"Claude API returned error status {response.status_code}: {response.text}")
                raise HTTPException(
                    status_code=502,
                    detail=f"Claude Service communication error: {response.text}"
                )

            res_json = response.json()
            content_list = res_json.get("content", [])
            if not content_list:
                raise ValueError("Claude API returned empty response content.")
            
            return content_list[0].get("text", "")

    async def _call_gemini(
        self,
        messages: List[Dict[str, Any]],
        response_format: Optional[Dict[str, Any]] = None,
        max_tokens: Optional[int] = 2000
    ) -> str:
        """Helper to invoke direct Google Gemini API via native generateContent endpoint."""
        if not self.api_key:
            raise ValueError("GEMINI_API_KEY is not configured.")

        selected_model = self.model
        url = f"https://generativelanguage.googleapis.com/v1beta/models/{selected_model}:generateContent"
        
        # Convert OpenAI messages to Gemini native format
        contents = []
        system_instruction_text = None

        for msg in messages:
            role = msg.get("role")
            content = msg.get("content")

            if role == "system":
                system_instruction_text = content
            elif role == "user":
                parts = []
                if isinstance(content, str):
                    parts.append({"text": content})
                elif isinstance(content, list):
                    for part in content:
                        part_type = part.get("type")
                        if part_type == "text":
                            parts.append({"text": part.get("text")})
                        elif part_type == "image_url":
                            url_val = part.get("image_url", {}).get("url", "")
                            if url_val.startswith("data:"):
                                header_part, base64_data = url_val.split(",", 1)
                                mime_type = header_part.split(";")[0].split(":")[1]
                                parts.append({
                                    "inlineData": {
                                        "mimeType": mime_type,
                                        "data": base64_data
                                    }
                                })
                            else:
                                parts.append({"text": url_val})
                contents.append({
                    "role": "user",
                    "parts": parts
                })

        payload = {
            "contents": contents
        }
        if system_instruction_text:
            payload["systemInstruction"] = {
                "parts": [
                    {"text": system_instruction_text}
                ]
            }

        generation_config = {}
        if response_format is not None and response_format.get("type") == "json_object":
            generation_config["responseMimeType"] = "application/json"
        if max_tokens is not None:
            generation_config["maxOutputTokens"] = max_tokens

        if generation_config:
            payload["generationConfig"] = generation_config

        headers = {
            "Content-Type": "application/json",
            "x-goog-api-key": self.api_key
        }

        async with httpx.AsyncClient(timeout=60.0) as client:
            response = None
            last_error = None
            
            # Try up to 5 times with exponential backoff for transient errors
            # (extra attempts to allow one fallback-model retry after switching)
            for attempt in range(1, 6):
                try:
                    logger.info(f"Invoking Gemini model {selected_model} (Attempt {attempt})...")
                    response = await client.post(url, headers=headers, json=payload)
                    
                    if response.status_code == 200:
                        break  # Success!
                    
                    logger.warning(f"Gemini API returned status {response.status_code} for model {selected_model} on attempt {attempt}.")
                    
                    # If it's a rate limit (429) or transient server issue (5xx), wait and retry
                    if response.status_code in (429, 500, 502, 503, 504):
                        import asyncio
                        # Switch to fallback model on first 5xx/429 if we haven't already
                        if selected_model != "gemini-2.5-flash":
                            logger.warning("Switching to fallback model gemini-2.5-flash due to server error...")
                            selected_model = "gemini-2.5-flash"
                            url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent"
                        await asyncio.sleep(1.0 * min(attempt, 3))
                        continue
                    
                    # If it's a 4xx error (other than 429) and we are not already using gemini-2.5-flash, fall back immediately
                    if selected_model != "gemini-2.5-flash":
                        logger.warning("Attempting immediate fallback to gemini-2.5-flash due to 4xx error...")
                        selected_model = "gemini-2.5-flash"
                        url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent"
                        continue
                    
                    # Already on fallback model and still getting 4xx, stop retrying
                    break
                        
                except Exception as e:
                    logger.error(f"Gemini connection error on attempt {attempt}: {e}")
                    last_error = str(e)
                    import asyncio
                    await asyncio.sleep(1.0 * min(attempt, 3))
                    continue

            # If response is still null after retries
            if response is None:
                raise HTTPException(
                    status_code=502,
                    detail=f"AI Service connection failed after multiple retries. Error: {last_error}"
                )

            if response.status_code == 429:
                logger.warning(f"Gemini API returned quota error (429) after retries: {response.text}")
                raise HTTPException(
                    status_code=429,
                    detail="AI scan quota exceeded. Please try again in a few moments."
                )
            elif response.status_code != 200:
                logger.error(f"Gemini API returned error status {response.status_code} after retries: {response.text}")
                raise HTTPException(
                    status_code=502,
                    detail=f"AI Service communication error: {response.text}"
                )
            
            res_json = response.json()
            
            if "error" in res_json:
                error_msg = res_json["error"].get("message", str(res_json["error"]))
                logger.error(f"Gemini API returned error: {error_msg}")
                raise HTTPException(status_code=502, detail=f"AI Error: {error_msg}")

            candidates = res_json.get("candidates", [])
            if not candidates:
                raise ValueError("AI Service returned empty response candidates.")
                
            parts = candidates[0].get("content", {}).get("parts", [])
            if not parts:
                raise ValueError("AI Service returned content with no parts.")
                
            return parts[0].get("text", "")

    async def parse_voice_log(self, transcript: str) -> Dict[str, Any]:
        """
        Parse text description or voice transcript of food consumed into structured log items
        using a fast, cost-free regex parser, and enrich items using database food lookups.
        """
        import re
        from sqlalchemy import select
        from app.models.food import FoodItem

        # Convert text to lowercase
        text = transcript.lower().strip()
        
        # Map number words to digits
        num_words = {
            "one": 1, "two": 2, "three": 3, "four": 4, "five": 5,
            "six": 6, "seven": 7, "eight": 8, "nine": 9, "ten": 10,
            "a": 1, "an": 1
        }
        
        # Common units mapping
        units = ["g", "gram", "grams", "ml", "ml.", "millilitres", "cup", "cups", "slice", "slices", "piece", "pieces", "glass", "glasses", "spoon", "spoons", "tbsp", "tsp", "plate", "plates", "bowl", "bowls"]
        
        # Split transcript by splitters: "and", "with", ",", "plus", ";"
        segments = re.split(r'\band\b|\bwith\b|\bplus\b|,|;', text)
        
        parsed_items = []
        current_meal = "breakfast" # default
        
        # Check if there is an overall meal type mentioned in the transcript
        if "breakfast" in text:
            current_meal = "breakfast"
        elif "lunch" in text:
            current_meal = "lunch"
        elif "dinner" in text:
            current_meal = "dinner"
        elif "snack" in text or "snacks" in text:
            current_meal = "snacks"
            
        for segment in segments:
            segment = segment.strip()
            if not segment:
                continue
                
            # Remove meal type words from segment to avoid confusing food name
            segment_clean = re.sub(r'\b(breakfast|lunch|dinner|snack|snacks)\b', '', segment).strip()
            if not segment_clean:
                continue
                
            quantity = 1.0
            unit = "piece"
            food_name = segment_clean
            
            # Extract quantity and unit
            match_digit_unit = re.search(r'(\d+(?:\.\d+)?)\s*([a-zA-Z]+)', segment_clean)
            match_digit_only = re.search(r'\b(\d+(?:\.\d+)?)\b', segment_clean)
            
            # If there's a word number:
            word_num_pattern = r'\b(' + '|'.join(num_words.keys()) + r')\b'
            match_word_num = re.search(word_num_pattern, segment_clean)
            
            matched = False
            if match_digit_unit:
                val = float(match_digit_unit.group(1))
                u = match_digit_unit.group(2).strip().lower()
                matched_unit = None
                for ku in units:
                    if u == ku or u.startswith(ku) or ku.startswith(u):
                        matched_unit = ku
                        break
                if matched_unit:
                    quantity = val
                    unit = matched_unit
                    food_name = segment_clean.replace(match_digit_unit.group(0), "").replace(" of ", " ").strip()
                    matched = True
            
            if not matched and match_digit_only:
                val = float(match_digit_only.group(1))
                quantity = val
                unit = "piece"
                food_name = segment_clean.replace(match_digit_only.group(0), "").strip()
                matched = True
                
            if not matched and match_word_num:
                word = match_word_num.group(1)
                val = num_words[word]
                quantity = val
                remaining = segment_clean.replace(word, "", 1).strip()
                match_next_word = re.match(r'^([a-zA-Z]+)', remaining)
                if match_next_word:
                    u = match_next_word.group(1).lower()
                    matched_unit = None
                    for ku in units:
                        if u == ku or u.startswith(ku) or ku.startswith(u):
                            matched_unit = ku
                            break
                    if matched_unit:
                        unit = matched_unit
                        food_name = remaining.replace(match_next_word.group(0), "", 1).replace(" of ", " ").strip()
                    else:
                        unit = "piece"
                        food_name = remaining.strip()
                else:
                    unit = "piece"
                    food_name = remaining
                matched = True
                
            # Clean up food name
            food_name = re.sub(r'^[:\-–—\s]+|[:\-–—\s]+$', '', food_name).strip()
            
            if not food_name or len(food_name) < 2:
                continue
                
            # Map unit & quantity to weight
            unit_weight_map = {
                "g": 1.0, "gram": 1.0, "grams": 1.0,
                "ml": 1.0, "millilitres": 1.0,
                "cup": 200.0, "cups": 200.0,
                "slice": 30.0, "slices": 30.0,
                "glass": 250.0, "glasses": 250.0,
                "spoon": 15.0, "spoons": 15.0,
                "tbsp": 15.0, "tsp": 5.0,
                "plate": 300.0, "plates": 300.0,
                "bowl": 250.0, "bowls": 250.0,
                "piece": 100.0, "pieces": 100.0
            }
            
            if "egg" in food_name:
                gram_weight = quantity * 50.0
            elif "banana" in food_name:
                gram_weight = quantity * 120.0
            elif "apple" in food_name:
                gram_weight = quantity * 150.0
            elif "roti" in food_name or "chapati" in food_name:
                gram_weight = quantity * 40.0
            else:
                base_weight = unit_weight_map.get(unit, 100.0)
                gram_weight = quantity * base_weight
                
            # Query local DB for matching food item
            stmt = select(FoodItem).where(FoodItem.name.ilike(f"%{food_name}%"))
            result = await self.db.execute(stmt)
            db_food = result.scalars().first()
            
            if db_food:
                cals = db_food.calories_per_100g
                carbs = db_food.carbs_per_100g
                protein = db_food.protein_per_100g
                fat = db_food.fat_per_100g
                confidence = "high"
                display_name = db_food.name
            else:
                cals = 120.0
                carbs = 15.0
                protein = 2.0
                fat = 3.0
                confidence = "medium"
                display_name = food_name.title()
                
            parsed_items.append({
                "food_name": display_name,
                "quantity_g": gram_weight,
                "unit_used": unit,
                "meal_type": current_meal,
                "confidence": confidence,
                "calories_per_100g": cals,
                "carbs_per_100g": carbs,
                "protein_per_100g": protein,
                "fat_per_100g": fat
            })
            
        return {"items": parsed_items, "unparsed_text": None}

    def _repair_json(self, raw_text: str) -> Optional[Dict[str, Any]]:
        """
        Multi-strategy JSON repair:
        1. Standard clean + parse
        2. Regex-extract the items array and reconstruct a valid envelope
        3. Return None if all strategies fail
        """
        import re

        # Strategy 1: clean and parse normally
        try:
            cleaned = self._clean_json(raw_text)
            return json.loads(cleaned)
        except (json.JSONDecodeError, ValueError):
            pass

        # Strategy 2: extract items array directly in case the outer envelope is malformed
        try:
            items_match = re.search(r'"items"\s*:\s*(\[.*?\])', raw_text, re.DOTALL)
            if items_match:
                items_json = items_match.group(1)
                # Remove trailing commas inside item objects
                items_json = re.sub(r',\s*([\]}])', r'\1', items_json)
                items = json.loads(items_json)
                # Reconstruct minimal valid envelope
                total_cal = sum(
                    (item.get("calories_per_100g", 0) * item.get("estimated_grams", 0) / 100.0)
                    for item in items
                )
                desc_match = re.search(r'"meal_description"\s*:\s*"([^"]+)"', raw_text)
                return {
                    "items": items,
                    "total_estimated_calories": round(total_cal, 1),
                    "overall_confidence": "medium",
                    "meal_description": desc_match.group(1) if desc_match else "Meal detected from photo."
                }
        except (json.JSONDecodeError, ValueError):
            pass

        return None

    async def _call_gemini_vision(
        self,
        image_bytes: bytes,
        mime_type: str,
        system_prompt: str,
        user_text: str,
        preferred_model: Optional[str] = None,
    ) -> str:
        """
        Dedicated Gemini vision call.
        Uses `preferred_model` (the dynamically configured model) as the first
        attempt, then falls back through GEMINI_VISION_FALLBACKS if it fails.
        This ensures the admin-panel model selection is always honoured.
        """
        if not self.api_key:
            raise ValueError("GEMINI_API_KEY is not configured.")

        base64_image = base64.b64encode(image_bytes).decode("utf-8")

        payload = {
            "systemInstruction": {
                "parts": [{"text": system_prompt}]
            },
            "contents": [
                {
                    "role": "user",
                    "parts": [
                        {"text": user_text},
                        {
                            "inlineData": {
                                "mimeType": mime_type,
                                "data": base64_image
                            }
                        }
                    ]
                }
            ],
            "generationConfig": {
                "responseMimeType": "application/json",
                "maxOutputTokens": 4096,
                "temperature": 0.2,
            }
        }

        headers = {
            "Content-Type": "application/json",
            "x-goog-api-key": self.api_key
        }

        # Build fallback chain: configured model first, then known-good fallbacks
        # (deduplicated while preserving order)
        chain: List[str] = []
        if preferred_model and preferred_model in VALID_GEMINI_MODELS:
            chain.append(preferred_model)
        for m in GEMINI_VISION_FALLBACKS:
            if m not in chain:
                chain.append(m)

        import asyncio
        last_error = None

        async with httpx.AsyncClient(timeout=90.0) as client:
            for model_name in chain:
                current_url = (
                    f"https://generativelanguage.googleapis.com/v1beta/"
                    f"models/{model_name}:generateContent"
                )
                for retry in range(1, 4):
                    try:
                        logger.info(
                            f"Gemini vision scan: model={model_name}, retry={retry}"
                        )
                        response = await client.post(
                            current_url, headers=headers, json=payload
                        )

                        if response.status_code == 200:
                            res_json = response.json()
                            if "error" in res_json:
                                err_msg = res_json["error"].get(
                                    "message", str(res_json["error"])
                                )
                                logger.error(
                                    f"Gemini vision body error on {model_name}: {err_msg}"
                                )
                                last_error = err_msg
                                break  # try next model
                            candidates = res_json.get("candidates", [])
                            if not candidates:
                                logger.warning(
                                    f"Gemini vision no candidates on {model_name}."
                                )
                                last_error = "No candidates in response"
                                break
                            parts = (
                                candidates[0].get("content", {}).get("parts", [])
                            )
                            if not parts:
                                last_error = "No parts in candidate"
                                break
                            logger.info(
                                f"Gemini vision success: model={model_name}"
                            )
                            return parts[0].get("text", "")

                        logger.warning(
                            f"Gemini vision model={model_name} HTTP "
                            f"{response.status_code} (retry {retry})"
                        )

                        if response.status_code in (429, 500, 502, 503, 504):
                            await asyncio.sleep(1.5 * retry)
                            continue  # retry same model

                        # Hard 4xx error — skip straight to next model
                        last_error = f"HTTP {response.status_code}: {response.text[:200]}"
                        break

                    except httpx.RequestError as e:
                        logger.error(
                            f"Gemini vision network error on {model_name} retry {retry}: {e}"
                        )
                        last_error = str(e)
                        await asyncio.sleep(1.5 * retry)
                        continue

        raise HTTPException(
            status_code=502,
            detail=f"All Gemini vision models exhausted. Last error: {last_error}"
        )

    async def _call_claude_vision(
        self,
        image_bytes: bytes,
        mime_type: str,
        system_prompt: str,
        user_text: str,
    ) -> str:
        """
        Claude vision call using the Anthropic Messages API.
        Sends the image as a base64-encoded source block.
        Falls back to claude-3-5-sonnet if the configured model doesn't support vision.
        """
        if not self.api_key:
            raise ValueError("CLAUDE_API_KEY is not configured.")

        # Ensure the configured model supports vision; fall back if not
        model = self.model
        if model not in CLAUDE_VISION_MODELS:
            model = "claude-3-5-sonnet-20241022"
            logger.warning(
                f"Configured Claude model '{self.model}' may not support vision. "
                f"Using '{model}' for scan."
            )

        base64_image = base64.b64encode(image_bytes).decode("utf-8")

        payload = {
            "model": model,
            "max_tokens": 4096,
            "system": system_prompt,
            "messages": [
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "image",
                            "source": {
                                "type": "base64",
                                "media_type": mime_type,
                                "data": base64_image,
                            },
                        },
                        {"type": "text", "text": user_text},
                    ],
                }
            ],
        }

        headers = {
            "x-api-key": self.api_key,
            "anthropic-version": "2023-06-01",
            "content-type": "application/json",
        }

        import asyncio

        async with httpx.AsyncClient(timeout=90.0) as client:
            for retry in range(1, 4):
                try:
                    logger.info(
                        f"Claude vision scan: model={model}, retry={retry}"
                    )
                    response = await client.post(
                        "https://api.anthropic.com/v1/messages",
                        headers=headers,
                        json=payload,
                    )

                    if response.status_code == 200:
                        res_json = response.json()
                        content = res_json.get("content", [])
                        if content and content[0].get("type") == "text":
                            logger.info(f"Claude vision success: model={model}")
                            return content[0]["text"]
                        last_error = "Empty content in Claude response"
                        break

                    logger.warning(
                        f"Claude vision HTTP {response.status_code} (retry {retry})"
                    )

                    if response.status_code in (429, 500, 502, 503, 504):
                        await asyncio.sleep(1.5 * retry)
                        continue

                    raise HTTPException(
                        status_code=502,
                        detail=f"Claude vision error {response.status_code}: {response.text[:300]}",
                    )

                except httpx.RequestError as e:
                    logger.error(
                        f"Claude vision network error retry {retry}: {e}"
                    )
                    await asyncio.sleep(1.5 * retry)
                    continue

        raise HTTPException(
            status_code=502,
            detail="Claude vision failed after retries."
        )

    async def scan_meal_photo(self, file_bytes: bytes, mime_type: str = "image/jpeg") -> Dict[str, Any]:
        """
        Analyze a food/meal photo using the active AI provider (Gemini or Claude).
        The provider and model are read dynamically from the database (admin panel)
        on every request, so changes take effect immediately without a restart.
        Falls back to sensible mock data on any failure so the app never crashes.
        """
        fallback_response = {
            "items": [
                {
                    "name": "Grilled Chicken Breast",
                    "estimated_grams": 150.0,
                    "calories_per_100g": 165.0,
                    "carbs_per_100g": 0.0,
                    "protein_per_100g": 31.0,
                    "fat_per_100g": 3.6,
                    "fiber_per_100g": 0.0,
                    "confidence": "medium"
                },
                {
                    "name": "Steamed White Rice",
                    "estimated_grams": 180.0,
                    "calories_per_100g": 130.0,
                    "carbs_per_100g": 28.0,
                    "protein_per_100g": 2.7,
                    "fat_per_100g": 0.3,
                    "fiber_per_100g": 0.4,
                    "confidence": "medium"
                },
                {
                    "name": "Mixed Vegetables",
                    "estimated_grams": 100.0,
                    "calories_per_100g": 65.0,
                    "carbs_per_100g": 13.0,
                    "protein_per_100g": 2.5,
                    "fat_per_100g": 0.4,
                    "fiber_per_100g": 3.5,
                    "confidence": "medium"
                }
            ],
            "total_estimated_calories": 527.5,
            "overall_confidence": "medium",
            "meal_description": "Estimated meal — AI unavailable. Edit weights before logging.",
            "scan_source": "fallback"
        }

        # ── 1. Load dynamic provider + model from DB (validates model name too) ──
        await self._load_settings()
        logger.info(
            f"Meal scan: provider={self.provider}, model={self.model}, "
            f"api_key={'set' if self.api_key else 'missing'}"
        )

        if not self.api_key:
            logger.warning(
                f"API key missing for provider '{self.provider}'. "
                "Returning fallback scan response."
            )
            return fallback_response

        # ── 2. Shared prompt (identical regardless of provider) ──────────────
        system_prompt = (
            "You are a registered dietitian and computer vision expert specializing in nutritional analysis of food photos. "
            "Your task is to carefully analyze a meal photo and identify every distinct food item visible on the plate or tray. "
            "For each identified item:\n"
            "  1. Name it precisely (e.g., 'Basmati Rice' not just 'Rice', 'Grilled Salmon Fillet' not just 'Fish').\n"
            "  2. Estimate the weight in grams using visual cues: plate size, item thickness, density, and volume.\n"
            "  3. Provide accurate USDA-grade nutritional values per 100g for the item in its cooked/prepared state.\n"
            "  4. Set confidence based on visual clarity: 'high' if clearly identifiable, 'medium' if probable, 'low' if a guess.\n"
            "\n"
            "Portion estimation rules:\n"
            "  - A standard dinner plate is ~26cm diameter; use it to scale portions.\n"
            "  - Cooked rice: 1 cup \u2248 195g. Cooked pasta: 1 cup \u2248 140g.\n"
            "  - Chicken breast (1 medium) \u2248 174g raw / 150g cooked.\n"
            "  - A slice of bread \u2248 30g. One egg \u2248 50g.\n"
            "\n"
            "Output ONLY a valid JSON object \u2014 no markdown, no prose \u2014 matching this exact schema:\n"
            "{\n"
            "  \"items\": [\n"
            "    {\n"
            "      \"name\": \"Basmati Rice\",\n"
            "      \"estimated_grams\": 195.0,\n"
            "      \"calories_per_100g\": 130.0,\n"
            "      \"carbs_per_100g\": 28.2,\n"
            "      \"protein_per_100g\": 2.7,\n"
            "      \"fat_per_100g\": 0.3,\n"
            "      \"fiber_per_100g\": 0.4,\n"
            "      \"confidence\": \"high\"\n"
            "    }\n"
            "  ],\n"
            "  \"total_estimated_calories\": 254.0,\n"
            "  \"overall_confidence\": \"high\",\n"
            "  \"meal_description\": \"A serving of fluffy basmati rice with a mixed vegetable curry.\"\n"
            "}"
        )

        user_text = (
            "Please analyse this meal photo. Identify all food items, estimate their gram "
            "weights from visual cues, and return accurate USDA-grade macronutrient and "
            "micronutrient values per 100g for each item. "
            "Be precise with portion sizes and specific with food names."
        )

        try:
            # ── 3. Route to the correct provider vision call ─────────────────
            if self.provider == "claude":
                logger.info(f"Routing meal scan to Claude vision (model={self.model})")
                raw_res = await self._call_claude_vision(
                    image_bytes=file_bytes,
                    mime_type=mime_type,
                    system_prompt=system_prompt,
                    user_text=user_text,
                )
            else:
                # Gemini (default) — use configured model as first attempt
                logger.info(f"Routing meal scan to Gemini vision (model={self.model})")
                raw_res = await self._call_gemini_vision(
                    image_bytes=file_bytes,
                    mime_type=mime_type,
                    system_prompt=system_prompt,
                    user_text=user_text,
                    preferred_model=self.model,
                )

            result = self._repair_json(raw_res)
            if result is None:
                logger.error(f"All JSON repair strategies failed. Raw: {raw_res[:500]}")
                logger.warning("Falling back to default meal scan response.")
                return fallback_response

            # Ensure required fields exist with defaults
            result.setdefault("total_estimated_calories", sum(
                (item.get("calories_per_100g", 0) * item.get("estimated_grams", 0) / 100.0)
                for item in result.get("items", [])
            ))
            result.setdefault("overall_confidence", "medium")
            result.setdefault("meal_description", "Meal analysed from photo.")
            result["scan_source"] = "ai"

            # Ensure optional micronutrient fields default to 0 on each item
            for item in result.get("items", []):
                item.setdefault("fiber_per_100g", 0.0)

            logger.info(
                f"Meal scan succeeded: {len(result.get('items', []))} items detected, "
                f"total_cal={result.get('total_estimated_calories', 0):.0f}"
            )
            return result

        except HTTPException as e:
            logger.error(f"Meal scan HTTP error: {e.detail}. Falling back to default response.")
            return fallback_response
        except httpx.RequestError as e:
            logger.error(f"Meal scan network error: {e}. Falling back to default response.")
            return fallback_response
        except Exception as e:
            logger.error(f"Meal scan unexpected error: {e}. Falling back to default response.")
            return fallback_response

    async def generate_insights(self, user_id: uuid.UUID) -> Dict[str, Any]:
        """
        Compile log history metrics for the past 7 days and call OpenRouter to generate coaching tips.
        Fallback to simulated mock insights if API key is not configured.
        """
        end_date = date.today()
        start_date = end_date - timedelta(days=6)

        # 1. Fetch user targets
        goal_repo = GoalRepository(self.db)
        goal_obj = await goal_repo.get_by_user_id(user_id)
        
        # 2. Query historical logs
        food_repo = FoodLogEntryRepository(self.db)
        water_repo = WaterLogRepository(self.db)
        exec_repo = ExerciseLogRepository(self.db)
        weight_repo = WeightEntryRepository(self.db)

        # Totals over the last 7 days
        days_logged = 0
        total_cal = 0.0
        total_protein = 0.0
        total_carbs = 0.0
        total_fat = 0.0
        total_water = 0
        total_burned = 0.0

        for i in range(7):
            d = start_date + timedelta(days=i)
            day_macros = await food_repo.get_daily_macro_totals(user_id, d)
            day_water = await water_repo.get_daily_total(user_id, d)
            day_exercise = await exec_repo.get_daily_calories_burned(user_id, d)

            if day_macros["calories"] > 0:
                days_logged += 1
                total_cal += day_macros["calories"]
                total_protein += day_macros["protein"]
                total_carbs += day_macros["carbs"]
                total_fat += day_macros["fat"]
            total_water += day_water
            total_burned += day_exercise

        avg_cal = total_cal / days_logged if days_logged > 0 else 0.0
        avg_protein = total_protein / days_logged if days_logged > 0 else 0.0
        avg_water = total_water / 7
        
        weight_stats = await weight_repo.get_weight_stats(user_id)

        # Compile metric brief for LLM prompt
        target_cal = goal_obj.daily_calorie_target if goal_obj else 2000
        target_water = goal_obj.daily_water_ml if goal_obj else 2000
        
        metrics_summary = (
            f"User Goal: {goal_obj.goal_type if goal_obj else 'Maintain'}. "
            f"Daily Calorie Target: {target_cal} kcal. Average Consumed: {avg_cal:.1f} kcal. "
            f"Average Protein Consumed: {avg_protein:.1f}g. "
            f"Daily Water Target: {target_water} ml. Average Hydration: {avg_water:.1f} ml. "
            f"Total Exercise Calories Burned: {total_burned:.1f} kcal. "
            f"Weight Change: Start={weight_stats['start_weight_kg']}kg, Current={weight_stats['current_weight_kg']}kg, "
            f"Goal={weight_stats['goal_weight_kg']}kg, Trend={weight_stats['trend_kg_per_week']}kg/week."
        )

        if not self.api_key:
            logger.warning("GEMINI_API_KEY is missing. Simulating coaching insights.")
            # Return high-quality mock response
            score = 82
            if avg_cal > 0 and abs(avg_cal - target_cal) < 200:
                score += 10
            if avg_water > target_water - 300:
                score += 5
            score = min(score, 100)

            return {
                "insights": [
                    {
                        "type": "nutrition",
                        "message": "Your average daily intake (1,840 kcal) was close to your target. Protein is slightly below the 2.0g/kg goal.",
                        "icon": "restaurant"
                    },
                    {
                        "type": "hydration",
                        "message": "You reached 85% of your daily water intake goals. Consider carrying a larger flask to stay consistent.",
                        "icon": "water_drop"
                    },
                    {
                        "type": "activity",
                        "message": "Excellent cardiovascular workouts logged this week! You burned an extra 1,200 kcal.",
                        "icon": "fitness_center"
                    }
                ],
                "tips": [
                    {"message": "Add a scoop of whey protein or egg whites to breakfast to meet your daily protein target.", "priority": "high"},
                    {"message": "Drink 250ml of water immediately upon waking to kickstart hydration.", "priority": "medium"},
                    {"message": "Ensure at least 7-8 hours of sleep for optimum recovery after strength workouts.", "priority": "low"}
                ],
                "overall_score": score
            }

        system_prompt = (
            "You are an expert fitness coach and health behaviorist. Analyze the user's weekly calorie, hydration, "
            "exercise, and weight metrics, comparing them against targets. "
            "Return 3 health insights, 3 daily tips, and a cumulative consistency health score (0-100). "
            "Output ONLY valid JSON matching this schema: "
            "{\n"
            "  \"insights\": [\n"
            "    {\"type\": \"nutrition|hydration|activity|weight\", \"message\": \"Insight message\", \"icon\": \"restaurant|water_drop|fitness_center|show_chart\"}\n"
            "  ],\n"
            "  \"tips\": [\n"
            "    {\"message\": \"Actionable recommendation\", \"priority\": \"high|medium|low\"}\n"
            "  ],\n"
            "  \"overall_score\": 85\n"
            "}"
        )

        messages = [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": f"Analyze these health logging metrics: \"{metrics_summary}\""}
        ]

        try:
            raw_res = await self._call_llm(messages, response_format={"type": "json_object"})
            cleaned = self._clean_json(raw_res)
            return json.loads(cleaned)
        except Exception as e:
            logger.error(f"Weekly insights AI call failed or returned invalid JSON: {e}. Falling back to default insights.")
            score = 82
            if avg_cal > 0 and abs(avg_cal - target_cal) < 200:
                score += 10
            if avg_water > target_water - 300:
                score += 5
            score = min(score, 100)
            
            return {
                "insights": [
                    {
                        "type": "nutrition",
                        "message": f"Your average daily intake ({avg_cal:.0f} kcal) is tracked. Aim to hit close to your {target_cal} kcal target.",
                        "icon": "restaurant"
                    },
                    {
                        "type": "hydration",
                        "message": f"You reached an average of {avg_water:.0f} ml of water. Keep drinking consistently to hit your {target_water} ml target.",
                        "icon": "water_drop"
                    },
                    {
                        "type": "activity",
                        "message": f"Logged workouts this week burned {total_burned:.0f} kcal total. Keep up the active momentum!",
                        "icon": "fitness_center"
                    }
                ],
                "tips": [
                    {"message": "Add a protein source to your meals to support muscle repair and recovery.", "priority": "high"},
                    {"message": "Drink a glass of water first thing in the morning to start your hydration early.", "priority": "medium"},
                    {"message": "Keep logging weight entries regularly to visualize weight trend updates.", "priority": "low"}
                ],
                "overall_score": score
            }

    async def _get_user_context_summary(self, user_id: uuid.UUID) -> str:
        """
        Compile goals, weight stats, and recent diary logs into a text summary for LLM context.
        """
        # 1. Fetch user targets
        goal_repo = GoalRepository(self.db)
        goal_obj = await goal_repo.get_by_user_id(user_id)
        
        # 2. Query historical logs
        food_repo = FoodLogEntryRepository(self.db)
        water_repo = WaterLogRepository(self.db)
        exec_repo = ExerciseLogRepository(self.db)
        weight_repo = WeightEntryRepository(self.db)
        
        # Weight stats
        weight_stats = await weight_repo.get_weight_stats(user_id)
        
        # Compile recent logs (last 3 days)
        today = date.today()
        recent_days_str = []
        for i in range(3):
            d = today - timedelta(days=i)
            day_macros = await food_repo.get_daily_macro_totals(user_id, d)
            day_water = await water_repo.get_daily_total(user_id, d)
            day_exercise = await exec_repo.get_daily_calories_burned(user_id, d)
            
            # Get list of foods logged on this day
            entries = await food_repo.get_entries_by_date(user_id, d)
            food_list_str = ", ".join([f"{e.food_item.name if e.food_item else 'Custom Food'} ({e.serving_size_g}g)" for e in entries])
            
            recent_days_str.append(
                f"- {d.strftime('%Y-%m-%d')}: Consumed {day_macros['calories']:.0f} kcal (P: {day_macros['protein']:.0f}g, C: {day_macros['carbs']:.0f}g, F: {day_macros['fat']:.0f}g). "
                f"Water: {day_water} ml. Workouts burned: {day_exercise:.0f} kcal. Food logged: [{food_list_str or 'None'}]"
            )
            
        logs_summary = "\n".join(recent_days_str)
        
        target_cal = goal_obj.daily_calorie_target if goal_obj else 2000
        target_protein = goal_obj.daily_protein_g if goal_obj else 150
        target_carbs = goal_obj.daily_carbs_g if goal_obj else 200
        target_fat = goal_obj.daily_fat_g if goal_obj else 65
        target_fiber = goal_obj.daily_fiber_g if goal_obj else 25
        target_water = goal_obj.daily_water_ml if goal_obj else 2000
        goal_type = goal_obj.goal_type if goal_obj else "Maintain"
        
        context = (
            f"User Goal: {goal_type}\n"
            f"Daily Targets: Calories={target_cal} kcal, Protein={target_protein}g, Carbs={target_carbs}g, Fat={target_fat}g, Fiber={target_fiber}g, Water={target_water} ml\n"
            f"Weight Progress: Start={weight_stats['start_weight_kg']} kg, Current={weight_stats['current_weight_kg']} kg, Target={weight_stats['goal_weight_kg']} kg. "
            f"Weight Trend (slope/week): {weight_stats['trend_kg_per_week']} kg/week.\n"
            f"Recent Logs (last 3 days):\n{logs_summary}"
        )
        return context

    async def chat_with_coach(self, user_id: uuid.UUID, messages: List[ChatMessage]) -> str:
        """
        Interactive chat with AI Coach, injecting user context into system instructions.
        """
        user_context = await self._get_user_context_summary(user_id)
        
        # Format conversation history
        history_str = ""
        for m in messages[:-1]:
            role_label = "User" if m.role == "user" else "Coach"
            history_str += f"{role_label}: {m.content}\n"
        
        current_query = messages[-1].content if messages else ""

        def offline_reply() -> str:
            # High-quality offline coach simulator
            greeting = "Hey there! I'm your AI Coach (simulated offline)."
            if "protein" in current_query.lower():
                return f"{greeting} Looking at your logs, your protein target is set. Try incorporating chicken, fish, eggs, tofu, or greek yogurt to hit your goal."
            elif "weight" in current_query.lower() or "progress" in current_query.lower():
                return f"{greeting} I see your current weight log. Staying consistent with logging your food and exercises is key. Let me know if you need macro suggestions!"
            elif "water" in current_query.lower() or "hydrate" in current_query.lower():
                return f"{greeting} Hydration is super important! Keep drinking water throughout the day. Having a glass right after waking up works wonders."
            else:
                return f"{greeting} I've analyzed your logs. Let me know if you have questions about your calories, protein, hydration, or weight trend!"
        
        if not self.api_key:
            return offline_reply()

        system_instruction = (
            "You are Antigravity, an elite personal AI health & fitness coach. "
            "You have access to the user's detailed profile, goals, weight trends, and recent food/water/exercise logs. "
            "Use this context to answer their questions accurately, and provide highly encouraging, scientific, "
            "and practical fitness advice. Be conversational, empathetic, and professional. Keep answers relatively concise (1-3 short paragraphs).\n\n"
            f"User Context:\n{user_context}"
        )
        
        user_content = ""
        if history_str:
            user_content += f"Conversation History:\n{history_str}\n"
        user_content += f"User's new question: {current_query}"
        
        gemini_messages = [
            {"role": "system", "content": system_instruction},
            {"role": "user", "content": user_content}
        ]
        
        try:
            return await self._call_llm(gemini_messages)
        except Exception as e:
            logger.error(f"Chat AI call failed: {e}")
            return offline_reply()

    async def get_daily_debrief(self, user_id: uuid.UUID, log_date: date) -> Dict[str, Any]:
        """
        Produce a customized end-of-day summary, deficits flag, and actionable tweaks.
        """
        # Fetch targets
        goal_repo = GoalRepository(self.db)
        goal_obj = await goal_repo.get_by_user_id(user_id)
        
        # Fetch logs for specific date
        food_repo = FoodLogEntryRepository(self.db)
        water_repo = WaterLogRepository(self.db)
        exec_repo = ExerciseLogRepository(self.db)
        
        day_macros = await food_repo.get_daily_macro_totals(user_id, log_date)
        day_water = await water_repo.get_daily_total(user_id, log_date)
        day_exercise = await exec_repo.get_daily_calories_burned(user_id, log_date)
        entries = await food_repo.get_entries_by_date(user_id, log_date)
        
        target_cal = goal_obj.daily_calorie_target if goal_obj else 2000
        target_protein = goal_obj.daily_protein_g if goal_obj else 150
        target_carbs = goal_obj.daily_carbs_g if goal_obj else 200
        target_fat = goal_obj.daily_fat_g if goal_obj else 65
        target_fiber = goal_obj.daily_fiber_g if goal_obj else 25
        target_water = goal_obj.daily_water_ml if goal_obj else 2000
        
        # Calculate actual values
        cals = day_macros["calories"]
        protein = day_macros["protein"]
        carbs = day_macros["carbs"]
        fat = day_macros["fat"]
        fiber = day_macros["fiber"]
        
        # Identify deficits programmatically
        deficits = []
        if protein < (target_protein - 15):
            deficits.append(f"Protein is short by {target_protein - protein:.0f}g")
        if fiber < (target_fiber - 5):
            deficits.append(f"Fiber is short by {target_fiber - fiber:.0f}g")
        if day_water < (target_water - 400):
            deficits.append(f"Hydration is short by {target_water - day_water:.0f} ml")
        if cals < (target_cal - 300):
            deficits.append(f"Calorie intake is below target by {target_cal - cals:.0f} kcal (undereating)")
        elif cals > (target_cal + 200):
            deficits.append(f"Calorie intake exceeds target by {cals - target_cal:.0f} kcal")
            
        if not deficits:
            deficits.append("None! You hit all major macronutrient and hydration targets.")
            
        food_list_str = ", ".join([f"{e.food_item.name if e.food_item else 'Custom Food'} ({e.serving_size_g}g)" for e in entries])
        
        if not self.api_key:
            # Fallback/Mock generator
            summary_text = (
                f"You consumed {cals:.0f} kcal today, aiming for {target_cal} kcal. "
                f"Your protein intake was {protein:.0f}g against a target of {target_protein}g. "
            )
            if len(entries) > 0:
                summary_text += f"Your logged meals included: {food_list_str}."
            else:
                summary_text += "You didn't log any food items today. Try logging tomorrow to track your macros!"
                
            tweaks = []
            if protein < (target_protein - 15):
                tweaks.append("Add a high-protein snack like Greek yogurt, eggs, or a shake tomorrow.")
            if fiber < (target_fiber - 5):
                tweaks.append("Incorporate leafy greens, oats, or chia seeds into your meals tomorrow to boost fiber.")
            if day_water < (target_water - 400):
                tweaks.append("Keep a water bottle beside you and aim to drink a glass every 2 hours.")
            if not tweaks:
                tweaks.append("Excellent consistency! Try to match this exact routine tomorrow.")
                
            return {
                "summary": summary_text,
                "deficits": deficits,
                "tweaks": tweaks
            }

        # LLM Generation
        system_prompt = (
            "You are a helpful nutrition coach. Analyze the user's daily eating summary, compare it to targets, "
            "and write a short summary (2-3 sentences), identify nutritional deficits, and suggest 2-3 specific, "
            "actionable diet tweaks for tomorrow. "
            "Output ONLY valid JSON matching this schema:\n"
            "{\n"
            "  \"summary\": \"Brief conversational summary of the day's eating\",\n"
            "  \"deficits\": [\"Deficit 1 (e.g., Protein was 30g short of target)\"],\n"
            "  \"tweaks\": [\"Tweak 1 (e.g., Have a cup of Greek yogurt with breakfast)\"]\n"
            "}"
        )
        
        user_input = (
            f"Daily Log Date: {log_date.strftime('%Y-%m-%d')}\n"
            f"Actual Intake: Calories={cals:.0f} kcal, Protein={protein:.0f}g, Carbs={carbs:.0f}g, Fat={fat:.0f}g, Fiber={fiber:.0f}g, Water={day_water} ml\n"
            f"Targets: Calories={target_cal} kcal, Protein={target_protein}g, Carbs={target_carbs}g, Fat={target_fat}g, Fiber={target_fiber}g, Water={target_water} ml\n"
            f"Foods Eaten: [{food_list_str}]\n"
            f"Exercise Calories Burned: {day_exercise:.0f} kcal"
        )
        
        messages = [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_input}
        ]
        
        try:
            raw_res = await self._call_llm(messages, response_format={"type": "json_object"})
            cleaned = self._clean_json(raw_res)
            return json.loads(cleaned)
        except Exception as e:
            logger.error(f"Debrief AI call failed: {e}")
            # Fallback to simple logic
            tweaks = []
            if protein < (target_protein - 15):
                tweaks.append("Add a high-protein snack like eggs or protein shake tomorrow.")
            if fiber < (target_fiber - 5):
                tweaks.append("Include more whole grains or vegetables to hit fiber targets.")
            if day_water < (target_water - 400):
                tweaks.append("Drink water consistently to cover the hydration deficit.")
            if not tweaks:
                tweaks.append("Continue tracking and matching your caloric goals tomorrow.")
                
            return {
                "summary": f"You logged {cals:.0f} kcal today compared to your target of {target_cal} kcal.",
                "deficits": deficits,
                "tweaks": tweaks
            }

    async def get_weight_trend_interpretation(self, user_id: uuid.UUID) -> Dict[str, Any]:
        """
        Narrate the regression-based weight trend in plain English with suggestions.
        """
        weight_repo = WeightEntryRepository(self.db)
        stats = await weight_repo.get_weight_stats(user_id)
        
        trend = stats["trend_kg_per_week"]
        goal_weight = stats["goal_weight_kg"]
        curr_weight = stats["current_weight_kg"]
        
        # Simple logical mapping for mock/fallback
        if trend < -0.1:
            trend_desc = f"losing {abs(trend)} kg per week"
            suggestion = "You are on track. Maintain current calorie targets."
        elif trend > 0.1:
            trend_desc = f"gaining {trend} kg per week"
            suggestion = "Consider reducing daily intake by 200-300 kcal if you want to lose weight."
        else:
            trend_desc = "maintaining current weight (plateau)"
            suggestion = "Try adding 20 minutes of daily cardio or cutting 150 kcal to break the plateau."

        if not self.api_key:
            return {
                "interpretation": f"Based on your entries, you are {trend_desc}. Current: {curr_weight} kg, Goal: {goal_weight} kg.",
                "suggestion": suggestion
            }
            
        system_prompt = (
            "You are a professional fitness coach. Analyze the user's weight log statistics and explain their weekly "
            "trend (calculated via linear regression) in plain English. Tell them if they are on track for their goals. "
            "Suggest adjustments for calorie and macro targets.\n"
            "Output ONLY valid JSON matching this schema:\n"
            "{\n"
            "  \"interpretation\": \"Narrative explanation of the trend (e.g., 'You are losing 0.4 kg per week, which is right on track for your fat loss goal...')\",\n"
            "  \"suggestion\": \"Actionable recommendation for calorie and macro intake (e.g., 'Maintain your current intake of 1,800 kcal to continue this steady progress.')\"\n"
            "}"
        )
        
        user_input = (
            f"Current Weight: {curr_weight} kg\n"
            f"Goal Target Weight: {goal_weight} kg\n"
            f"Calculated Weight Trend: {trend} kg/week (negative indicates weight loss, positive indicates gain)"
        )
        
        messages = [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_input}
        ]
        
        try:
            raw_res = await self._call_llm(messages, response_format={"type": "json_object"})
            cleaned = self._clean_json(raw_res)
            return json.loads(cleaned)
        except Exception as e:
            logger.error(f"Weight trend AI call failed: {e}")
            return {
                "interpretation": f"You are currently {trend_desc}. Your weight is {curr_weight} kg, with a goal of {goal_weight} kg.",
                "suggestion": suggestion
            }
