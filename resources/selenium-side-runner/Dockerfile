#FROM node:10-alpine
FROM node:22-alpine

ENV SE_HOST="${SE_HOST}"

RUN npm install -g selenium-side-runner

COPY docker-entrypoint.sh /opt/bin/docker-entrypoint.sh
RUN chmod +x /opt/bin/docker-entrypoint.sh

RUN mkdir /sides

WORKDIR /root

VOLUME [ "/sides" ]

ENTRYPOINT ["/opt/bin/docker-entrypoint.sh"]
