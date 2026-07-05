import json
import logging
import os
import sys
import threading
import time

from confluent_kafka import Consumer
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import create_engine, text


class JsonFormatter(logging.Formatter):
    def format(self, record):
        payload = {
            "timestamp": self.formatTime(record, "%Y-%m-%dT%H:%M:%S%z"),
            "level": record.levelname,
            "service": "activity-service",
            "logger": record.name,
            "message": record.getMessage(),
        }
        for key in ("method", "path", "status_code", "duration_ms", "topic", "user_id", "activity_type"):
            value = getattr(record, key, None)
            if value is not None:
                payload[key] = value
        return json.dumps(payload)


handler = logging.StreamHandler(sys.stdout)
handler.setFormatter(JsonFormatter())
logging.basicConfig(level=os.getenv("LOG_LEVEL", "INFO"), handlers=[handler], force=True)
logger = logging.getLogger("activity-service")

DATABASE_URL = os.getenv("DATABASE_URL")
KAFKA_BOOTSTRAP_SERVERS = os.getenv("KAFKA_BOOTSTRAP_SERVERS", "kafka:29092")
FRONTEND_ORIGIN = os.getenv("FRONTEND_ORIGIN", "http://localhost:3000")

if not DATABASE_URL:
    raise RuntimeError("DATABASE_URL is required")

engine = create_engine(f"postgresql+psycopg2://{DATABASE_URL.split('://', 1)[1]}")

app = FastAPI(title="Techbleat Global Bank - Activity Service")

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


def kafka_consumer_loop():
    consumer = None
    while consumer is None:
        try:
            consumer = Consumer(
                {
                    "bootstrap.servers": KAFKA_BOOTSTRAP_SERVERS,
                    "group.id": "activity-service-group",
                    "auto.offset.reset": "earliest",
                }
            )
            consumer.subscribe(["banking-transactions"])
        except Exception:
            time.sleep(3)

    while True:
        try:
            msg = consumer.poll(1.0)
            if msg is None:
                continue
            if msg.error():
                continue

            event = json.loads(msg.value().decode("utf-8"))
            user_id = event.get("userId", "unknown")
            activity_type = event.get("eventType", "UNKNOWN")
            amount = event.get("amount", 0)
            description = f"{activity_type} of {amount} by {user_id}"

            with engine.begin() as conn:
                conn.execute(
                    text(
                        '''
                        INSERT INTO activities (user_id, activity_type, description)
                        VALUES (:user_id, :activity_type, :description)
                        '''
                    ),
                    {
                        "user_id": user_id,
                        "activity_type": activity_type,
                        "description": description,
                    },
                )
            logger.info(
                "activity_recorded",
                extra={
                    "topic": "banking-transactions",
                    "user_id": user_id,
                    "activity_type": activity_type,
                },
            )
        except Exception:
            logger.exception("activity_consumer_error")
            time.sleep(1)


@app.on_event("startup")
def startup_event():
    thread = threading.Thread(target=kafka_consumer_loop, daemon=True)
    thread.start()


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/activities/{user_id}")
def get_activities(user_id: str):
    with engine.begin() as conn:
        rows = conn.execute(
            text(
                '''
                SELECT id, user_id, activity_type, description, created_at
                FROM activities
                WHERE user_id = :user_id
                ORDER BY created_at DESC
                LIMIT 20
                '''
            ),
            {"user_id": user_id},
        ).mappings().all()
        return [dict(row) for row in rows]
