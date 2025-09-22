FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY flask-quiz/ ./flask-quiz/
CMD ["python", "flask-quiz/app.py"]

