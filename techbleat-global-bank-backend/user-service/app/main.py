import os
import json
import logging
import sys
import time

from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from prometheus_fastapi_instrumentator import Instrumentator
from pydantic import BaseModel, EmailStr
from sqlalchemy import create_engine, text


class JsonFormatter(logging.Formatter):
    def format(self, record):
        payload = {
            "timestamp": self.formatTime(record, "%Y-%m-%dT%H:%M:%S%z"),
            "level": record.levelname,
            "service": "user-service",
            "logger": record.name,
            "message": record.getMessage(),
        }
        for key in ("method", "path", "status_code", "duration_ms"):
            value = getattr(record, key, None)
            if value is not None:
                payload[key] = value
        return json.dumps(payload)


handler = logging.StreamHandler(sys.stdout)
handler.setFormatter(JsonFormatter())
logging.basicConfig(level=os.getenv("LOG_LEVEL", "INFO"), handlers=[handler], force=True)
logger = logging.getLogger("user-service")

DATABASE_URL = os.getenv("DATABASE_URL")
FRONTEND_ORIGIN = os.getenv("FRONTEND_ORIGIN", "http://localhost:3000")

if not DATABASE_URL:
    raise RuntimeError("DATABASE_URL is required")

engine = create_engine(f"postgresql+psycopg2://{DATABASE_URL.split('://', 1)[1]}")

app = FastAPI(title="Techbleat Global Bank - User Service")
Instrumentator().instrument(app).expose(app, endpoint="/metrics")

app.add_middleware(
    CORSMiddleware,
    allow_origins=[FRONTEND_ORIGIN, "http://127.0.0.1:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.middleware("http")
async def log_requests(request: Request, call_next):
    start = time.perf_counter()
    response = await call_next(request)
    duration_ms = round((time.perf_counter() - start) * 1000, 2)
    logger.info(
        "http_request",
        extra={
            "method": request.method,
            "path": request.url.path,
            "status_code": response.status_code,
            "duration_ms": duration_ms,
        },
    )
    return response


class UserCreate(BaseModel):
    id: str
    full_name: str
    email: EmailStr


@app.get("/health")
def health():
    return {"status": "ok"}


@app.post("/users")
def create_user(user: UserCreate):
    with engine.begin() as conn:
        existing = conn.execute(
            text("SELECT id FROM users WHERE id = :id OR email = :email"),
            {"id": user.id, "email": user.email},
        ).fetchone()

        if existing:
            raise HTTPException(status_code=400, detail="User ID or email already exists")

        conn.execute(
            text(
                '''
                INSERT INTO users (id, full_name, email)
                VALUES (:id, :full_name, :email)
                '''
            ),
            {"id": user.id, "full_name": user.full_name.title(), "email": user.email},
        )

        conn.execute(
            text(
                '''
                INSERT INTO accounts (user_id, balance)
                VALUES (:user_id, 0)
                '''
            ),
            {"user_id": user.id},
        )

    return {"message": "User created successfully", "user_id": user.id}


@app.get("/users")
def list_users():
    with engine.begin() as conn:
        rows = conn.execute(
            text(
                '''
                SELECT id, full_name, email, created_at
                FROM users
                ORDER BY created_at DESC
                '''
            )
        ).mappings().all()
        return [dict(row) for row in rows]
