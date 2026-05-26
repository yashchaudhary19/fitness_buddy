from pydantic import BaseModel
from typing import Generic, TypeVar, List, Optional

T = TypeVar("T")

class ResponseEnvelope(BaseModel, Generic[T]):
    success: bool = True
    data: Optional[T] = None
    message: Optional[str] = None

class ErrorResponseEnvelope(BaseModel):
    success: bool = False
    error: str
    detail: str

class PaginatedData(BaseModel, Generic[T]):
    data: List[T]
    total: int
    page: int
    limit: int
    has_next: bool
