import math
import logging
from fastapi import FastAPI

# Configuração básica de logs para o Filebeat capturar no stdout
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[logging.StreamHandler()]
)
logger = logging.getLogger("api-logger")

app = FastAPI(
    title="DevSecOps Lab API",
    description="API FastAPI com capacidade de estresse de CPU para testes de HPA e Observabilidade.",
    version="2.0.0"
)

@app.get("/")
def read_root():
    logger.info("Requisição recebida em GET / - Iniciando processamento de estresse.")
    
    # Loop de estresse artificial para forçar consumo de CPU real (1 milhão de iterações)
    stress_factor = 0.0001
    for i in range(1000000):
        stress_factor += math.sin(i) * math.cos(i)
        
    logger.info(f"Processamento concluído com sucesso. Fator de estresse calculado: {stress_factor}")
    
    return {
        "status": "healthy",
        "message": "Pipeline DevSecOps Ativo e Seguro!",
        "stress_factor": stress_factor
    }

@app.get("/health")
def health_check():
    # Rota leve de health check caso o Kubernetes precise testar a saúde do Pod sem gerar carga
    return {"status": "UP"}
