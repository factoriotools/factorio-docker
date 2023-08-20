FROM dtandersen/factorio:latest

RUN apk add --update python py-pip
RUN pip install awscli

COPY fargate-entrypoint.sh fargate-entrypoint.sh

ENTRYPOINT ["/fargate-entrypoint.sh"]
