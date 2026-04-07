from pydantic import BaseModel
from datetime import datetime

# Схема для получения данных от клиента (Flutter)
class UserCreate(BaseModel):
    username: str
    password: str

# Схема для отправки данных обратно клиенту
class UserResponse(BaseModel):
    id: int
    username: str
    created_at: datetime

    # Эта настройка позволяет Pydantic читать данные прямо из моделей SQLAlchemy
    class Config:
        from_attributes = True

class Token(BaseModel):
    access_token: str
    token_type: str