ARG BASE_TAG=latest
FROM gentoo/portage:$BASE_TAG AS portage
FROM gentoo/stage3:$BASE_TAG AS distcc-builder
COPY --from=portage /var/db/repos/gentoo /var/db/repos/gentoo
RUN emerge -1q distcc
RUN rm -rf /var/cache/distfiles/* /var/db/repos/gentoo/

FROM scratch AS distcc-builder-squashed
COPY --from=distcc-builder / /
ARG BUILD_DATETIME
ARG VCS_REF
LABEL org.opencontainers.image.title="gentoo-distcc" \
      org.opencontainers.image.description="Gentoo Docker image with distcc that can be used to speed up compilation jobs" \
      org.opencontainers.image.authors="Konstantinos Smanis <konstantinos.smanis@gmail.com>" \
      org.opencontainers.image.source="https://github.com/KSmanis/docker-gentoo-distcc" \
      org.opencontainers.image.revision="$VCS_REF" \
      org.opencontainers.image.created="$BUILD_DATETIME"

FROM distcc-builder-squashed AS distcc-tcp
ENTRYPOINT ["distccd", "--daemon", "--no-detach", "--log-level", "notice", "--log-stderr", "--allow-private"]
EXPOSE 3632

FROM distcc-builder-squashed AS distcc-ssh
ENV USER=distcc-ssh
COPY entrypoint-distcc-ssh.sh /
ENTRYPOINT ["/entrypoint-distcc-ssh.sh"]
EXPOSE 22
