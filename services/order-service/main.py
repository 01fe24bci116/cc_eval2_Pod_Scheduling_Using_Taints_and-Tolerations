import os
import psycopg2
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

app = FastAPI(title="CloudOps Resource Request / Order Service", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

DB_HOST = os.getenv("DB_HOST", "postgres-clusterip.cloudops.svc.cluster.local")
DB_NAME = os.getenv("DB_NAME", "cloudops_db")
DB_USER = os.getenv("DB_USER", "postgres_admin")
DB_PASSWORD = os.getenv("DB_PASSWORD", "SecureLabPassword2026!")

class ResourceOrder(BaseModel):
    requester: str
    service_name: str
    cpu_cores: str
    memory_mb: str

def get_db():
    try:
        return psycopg2.connect(
            host=DB_HOST,
            database=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD,
            connect_timeout=3
        )
    except Exception:
        return None

@app.get("/health")
def health():
    conn = get_db()
    status = "connected" if conn else "disconnected"
    if conn:
        conn.close()
    return {"service": "order-service", "status": "healthy", "database": status}

@app.get("/api/orders/requests")
def list_requests():
    conn = get_db()
    if conn:
        try:
            cur = conn.cursor()
            cur.execute("SELECT id, requester, service_name, cpu_cores, memory_mb, status, created_at FROM resource_requests ORDER BY id DESC;")
            rows = cur.fetchall()
            cur.close()
            conn.close()
            return {
                "requests": [
                    {
                        "id": r[0],
                        "requester": r[1],
                        "service_name": r[2],
                        "cpu_cores": r[3],
                        "memory_mb": r[4],
                        "status": r[5],
                        "created_at": str(r[6])
                    } for r in rows
                ]
            }
        except Exception as e:
            print(f"DB Error: {e}")

    # Fallback
    return {
        "requests": [
            {"id": 1, "requester": "DevOps-Lead", "service_name": "order-service", "cpu_cores": "500m", "memory_mb": "512Mi", "status": "Approved", "created_at": "2026-11-15 20:00:00"},
            {"id": 2, "requester": "QA-Team", "service_name": "load-test-runner", "cpu_cores": "1000m", "memory_mb": "1024Mi", "status": "Pending", "created_at": "2026-11-15 20:05:00"},
            {"id": 3, "requester": "DBA", "service_name": "postgres-db-0", "cpu_cores": "250m", "memory_mb": "256Mi", "status": "Dedicated-Tolerated", "created_at": "2026-11-15 20:10:00"}
        ]
    }

@app.post("/api/orders/requests")
def create_request(order: ResourceOrder):
    conn = get_db()
    if conn:
        try:
            cur = conn.cursor()
            cur.execute(
                "INSERT INTO resource_requests (requester, service_name, cpu_cores, memory_mb, status) VALUES (%s, %s, %s, %s, 'Approved') RETURNING id, created_at;",
                (order.requester, order.service_name, order.cpu_cores, order.memory_mb)
            )
            inserted = cur.fetchone()
            conn.commit()
            cur.close()
            conn.close()
            return {
                "id": inserted[0],
                "requester": order.requester,
                "service_name": order.service_name,
                "cpu_cores": order.cpu_cores,
                "memory_mb": order.memory_mb,
                "status": "Approved",
                "created_at": str(inserted[1])
            }
        except Exception as e:
            print(f"Error inserting: {e}")

    return {
        "id": 999,
        "requester": order.requester,
        "service_name": order.service_name,
        "cpu_cores": order.cpu_cores,
        "memory_mb": order.memory_mb,
        "status": "Approved",
        "created_at": "Just now"
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=5003)
