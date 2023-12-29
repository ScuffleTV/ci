FROM redis:latest

COPY docker/entrypoint.sh /scuffle-entrypoint.sh

ENTRYPOINT [ "/scuffle-entrypoint.sh", "docker-entrypoint.sh" ]
CMD [ "redis-server" ]
