# Estágio único usando uma imagem leve
FROM python:3.11-slim

# Definir diretório de trabalho
WORKDIR /app

# Copiar apenas os requisitos primeiro (aproveitamento de cache do Docker)
COPY requirements.txt .

# Instalar dependências sem salvar cache local (diminui o tamanho da imagem)
RUN pip install --no-cache-dir -r requirements.txt

# Copiar o resto do código da aplicação
COPY app.py .

# Criar um usuário não-privilegiado e mudar o dono dos arquivos
RUN useradd -m appuser && chown -R appuser:appuser /app
USER appuser

# Expor a porta que a aplicação vai rodar
EXPOSE 8000

# Comando para iniciar a API
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
