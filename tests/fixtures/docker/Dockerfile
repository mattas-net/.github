# Minimal image for the docker-build-push self-test (build only, never pushed).
FROM alpine:3.22
COPY hello.txt /hello.txt
USER 65534
CMD ["cat", "/hello.txt"]
