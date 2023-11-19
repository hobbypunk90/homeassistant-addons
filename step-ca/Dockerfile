ARG BUILD_FROM
ARG BUILD_VERSION
ARG BUILD_ARCH
FROM smallstep/step-ca:${BUILD_VERSION} as builder

FROM ${BUILD_FROM}

ENV LANG C.UTF-8

COPY --from=builder /usr/local/bin/step /usr/local/bin/step
COPY --from=builder /usr/local/bin/step-ca /usr/local/bin/step-ca

COPY start.sh /app/start.sh
ENTRYPOINT ["/app/start.sh"]

HEALTHCHECK CMD step ca health 2>/dev/null | grep "^ok" >/dev/null

LABEL io.hass.version="VERSION" io.hass.type="addon" io.hass.arch="armhf|aarch64|i386|amd64"
