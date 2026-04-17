from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy.orm import Session
import json
from fastapi import WebSocket, WebSocketDisconnect
import models
import schemas
from database import engine, get_db
from database import engine, get_db, SessionLocal
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
from typing import Optional
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

# Указываем FastAPI, где искать токен (в заголовке Authorization)
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="login")

# Функция-зависимость: расшифровывает токен и возвращает текущего пользователя
def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        if username is None:
            raise credentials_exception
    except jwt.PyJWTError: # Обрати внимание: если вернулся к PyJWT, используй это исключение
        raise credentials_exception
        
    user = db.query(models.User).filter(models.User.username == username).first()
    if user is None:
        raise credentials_exception
    return user

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
@app.post("/register", response_model=schemas.Token)
def register_user(user: schemas.UserCreate, db: Session = Depends(get_db)):
    # 1. Проверяем, не занят ли ник
    db_user = db.query(models.User).filter(models.User.username == user.username).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Username already registered")
    
    # 2. Сохраняем нового пользователя с телефоном
    # В идеале здесь должен быть hashed_password = get_password_hash(user.password)
    # Но если у тебя пока простые пароли:
    new_user = models.User(
        username=user.username, 
        hashed_password=user.password, # Замени на хэш, если настроил bcrypt
        phone_number=user.phone_number
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    
    # 3. Сразу авторизуем его и выдаем токен
    access_token = create_access_token(data={"sub": new_user.username})
    return {"access_token": access_token, "token_type": "bearer"}

# Получить список пользователей с возможностью поиска
@app.get("/users", response_model=list[schemas.UserPublic])
def get_users(search: Optional[str] = None, skip: int = 0, limit: int = 100, current_user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    # Базовый запрос: ищем всех, кроме самого себя
    query = db.query(models.User).filter(models.User.id != current_user.id)
    
    # Если пришел текст для поиска — фильтруем по никнейму
    if search:
        query = query.filter(models.User.username.ilike(f"%{search}%"))
        
    users = query.offset(skip).limit(limit).all()
    return users

# Получить список чатов текущего пользователя
# Получить список чатов текущего пользователя
@app.get("/chats", response_model=list[schemas.ChatResponse])
def get_my_chats(current_user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    # Находим все связи, где состоит текущий пользователь
    chat_members = db.query(models.ChatMember).filter(models.ChatMember.user_id == current_user.id).all()
    
    result = []
    for member in chat_members:
        chat = member.chat
        
        # Копируем данные чата в словарь, чтобы безопасно их изменить для ответа
        chat_info = {
            "id": chat.id,
            "is_group": chat.is_group,
            "name": chat.name
        }
        
        # Если чат личный, находим имя собеседника
        if not chat.is_group:
            # Ищем в этом же чате участника, ID которого НЕ равен нашему
            other_member = db.query(models.ChatMember).filter(
                models.ChatMember.chat_id == chat.id,
                models.ChatMember.user_id != current_user.id
            ).first()
            
            # Если собеседник найден, берем его username
            if other_member:
                chat_info["name"] = other_member.user.username
                
        result.append(chat_info)
        
    return result

# Начать новый диалог
# Начать новый диалог (с защитой от дубликатов)
@app.post("/chats", response_model=schemas.ChatResponse)
def create_chat(chat_data: schemas.ChatCreate, current_user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    
    # 1. Проверяем, существует ли целевой юзер
    target_user = db.query(models.User).filter(models.User.id == chat_data.target_user_id).first()
    if not target_user:
        raise HTTPException(status_code=404, detail="User not found")

    # --- НАЧАЛО НОВОЙ ЛОГИКИ: ПРОВЕРКА НА СУЩЕСТВУЮЩИЙ ЧАТ ---
    if not chat_data.is_group:
        # Шаг А: Получаем "список" (подзапрос) ID всех чатов, где состою Я
        my_chat_ids = db.query(models.ChatMember.chat_id).filter(
            models.ChatMember.user_id == current_user.id
        ).subquery()
        
        # Шаг Б: Ищем чат, который: 1) есть в моем списке, 2) является личным, 3) содержит нужного собеседника
        existing_chat = db.query(models.Chat).join(models.ChatMember).filter(
            models.Chat.id.in_(my_chat_ids),
            models.Chat.is_group == False,
            models.ChatMember.user_id == target_user.id
        ).first()

        # Если такой чат уже существует — просто отдаем его клиенту, прерывая функцию
        if existing_chat:
            return existing_chat
    # --- КОНЕЦ НОВОЙ ЛОГИКИ ---

    # 2. Если такого чата еще нет, создаем новую запись в БД
    new_chat = models.Chat(is_group=chat_data.is_group, name=chat_data.name)
    db.add(new_chat)
    db.commit()
    db.refresh(new_chat)

    # 3. Добавляем участников в связующую таблицу
    member1 = models.ChatMember(chat_id=new_chat.id, user_id=current_user.id)
    member2 = models.ChatMember(chat_id=new_chat.id, user_id=target_user.id)
    db.add_all([member1, member2])
    db.commit()

    return new_chat

# --- WEBSOCKETS (Реальное время) ---

# Диспетчер соединений: следит за тем, кто в каком чате находится
class ConnectionManager:
    def __init__(self):
        # Словарь: ID чата -> список активных WebSocket-соединений
        self.active_connections: dict[int, list[WebSocket]] = {}

    async def connect(self, websocket: WebSocket, chat_id: int):
        await websocket.accept()
        if chat_id not in self.active_connections:
            self.active_connections[chat_id] = []
        self.active_connections[chat_id].append(websocket)

    def disconnect(self, websocket: WebSocket, chat_id: int):
        if chat_id in self.active_connections:
            self.active_connections[chat_id].remove(websocket)
            if not self.active_connections[chat_id]:
                del self.active_connections[chat_id]

    async def broadcast(self, message: str, chat_id: int):
        if chat_id in self.active_connections:
            for connection in self.active_connections[chat_id]:
                await connection.send_text(message)

manager = ConnectionManager()

# Получить историю сообщений конкретного чата
@app.get("/chats/{chat_id}/messages")
def get_chat_messages(chat_id: int, current_user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    # Вытаскиваем все сообщения этого чата, отсортированные по времени
    messages = db.query(models.Message).filter(models.Message.chat_id == chat_id).order_by(models.Message.id).all()
    
    # Формируем ответ точно в таком же формате, в каком работает наш WebSocket
    result = []
    for msg in messages:
        sender = db.query(models.User).filter(models.User.id == msg.sender_id).first()
        result.append({
            "sender": sender.username,
            "text": msg.text
        })
    return result

# Сам эндпоинт, к которому будет подключаться Flutter
@app.websocket("/ws/{chat_id}")
async def websocket_endpoint(websocket: WebSocket, chat_id: int, token: str):
    # Открываем независимую сессию БД для этого подключения
    db = SessionLocal() 
    try:
        # 1. Расшифровываем токен и находим пользователя
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username = payload.get("sub")
        if username is None:
            await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
            return
            
        user = db.query(models.User).filter(models.User.username == username).first()
        if not user:
            await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
            return

        # 2. Подключаем пользователя
        await manager.connect(websocket, chat_id)
        
        while True:
            # 3. Ждем сообщение от клиента
            data = await websocket.receive_text()
            
            # --- НОВОЕ: СОХРАНЯЕМ В БАЗУ ---
            new_msg = models.Message(chat_id=chat_id, sender_id=user.id, text=data)
            db.add(new_msg)
            db.commit()
            # -------------------------------
            
            # 4. Рассылаем всем
            message_data = json.dumps({"sender": username, "text": data})
            await manager.broadcast(message_data, chat_id)
            
    except WebSocketDisconnect:
        manager.disconnect(websocket, chat_id)
    finally:
        db.close() # Обязательно закрываем соединение с БД при выходе