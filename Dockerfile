# Dockerfile for garbonzo

FROM python:3.9-alpine

ENV PIP_CACHE_DIR=/tmp/.cache PIPENV_CACHE_DIR=/tmp/.cache

RUN addgroup -S -g 1000 garbonzo \
    && adduser -h /home/garbonzo -g "User account for running garbonzo" \
    -s /sbin/nologin -S -D -G garbonzo -u 1000 garbonzo

USER garbonzo

COPY --chown=garbonzo:garbonzo src /garbonzo

WORKDIR /garbonzo

RUN pip install pipenv==2020.11.15 \
    && python -m pipenv install --deploy \
    && rm -rf /tmp/.cache/*

ENTRYPOINT ["python", "-m", "pipenv", "run"]
CMD ["gunicorn", "-b", "0.0.0.0:8000", "--workers=2", "--access-logfile", "-", "--capture-output", "app:app"]
