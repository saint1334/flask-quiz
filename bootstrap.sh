# Инициализация базы данных
python3 -c "from app import app, db; with app.app_context(): db.create_all()"

# Git init и пуш
git init
git remote add origin https://github.com/saint1334/flask-quiz.git
git add .
git commit -m 'Initial commit'
git push origin main

