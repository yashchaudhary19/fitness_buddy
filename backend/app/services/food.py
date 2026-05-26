import json
import logging
import uuid
from typing import List, Optional, Dict, Any
import httpx
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.dialects.postgresql import insert as pg_insert
from sqlalchemy import select

from app.core.config import settings
from app.core.redis import get_redis
from app.models.food import FoodItem, FoodSource
from app.repositories.food import FoodItemRepository

logger = logging.getLogger("nutritrack.food_service")

class FoodService:
    def __init__(self, db: AsyncSession):
        self.db = db
        self.food_repo = FoodItemRepository(db)
        self.redis = get_redis()
        self.api_key = settings.GEMINI_API_KEY
        self.model = settings.GEMINI_MODEL

    def _parse_product(self, product_data: Dict[str, Any], source: FoodSource) -> Dict[str, Any]:
        """Parse raw nutritional data from Open Food Facts into database columns."""
        nutriments = product_data.get("nutriments", {})
        
        # Determine calorie value per 100g (energy-kcal preferred, fallback to energy)
        calories = nutriments.get("energy-kcal_100g")
        if calories is None:
            calories = nutriments.get("energy-kcal")
        if calories is None:
            # Fallback to energy in kJ (1 kcal = 4.184 kJ)
            energy_kj = nutriments.get("energy-kj_100g") or nutriments.get("energy_100g")
            if energy_kj is not None:
                calories = float(energy_kj) / 4.184
            else:
                calories = 0.0

        return {
            "name": product_data.get("product_name") or product_data.get("product_name_en") or "Unknown Product",
            "brand": product_data.get("brands") or "",
            "barcode": product_data.get("code") or product_data.get("_id"),
            "calories_per_100g": max(0.0, float(calories)),
            "carbs_per_100g": max(0.0, float(nutriments.get("carbohydrates_100g") or 0.0)),
            "protein_per_100g": max(0.0, float(nutriments.get("proteins_100g") or 0.0)),
            "fat_per_100g": max(0.0, float(nutriments.get("fat_100g") or 0.0)),
            "fiber_per_100g": max(0.0, float(nutriments.get("fiber_100g") or 0.0)),
            "sugar_per_100g": max(0.0, float(nutriments.get("sugars_100g") or 0.0)),
            "sodium_per_100g": max(0.0, float(nutriments.get("sodium_100g") or 0.0)),
            "saturated_fat_per_100g": max(0.0, float(nutriments.get("saturated-fat_100g") or 0.0)),
            "image_url": product_data.get("image_front_url") or product_data.get("image_url") or None,
            "source": source
        }

    async def search_foods(self, query: str, user_id: Optional[uuid.UUID] = None) -> List[FoodItem]:
        """
        Search for foods:
          1. Query local database first.
          2. If local matches >= 10, return them.
          3. If local matches < 10, check Redis cache for OFF results.
          4. If not cached, query Open Food Facts API, save new foods, cache results, and return.
        """
        query = query.strip()
        if not query:
            return []

        # 1. Search local DB
        local_results = await self.food_repo.search_foods(query, user_id)
        if len(local_results) >= 10:
            return local_results

        # 2. Check Redis cache
        cache_key = f"food:search:{query.lower()}"
        if self.redis:
            try:
                cached = await self.redis.get(cache_key)
                if cached:
                    cached_ids = json.loads(cached)
                    # Fetch from database by IDs to ensure they are returned as SQLAlchemy objects
                    stmt = select(FoodItem).filter(FoodItem.id.in_([uuid.UUID(i) for i in cached_ids]))
                    res = await self.db.execute(stmt)
                    cached_items = list(res.scalars().all())
                    if cached_items:
                        # Combine local_results and cached_items, avoiding duplicates
                        seen = {item.id for item in local_results}
                        combined = list(local_results)
                        for item in cached_items:
                            if item.id not in seen:
                                combined.append(item)
                        return combined
            except Exception as e:
                logger.error(f"Redis search cache retrieval error: {e}")

        # 3. Call Open Food Facts API
        logger.info(f"Local matches for '{query}' less than 10. Fetching from Open Food Facts.")
        off_url = f"{settings.OPEN_FOOD_FACTS_BASE}/cgi/search.pl"
        params = {
            "search_terms": query,
            "json": "true",
            "page_size": 20
        }
        
        products_to_save = []
        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                response = await client.get(off_url, params=params)
                if response.status_code == 200:
                    data = response.json()
                    products = data.get("products", [])
                    
                    for prod in products:
                        barcode = prod.get("code") or prod.get("_id")
                        if not barcode:
                            continue
                        
                        # Parse
                        parsed_data = self._parse_product(prod, FoodSource.API)
                        
                        # Verify item is not already in db
                        existing = await self.food_repo.get_by_barcode(barcode)
                        if not existing:
                            db_item = FoodItem(**parsed_data)
                            self.db.add(db_item)
                            products_to_save.append(db_item)
                        else:
                            products_to_save.append(existing)

                    if products_to_save:
                        await self.db.flush()
                        await self.db.commit()
        except Exception as e:
            logger.error(f"Failed to query Open Food Facts API: {e}")
            return local_results  # Fallback to local only

        # Combine results
        seen = {item.id for item in local_results}
        combined = list(local_results)
        for item in products_to_save:
            if item.id not in seen:
                combined.append(item)

        # 4. Cache search IDs in Redis
        if self.redis and combined:
            try:
                ids_to_cache = [str(item.id) for item in combined]
                await self.redis.setex(
                    cache_key,
                    settings.FOOD_CACHE_TTL_SECONDS,
                    json.dumps(ids_to_cache)
                )
            except Exception as e:
                logger.error(f"Redis search cache store error: {e}")

        return combined

    async def _estimate_macros_via_gemini(self, title: str, brand: str) -> Optional[Dict[str, float]]:
        """Estimate macronutrients using Gemini based on product name and brand."""
        if not self.api_key:
            return None
        prompt = (
            f"Estimate the nutrition facts for the product '{title}' by brand '{brand}' per 100g. "
            "Respond ONLY with a JSON object in this format:\n"
            "{\n"
            "  \"calories_per_100g\": 0.0,\n"
            "  \"carbs_per_100g\": 0.0,\n"
            "  \"protein_per_100g\": 0.0,\n"
            "  \"fat_per_100g\": 0.0,\n"
            "  \"fiber_per_100g\": 0.0\n"
            "}"
        )
        url = f"https://generativelanguage.googleapis.com/v1beta/models/{self.model}:generateContent?key={self.api_key}"
        payload = {
            "contents": [{"parts": [{"text": prompt}]}],
            "generationConfig": {"responseMimeType": "application/json"}
        }
        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                response = await client.post(url, json=payload)
                if response.status_code == 200:
                    res_json = response.json()
                    candidates = res_json.get("candidates", [])
                    if candidates:
                        text = candidates[0].get("content", {}).get("parts", [])[0].get("text", "")
                        cleaned = text.strip()
                        if cleaned.startswith("```json"):
                            cleaned = cleaned[7:]
                        elif cleaned.startswith("```"):
                            cleaned = cleaned[3:]
                        if cleaned.endswith("```"):
                            cleaned = cleaned[:-3]
                        data = json.loads(cleaned.strip())
                        return {
                            "calories_per_100g": float(data.get("calories_per_100g") or 0.0),
                            "carbs_per_100g": float(data.get("carbs_per_100g") or 0.0),
                            "protein_per_100g": float(data.get("protein_per_100g") or 0.0),
                            "fat_per_100g": float(data.get("fat_per_100g") or 0.0),
                            "fiber_per_100g": float(data.get("fiber_per_100g") or 0.0)
                        }
        except Exception as e:
            logger.error(f"Gemini estimation of macros failed: {e}")
        return None

    async def _estimate_macros_from_local_db(self, title: str) -> Optional[Dict[str, float]]:
        """Try to find a similar product in the local DB and use its macros as a fallback."""
        words = [w for w in title.split() if len(w) > 3]
        if not words:
            return None
        try:
            local_results = await self.food_repo.search_foods(words[0])
            if local_results:
                # Find the first match with non-zero calories or macros
                match = local_results[0]
                for item in local_results:
                    if (item.calories_per_100g or 0) > 0 or (item.carbs_per_100g or 0) > 0 or (item.protein_per_100g or 0) > 0:
                        match = item
                        break
                return {
                    "calories_per_100g": match.calories_per_100g,
                    "carbs_per_100g": match.carbs_per_100g,
                    "protein_per_100g": match.protein_per_100g,
                    "fat_per_100g": match.fat_per_100g,
                    "fiber_per_100g": match.fiber_per_100g,
                }
        except Exception as e:
            logger.error(f"Error estimating macros from local DB: {e}")
        return None

    async def _estimate_product_by_barcode_via_gemini(self, barcode: str) -> Optional[Dict[str, Any]]:
        """Identify product name, brand, and nutrition using Gemini direct lookup."""
        if not self.api_key:
            return None
        prompt = (
            f"You are a barcode nutrition lookup system. The user scanned the barcode '{barcode}'. "
            "Please lookup or estimate what product this barcode corresponds to. "
            "Provide the name, brand, and nutritional facts per 100g. "
            "Respond ONLY with a JSON object in this format:\n"
            "{\n"
            "  \"name\": \"Product Name\",\n"
            "  \"brand\": \"Brand Name\",\n"
            "  \"calories_per_100g\": 0.0,\n"
            "  \"carbs_per_100g\": 0.0,\n"
            "  \"protein_per_100g\": 0.0,\n"
            "  \"fat_per_100g\": 0.0,\n"
            "  \"fiber_per_100g\": 0.0\n"
            "}"
        )
        url = f"https://generativelanguage.googleapis.com/v1beta/models/{self.model}:generateContent?key={self.api_key}"
        payload = {
            "contents": [{"parts": [{"text": prompt}]}],
            "generationConfig": {"responseMimeType": "application/json"}
        }
        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                response = await client.post(url, json=payload)
                if response.status_code == 200:
                    res_json = response.json()
                    candidates = res_json.get("candidates", [])
                    if candidates:
                        text = candidates[0].get("content", {}).get("parts", [])[0].get("text", "")
                        cleaned = text.strip()
                        if cleaned.startswith("```json"):
                            cleaned = cleaned[7:]
                        elif cleaned.startswith("```"):
                            cleaned = cleaned[3:]
                        if cleaned.endswith("```"):
                            cleaned = cleaned[:-3]
                        data = json.loads(cleaned.strip())
                        return {
                            "name": data.get("name") or "Unknown AI Product",
                            "brand": data.get("brand") or "Generic",
                            "barcode": barcode,
                            "calories_per_100g": float(data.get("calories_per_100g") or 0.0),
                            "carbs_per_100g": float(data.get("carbs_per_100g") or 0.0),
                            "protein_per_100g": float(data.get("protein_per_100g") or 0.0),
                            "fat_per_100g": float(data.get("fat_per_100g") or 0.0),
                            "fiber_per_100g": float(data.get("fiber_per_100g") or 0.0),
                            "sugar_per_100g": 0.0,
                            "sodium_per_100g": 0.0,
                            "saturated_fat_per_100g": 0.0,
                            "image_url": None,
                            "source": FoodSource.BARCODE
                        }
        except Exception as e:
            logger.error(f"Gemini estimation of product by barcode failed: {e}")
        return None

    async def lookup_barcode(self, barcode: str) -> Optional[FoodItem]:
        """
        Lookup barcode using Open Food Facts API directly.
        If not found, falls back to searching the web (DuckDuckGo) to resolve
        the product name, and then estimates macros using Gemini AI / Local DB / Defaults.
        """
        barcode = barcode.strip()
        if not barcode:
            return None

        # 1. Query Open Food Facts API
        logger.info(f"Querying Open Food Facts API for barcode '{barcode}'...")
        off_url = f"{settings.OPEN_FOOD_FACTS_BASE}/api/v2/product/{barcode}.json"
        try:
            async with httpx.AsyncClient(timeout=8.0) as client:
                response = await client.get(off_url)
                if response.status_code == 200:
                    data = response.json()
                    status_code = data.get("status")
                    if status_code == 1 or data.get("status_verbose") == "product found":
                        product_data = data.get("product", {})
                        parsed_data = self._parse_product(product_data, FoodSource.BARCODE)
                        
                        existing = await self.food_repo.get_by_barcode(barcode)
                        if existing:
                            return existing
                            
                        db_item = FoodItem(**parsed_data)
                        await self.food_repo.create(db_item)
                        await self.db.commit()
                        return db_item
        except Exception as e:
            logger.error(f"Error querying Open Food Facts API: {e}")

        # 2. Fallback: Search the web (DuckDuckGo HTML search) for the barcode
        logger.info(f"Barcode '{barcode}' not found on Open Food Facts. Trying web search fallback...")
        ddg_url = f"https://html.duckduckgo.com/html/?q={barcode}"
        product_name = None
        brand_name = "Generic Brand"

        try:
            async with httpx.AsyncClient(timeout=8.0) as client:
                headers = {
                    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
                }
                response = await client.get(ddg_url, headers=headers)
                if response.status_code == 200:
                    html = response.text
                    
                    # Parse DuckDuckGo result snippets
                    import re
                    snippets = re.findall(r'class="[^"]*result__snippet[^"]*"[^>]*>(.*?)</a>', html, re.DOTALL)
                    
                    # Try to extract a clean product name from snippets
                    for snippet in snippets:
                        clean_s = re.sub('<[^<]+?>', '', snippet).strip()
                        # Extract name
                        # Pattern 1: e.g. "UPC 8901058006285: Maggi 2-Min Masala..."
                        pat1 = rf"(?:upc|ean|barcode|gtin)?\s*{barcode}\s*[:\-–—]\s*([^.]+)"
                        m1 = re.search(pat1, clean_s, re.IGNORECASE)
                        if m1:
                            name = m1.group(1).strip()
                            if name and 3 < len(name) < 100:
                                product_name = name
                                break
                                
                        # Pattern 2: e.g. "Maggi 2-Min Masala : Barcode 8901058006285"
                        pat2 = rf"([^.]+)\s*[:\-–—]\s*(?:upc|ean|barcode|gtin)?\s*{barcode}"
                        m2 = re.search(pat2, clean_s, re.IGNORECASE)
                        if m2:
                            name = m2.group(1).strip()
                            if name and 3 < len(name) < 100:
                                product_name = name
                                break
                                
                    # If regex matching failed, take first snippet first sentence as fallback
                    if not product_name and snippets:
                        first_s = re.sub('<[^<]+?>', '', snippets[0]).strip()
                        # If there's a colon and it's not a url
                        if ":" in first_s:
                            parts = first_s.split(":")
                            first_part = parts[0].strip()
                            if barcode in first_part and len(parts) > 1:
                                second_part = parts[1].split(".")[0].strip()
                                if 3 < len(second_part) < 100:
                                    product_name = second_part
                            elif 3 < len(first_part) < 100 and not any(k in first_part.lower() for k in ["http", "www", "image", "sold by"]):
                                product_name = first_part
                                
                        if not product_name:
                            first_sentence = first_s.split(".")[0].strip()
                            first_sentence = first_sentence.replace(barcode, "").replace("UPC", "").replace("EAN", "").strip()
                            first_sentence = re.sub(r'^\s*[:\-–—]\s*', '', first_sentence)
                            if 3 < len(first_sentence) < 100:
                                product_name = first_sentence

        except Exception as e:
            logger.error(f"Error performing web search fallback: {e}")

        if product_name:
            # We found a product name! Clean it up slightly.
            import re
            product_name = re.sub(r'\s+', ' ', product_name).strip()
            logger.info(f"Web search resolved barcode '{barcode}' to product name: '{product_name}'")
            
            # Extract possible brand name from product name (first word or before space)
            words = product_name.split()
            if words:
                brand_name = words[0]
                
            # 3. Estimate Macros
            macros = None
            
            # Try Gemini first if API key is present
            if self.api_key:
                logger.info(f"Estimating macros via Gemini for product '{product_name}' by '{brand_name}'...")
                macros = await self._estimate_macros_via_gemini(product_name, brand_name)
                
            # If Gemini failed/rate-limited, try local database fallback
            if not macros:
                logger.info(f"Gemini estimation unavailable. Trying local DB fallback for name '{product_name}'...")
                macros = await self._estimate_macros_from_local_db(product_name)
                
            # If local database estimation failed, use baseline default macros
            if not macros:
                logger.info(f"Local DB estimation unavailable. Using default baseline macros for '{product_name}'...")
                macros = {
                    "calories_per_100g": 120.0,
                    "carbs_per_100g": 15.0,
                    "protein_per_100g": 2.0,
                    "fat_per_100g": 3.0,
                    "fiber_per_100g": 0.0
                }

            # 4. Save and return estimated food item
            parsed_data = {
                "name": product_name,
                "brand": brand_name,
                "barcode": barcode,
                "calories_per_100g": max(0.0, float(macros.get("calories_per_100g", 0.0))),
                "carbs_per_100g": max(0.0, float(macros.get("carbs_per_100g", 0.0))),
                "protein_per_100g": max(0.0, float(macros.get("protein_per_100g", 0.0))),
                "fat_per_100g": max(0.0, float(macros.get("fat_per_100g", 0.0))),
                "fiber_per_100g": max(0.0, float(macros.get("fiber_per_100g", 0.0))),
                "sugar_per_100g": 0.0,
                "sodium_per_100g": 0.0,
                "saturated_fat_per_100g": 0.0,
                "image_url": None,
                "source": FoodSource.BARCODE
            }
            
            existing = await self.food_repo.get_by_barcode(barcode)
            if existing:
                return existing
                
            db_item = FoodItem(**parsed_data)
            await self.food_repo.create(db_item)
            await self.db.commit()
            return db_item

        # 3. Direct Gemini direct lookup fallback
        if self.api_key:
            logger.info(f"Web search failed. Attempting direct Gemini lookup for barcode '{barcode}'...")
            gemini_product = await self._estimate_product_by_barcode_via_gemini(barcode)
            if gemini_product:
                existing = await self.food_repo.get_by_barcode(barcode)
                if existing:
                    return existing
                db_item = FoodItem(**gemini_product)
                await self.food_repo.create(db_item)
                await self.db.commit()
                return db_item

        # 4. Final fallback
        logger.warning(f"Failed to resolve product name for barcode '{barcode}' via web search/Gemini.")
        return None
