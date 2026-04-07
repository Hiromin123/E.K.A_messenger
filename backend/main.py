from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy.orm import Session

import models
import schemas
from database import engine, get_db
import bcrypt
from datetime import datetime, timedelta
from fastapi import HTTPException, status
import os
import dotenv 
from dotenv import load_dotenv
from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from jose import JWTError, jwt


load_dotenv()

# Создаем таблицы в БД
models.Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Messenger API",
    description="Backend for self-hosted Flutter messenger",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # Разрешаем запросы с любых адресов (в браузере)
    allow_credentials=True,
    allow_methods=["*"], # Разрешаем любые методы (POST, GET, OPTIONS и т.д.)
    allow_headers=["*"], # Разрешаем любые заголовки
)

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

SECRET_KEY = os.getenv("SECRET_KEY")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24 * 7
if not SECRET_KEY:
    raise ValueError("No SECRET_KEY set for FastAPI application")

def get_password_hash(password: str):
    # bcrypt работает только с байтами, поэтому кодируем строку
    pwd_bytes = password.encode('utf-8')
    # Генерируем уникальную "соль" для безопасности
    salt = bcrypt.gensalt()
    # Хешируем
    hashed_password = bcrypt.hashpw(password=pwd_bytes, salt=salt)
    # Возвращаем обратно в виде строки, чтобы SQLAlchemy могла сохранить это в БД
    return hashed_password.decode('utf-8')

def verify_password(plain_password: str, hashed_password: str):
    # Проверяем, совпадает ли введенный пароль с хешем из базы
    return bcrypt.checkpw(
        plain_password.encode('utf-8'), 
        hashed_password.encode('utf-8')
    )

def create_access_token(data: dict):
    to_encode = data.copy()
    # Устанавливаем время жизни токена
    expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    # Генерируем сам токен
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt
@app.get("/")
async def root():
    return {"status": "ok", "message": "Messenger API is running!"}

# --- НОВЫЙ ЭНДПОИНТ РЕГИСТРАЦИИ ---
@app.post("/register", response_model=schemas.UserResponse)
def register_user(user: schemas.UserCreate, db: Session = Depends(get_db)):
    # 1. Проверяем, не занят ли уже такой username
    db_user = db.query(models.User).filter(models.User.username == user.username).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Username already registered")
    
    # 2. Хешируем пароль
    hashed_password = get_password_hash(user.password)
    
    # 3. Создаем объект пользователя для базы данных
    new_user = models.User(username=user.username, hashed_password=hashed_password)
    
    # 4. Сохраняем в базу
    db.add(new_user)
    db.commit()
    db.refresh(new_user) # Обновляем объект, чтобы получить сгенерированный ID
    
    # Возвращаем пользователя (FastAPI сам отфильтрует пароль благодаря schemas.UserResponse)
    return new_user

@app.post("/login", response_model=schemas.Token)
def login_user(user: schemas.UserCreate, db: Session = Depends(get_db)):
    # 1. Ищем пользователя в базе по username
    db_user = db.query(models.User).filter(models.User.username == user.username).first()
    
    # 2. Если пользователя нет или пароль не совпал — выдаем ошибку
    if not db_user or not verify_password(user.password, db_user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
        )
    
    # 3. Если всё верно, генерируем токен, зашивая в него username пользователя
    access_token = create_access_token(data={"sub": db_user.username})
    
    # 4. Возвращаем токен клиенту
    return {"access_token": access_token, "token_type": "bearer"}