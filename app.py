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
