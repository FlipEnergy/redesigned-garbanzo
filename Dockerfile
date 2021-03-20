# Dockerfile for garbanzo

FROM python:3.8-slim-buster

ENV NONROOT_USER garbanzo

RUN addgroup --gid 1000 $NONROOT_USER \
    && useradd -m -g 1000 -s /sbin/nologin -u 1000 $NONROOT_USER \
    && mkdir /garbanzo && chown ${NONROOT_USER}:${NONROOT_USER} /garbanzo

USER $NONROOT_USER

ENV PIP_CACHE_DIR=/tmp/.cache PIPENV_CACHE_DIR=/tmp/.cache PATH=$PATH:/home/garbanzo/.local/bin

COPY --chown=${NONROOT_USER}:${NONROOT_USER} src/Pipfile* /garbanzo/

WORKDIR /garbanzo

RUN pip install pipenv==2020.11.15 \
    && pipenv install --system --deploy \
    && mkdir -p migrations/versions \
    && rm -rf /tmp/.cache/*

# another layer for just source code so pipenv is cached
COPY --chown=${NONROOT_USER}:${NONROOT_USER} src /garbanzo

CMD ["gunicorn", "-b", "0.0.0.0:8000", "--workers=2", "--access-logfile", "-", "--capture-output", "app:app"]
