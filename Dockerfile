FROM python:3.7 AS base

ENV LANG C.UTF-8
ENV PYTHONUNBUFFERED=1

USER root
# RUN useradd --create-home locust

WORKDIR /locust
# ENTRYPOINT ["locust"]
COPY docker/* docker/

RUN apt-get update \
  && apt-get install --no-install-recommends -y python3.7-distutils \
  && apt-get install --no-install-recommends -y $(cat docker/build-pkgs.txt) \
  && rm -rf /root/.cache \
  && apt-get -q autoremove \
  && apt-get -q clean -y \
  && rm -rf /var/lib/apt/lists/* \
  && rm -f /var/cache/apt/*.bin \
  && find . | grep -E "(__pycache__|\.pyc|\.pyo$)" | xargs -r rm -rf
# USER locust
COPY requirements.txt /locust
RUN pip install -r requirements.txt
COPY . /locust
EXPOSE 8089 5557