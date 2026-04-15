from pydantic import BaseModel
from datetime import datetime
from typing import Optional
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

# Схема для отображения пользователя в поиске (без паролей и лишних данных)
class UserPublic(BaseModel):
    id: int
    username: str

    class Config:
        from_attributes = True

# Схема для создания нового чата
class ChatCreate(BaseModel):
    is_group: bool = False
    name: Optional[str] = None
    # ID пользователя, с которым хотим начать диалог
    target_user_id: int 

# Схема для ответа со списком чатов
class ChatResponse(BaseModel):
    id: int
    is_group: bool
    name: Optional[str] = None

    class Config:
        from_attributes = True