FROM alpine:3.21

RUN apk add --no-cache bash ca-certificates curl coreutils

COPY fetch-gguf /usr/local/bin/fetch-gguf
RUN chmod +x /usr/local/bin/fetch-gguf

ENTRYPOINT ["/usr/local/bin/fetch-gguf"]
