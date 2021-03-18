# Dockerfile for garbanzo

FROM python:3.9-alpine

ENV PIP_CACHE_DIR=/tmp/.cache PIPENV_CACHE_DIR=/tmp/.cache

RUN addgroup -S -g 1000 garbanzo \
    && adduser -h /home/garbanzo -g "User account for running garbanzo" \
    -s /sbin/nologin -S -D -G garbanzo -u 1000 garbanzo

USER garbanzo

COPY --chown=garbanzo:garbanzo src /garbanzo

WORKDIR /garbanzo

RUN pip install pipenv==2020.11.15 \
    && python -m pipenv install --deploy \
    && rm -rf /tmp/.cache/*

ENTRYPOINT ["python", "-m", "pipenv", "run"]
CMD ["gunicorn", "-b", "0.0.0.0:8000", "--workers=2", "--access-logfile", "-", "--capture-output", "app:app"]
