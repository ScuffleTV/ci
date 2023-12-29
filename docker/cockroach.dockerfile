FROM cockroachdb/cockroach:latest

COPY docker/entrypoint.sh /scuffle-entrypoint.sh

ENTRYPOINT [ "/scuffle-entrypoint.sh", "/cockroach/cockroach.sh" ]
