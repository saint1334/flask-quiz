# Инициализация базы данных
python3 -c "from app import app, db; with app.app_context(): db.create_all()"

# Git init и пуш
git init
git remote add origin https://github.com/saint1334/flask-quiz.git
git add .
git commit -m 'Initial commit'
git push origin main

#!/bin/bash

# Создание структуры
mkdir -p templates static routes helm-chart/templates .github/workflows

# requirements.txt
echo -e "Flask==2.3.2\nFlask-SQLAlchemy\nFlask-Login" > requirements.txt

# app.py
cat <<EOF > app.py
from flask import Flask, render_template, request
from flask_sqlalchemy import SQLAlchemy
from datetime import datetime

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///quiz.db'
db = SQLAlchemy(app)

class Question(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    text = db.Column(db.String(255))
    correct_answer = db.Column(db.String(255))

class UserAttempt(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(64))
    score = db.Column(db.Integer)
    timestamp = db.Column(db.DateTime, default=datetime.utcnow)

@app.route('/')
def index():
    return "Flask quiz app is running!"

@app.route('/quiz')
def quiz():
    questions = Question.query.all()
    return render_template('quiz.html', questions=questions)

@app.route('/submit', methods=['POST'])
def submit():
    answers = request.form
    score = 0
    for q in Question.query.all():
        if answers.get(str(q.id)) == q.correct_answer:
            score += 1
    attempt = UserAttempt(username="guest", score=score)
    db.session.add(attempt)
    db.session.commit()
    return f"Your score: {score}"

if __name__ == '__main__':
    with app.app_context():
        db.create_all()
    app.run(host='0.0.0.0', port=5000)
EOF

# quiz.html
cat <<EOF > templates/quiz.html
<!DOCTYPE html>
<html>
<head><title>Quiz</title></head>
<body>
  <form method="POST" action="/submit">
    {% for q in questions %}
      <p>{{ q.text }}</p>
      <input type="text" name="{{ q.id }}">
    {% endfor %}
    <button type="submit">Submit</button>
  </form>
</body>
</html>
EOF

# Dockerfile
cat <<EOF > Dockerfile
FROM python:3.10
WORKDIR /app
COPY . /app
RUN pip install -r requirements.txt
CMD ["python", "app.py"]
EOF

# Helm Chart
cat <<EOF > helm-chart/Chart.yaml
apiVersion: v2
name: flask-quiz
version: 0.1.0
EOF

cat <<EOF > helm-chart/values.yaml
image:
  repository: saint1334/flask-quiz
  tag: latest
service:
  type: NodePort
  port: 80
  targetPort: 5000
  nodePort: 30500
EOF

cat <<EOF > helm-chart/templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: flask-quiz
spec:
  replicas: 1
  selector:
    matchLabels:
      app: flask-quiz
  template:
    metadata:
      labels:
        app: flask-quiz
    spec:
      containers:
        - name: flask-quiz
          image: {{ .Values.image.repository }}:{{ .Values.image.tag }}
          ports:
            - containerPort: {{ .Values.service.targetPort }}
EOF

cat <<EOF > helm-chart/templates/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: flask-quiz
spec:
  type: {{ .Values.service.type }}
  selector:
    app: flask-quiz
  ports:
    - port: {{ .Values.service.port }}
      targetPort: {{ .Values.service.targetPort }}
      nodePort: {{ .Values.service.nodePort }}
EOF

# CI/CD workflow
cat <<EOF > .github/workflows/deploy.yaml
name: Deploy to Kubernetes
on:
  push:
    branches: [main]
jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      - name: Log in to Docker Hub
        uses: docker/login-action@v2
        with:
          username: \${{ secrets.DOCKER_USERNAME }}
          password: \${{ secrets.DOCKER_PASSWORD }}
      - name: Build Docker image
        run: docker build -t saint1334/flask-quiz:latest -f Dockerfile .
      - name: Push Docker image
        run: docker push saint1334/flask-quiz:latest
      - name: Set up kubectl
        uses: azure/setup-kubectl@v3
      - name: Set up Helm
        uses: azure/setup-helm@v3
      - name: Configure kubeconfig
        run: |
          mkdir -p ~/.kube
          echo "\${{ secrets.KUBE_CONFIG }}" > ~/.kube/config
      - name: Deploy with Helm
        run: |
          helm upgrade --install flask-quiz ./helm-chart \
            --set image.repository=saint1334/flask-quiz \
            --set image.tag=latest
EOF

# Git init
git init
git remote add origin https://github.com/saint1334/flask-quiz.git
git add .
git commit -m "Initial commit"
git push origin main

