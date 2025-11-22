FROM python:3.11

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

COPY ./requirements.txt /app/
RUN python3 -m venv env && \
    . env/bin/activate && \
    pip install -r requirements.txt

COPY ../backend /app/backend
COPY ../manage.py /app/
COPY ../base /app/base
COPY ../frontend /app/frontend
COPY ../media/images /app/media/images
COPY ../db.json /app/
COPY ../startup.sh /startup.sh

RUN chmod +x /startup.sh

EXPOSE 7000

ENTRYPOINT ["/startup.sh"]