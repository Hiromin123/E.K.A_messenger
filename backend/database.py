from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker

# Указываем путь к файлу БД. Он будет создан прямо в папке backend.
SQLALCHEMY_DATABASE_URL = "sqlite:///./messenger.db"

# connect_args={"check_same_thread": False} — это специфичный костыль для SQLite в FastAPI.
# По умолчанию SQLite запрещает использовать одно подключение в разных потоках, 
# а FastAPI под капотом обрабатывает запросы асинхронно в разных потоках.
engine = create_engine(
    SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False}
)

# Создаем класс сессии, который будет генерировать подключения к БД
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Базовый класс, от которого будут наследоваться все наши модели (таблицы)
Base = declarative_base()

# Зависимость (Dependency) для FastAPI, чтобы получать сессию БД в эндпоинтах``
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()