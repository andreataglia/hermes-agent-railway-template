# Hermes Agent on Railway, with the browser-hosted Desktop (Webapp).
#
# Base: the pinned upstream runtime image — Python venv, managed tools,
# Chromium and the prebuilt TUI/dashboard bundles stay untouched.
FROM nousresearch/hermes-agent:v0.22.5@sha256:9c5561579f3ffdf333401797094ac3a743738d6c25d40f4331c7bf77b694238d

# The Webapp ("hermes webapp") merged into the main channel after v0.22.5 and no
# release image carries it yet. Overlay that commit's source, then build the
# browser renderer here: the runtime image is read-only, so the bundle cannot be
# built on boot. Python deps added since the base need no install to import
# (ruamel.yaml.clib is an optional accelerator with a pure-Python fallback).
ARG HERMES_REF=69f73ec5f11f5a945cc864f29c4e2ad2307eaec3

RUN git clone --quiet --no-checkout https://github.com/NousResearch/hermes-agent /tmp/hermes-src \
 && git -C /tmp/hermes-src checkout --quiet --detach "$HERMES_REF" \
 && rm -rf /tmp/hermes-src/.git \
 && cp -a /tmp/hermes-src/. /opt/hermes/ \
 && rm -rf /tmp/hermes-src

# Renders apps/desktop into apps/desktop/dist-webapp (installs its own node deps
# in .build/webapp-workspace, lifecycle scripts disabled, so no Electron build).
RUN cd /opt/hermes/apps/desktop && node scripts/build-webapp.mjs \
 && test -f /opt/hermes/apps/desktop/dist-webapp/index.html

COPY --chmod=0755 docker-entrypoint.sh /usr/local/bin/hermes-railway-entrypoint

ENV HERMES_HOME=/data/.hermes \
    HERMES_WRITE_SAFE_ROOT=/data/.hermes \
    HERMES_LAZY_INSTALL_TARGET=/data/.hermes/lazy-packages \
    HERMES_DASHBOARD=1 \
    HERMES_DASHBOARD_HOST=0.0.0.0 \
    HERMES_GATEWAY_BOOTSTRAP_STATE=running

ENTRYPOINT ["/usr/local/bin/hermes-railway-entrypoint"]
CMD ["gateway", "run"]
