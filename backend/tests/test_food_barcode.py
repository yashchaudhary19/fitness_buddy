import pytest
from unittest.mock import patch, MagicMock
from httpx import Response
from sqlalchemy.ext.asyncio import AsyncSession
from app.services.food import FoodService
from app.models.food import FoodSource

@pytest.mark.asyncio
async def test_lookup_barcode_open_food_facts_success(db: AsyncSession):
    """Test successful lookup of barcode present in Open Food Facts API."""
    service = FoodService(db)
    
    # Mock data for OFF response
    off_response_data = {
        "status": 1,
        "status_verbose": "product found",
        "product": {
            "code": "8901058006285",
            "product_name": "Instant noodles",
            "brands": "Maggi",
            "nutriments": {
                "energy-kcal_100g": 364.0,
                "carbohydrates_100g": 59.6,
                "proteins_100g": 8.2,
                "fat_100g": 12.5
            }
        }
    }
    
    async def mock_get(url, *args, **kwargs):
        if "openfoodfacts" in url:
            return Response(200, json=off_response_data)
        return Response(404)
        
    with patch("httpx.AsyncClient.get", side_effect=mock_get):
        item = await service.lookup_barcode("8901058006285")
        
        assert item is not None
        assert item.name == "Instant noodles"
        assert item.brand == "Maggi"
        assert item.barcode == "8901058006285"
        assert item.calories_per_100g == 364.0
        assert item.source == FoodSource.BARCODE


@pytest.mark.asyncio
async def test_lookup_barcode_web_fallback_success(db: AsyncSession):
    """Test lookup of barcode not on OFF, falling back to DDG search and local DB/Gemini/Default estimation."""
    service = FoodService(db)
    
    # Mock DDG HTML results containing a pattern for barcode:
    mock_ddg_html = """
    <html>
        <body>
            <a class="result__snippet" href="...">UPC 8901491101831: Lays Magic Masala Chips. Buy online...</a>
        </body>
    </html>
    """
    
    async def mock_get(url, *args, **kwargs):
        if "openfoodfacts" in url:
            # Simulate NOT found on Open Food Facts
            return Response(404)
        elif "duckduckgo" in url:
            # Return search results
            return Response(200, text=mock_ddg_html)
        return Response(404)
        
    async def mock_post(url, *args, **kwargs):
        # Simulate Gemini 429 error
        return Response(429, text="Rate limit exceeded")
        
    with patch("httpx.AsyncClient.get", side_effect=mock_get), \
         patch("httpx.AsyncClient.post", side_effect=mock_post):
         
        # We query the barcode
        item = await service.lookup_barcode("8901491101831")
        
        assert item is not None
        assert item.name == "Lays Magic Masala Chips"
        assert item.brand == "Lays"
        assert item.barcode == "8901491101831"
        # Since Gemini returned 429 and local DB has no matching "Lays" items,
        # it should fall back to baseline defaults:
        assert item.calories_per_100g == 120.0  # Baseline calories
        assert item.source == FoodSource.BARCODE


@pytest.mark.asyncio
async def test_lookup_barcode_not_found(db: AsyncSession):
    """Test lookup of invalid barcode that is neither on OFF nor on the web."""
    service = FoodService(db)
    
    # Mock DDG results indicating no matches:
    mock_ddg_html_empty = """
    <html>
        <body>
            <span class="no-results">No results found for 8904063214461</span>
        </body>
    </html>
    """
    
    async def mock_get(url, *args, **kwargs):
        if "openfoodfacts" in url:
            return Response(404)
        elif "duckduckgo" in url:
            return Response(200, text=mock_ddg_html_empty)
        return Response(404)
        
    async def mock_post(url, *args, **kwargs):
        return Response(429, text="Rate limit exceeded")
        
    with patch("httpx.AsyncClient.get", side_effect=mock_get), \
         patch("httpx.AsyncClient.post", side_effect=mock_post):
        item = await service.lookup_barcode("8904063214461")
        
        # Should fail gracefully and return None
        assert item is None
