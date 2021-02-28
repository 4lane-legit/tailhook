FROM alpine:latest

LABEL maintainer="4-lane legit" \
  name="tailhook" \
  description="Mutates the pod CREATE/UPDATE and injects any sidecar of choice if namespace is labelled" \
  summary="Inserts a sidecar if annotation is placed on the deployment"

# Inspired by the morvencao's work.
ENV BUILD=/usr/local/bin/mutating-sidecar \
  USER_UID=1001 \
  USER_NAME=user-sidecar

COPY build/_output/linux/bin/mutating-sidecar ${BUILD}

ENTRYPOINT ["/usr/local/bin/mutating-sidecar"]

USER ${USER_UID}
