from fastapi import FastAPI, Depends
import sqlite3
import os

app = FastAPI(title="DevSecOps Lab API")
print("--- Inicializando App do Laboratório DevSecOps ---")

# Banco de dados em memória para testes rápidos
def get_db():
    conn = sqlite3.connect(":memory:")
    cursor = conn.cursor()
    cursor.execute("CREATE TABLE users (id INTEGER, username TEXT, password TEXT)")
    cursor.execute("INSERT INTO users VALUES (1, 'admin', 'admin123')")
    conn.commit()
    try:
        yield cursor
    finally:
        conn.close()

@app.get("/")
def read_root():
    return {"status": "healthy", "message": "Pipeline DevSecOps Ativo e Seguro!"}

# Query parametrizada 100% segura contra SQL Injection
@app.get("/login")
def login(username: str, db = Depends(get_db)):
    # O caractere '?' age como um placeholder. O SQLite garante que o input
    # será tratado estritamente como um dado, e nunca como código executável.
    query = "SELECT * FROM users WHERE username = ?"
    db.execute(query, (username,))
    user = db.fetchone()
    if user:
        return {"success": True, "user": user[1]}
    return {"success": False, "message": "Usuário não encontrado"}
