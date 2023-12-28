FROM cockroachdb/cockroach:latest

COPY entrypoint.sh /scuffle-entrypoint.sh

ENTRYPOINT [ "/scuffle-entrypoint.sh", "/cockroach/cockroach.sh" ]
