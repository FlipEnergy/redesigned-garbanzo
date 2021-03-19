# Dockerfile for garbanzo

FROM python:3.8-slim-buster

RUN addgroup --gid 1000 garbanzo \
    && useradd -m -g 1000 -s /sbin/nologin -u 1000 garbanzo

USER garbanzo

ENV PIP_CACHE_DIR=/tmp/.cache PIPENV_CACHE_DIR=/tmp/.cache PATH=$PATH:/home/garbanzo/.local/bin

COPY --chown=garbanzo:garbanzo src /garbanzo

WORKDIR /garbanzo

RUN pip install pipenv==2020.11.15 \
    && pipenv install --system --deploy \
    && rm -rf /tmp/.cache/*

CMD ["gunicorn", "-b", "0.0.0.0:8000", "--workers=2", "--access-logfile", "-", "--capture-output", "app:app"]
