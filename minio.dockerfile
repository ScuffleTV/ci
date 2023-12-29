FROM minio/minio:latest

COPY entrypoint.sh /scuffle-entrypoint.sh

ENTRYPOINT [ "/scuffle-entrypoint.sh", "/usr/bin/docker-entrypoint.sh" ]
CMD [ "minio" ]
