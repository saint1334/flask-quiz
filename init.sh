#!/bin/bash
sudo chown -R $USER:$USER helm-chart
chmod -R u+w helm-chart


# Flask app
mkdir -p templates static routes
touch app.py models.py config.py requirements.txt
echo "Flask==2.3.2\nFlask-SQLAlchemy\nFlask-Login" > requirements.txt

# Minimal app.py
cat <<EOF > app.py
from flask import Flask, render_template
app = Flask(__name__)
@app.route('/')
def index():
    return "Flask quiz app is running!"
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
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
mkdir -p helm-chart/templates
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
mkdir -p .github/workflows
cat <<EOF > .github/workflows/deploy.yaml
name: Deploy to Kubernetes
on:
  push:
    branches: [main]
jobs:
  build-and-deploy:
    runs-on: ubuntu
EOF

