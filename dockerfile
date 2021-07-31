# DON'T UPDATE TO alpine3.13, 1.14, see #41.
FROM node:14-alpine3.12 AS release
WORKDIR /app

# split the sqlite install here, so that it can caches the arm prebuilt
RUN apk add --no-cache --virtual .build-deps make g++ python3 python3-dev && \
            ln -s /usr/bin/python3 /usr/bin/python && \
            npm install sqlite3@5.0.2 bcrypt@5.0.1 && \
            apk del .build-deps

# Touching above code may causes sqlite3 re-compile again, painful slow.

# Install apprise
RUN apk add --no-cache python3 py3-cryptography py3-pip py3-six py3-yaml py3-click py3-markdown py3-requests py3-requests-oauthlib
RUN pip3 install apprise && \
    pip3 cache purge && \
    rm -rf /root/.cache
RUN apprise --version

# New things add here

COPY . .
RUN npm install && npm run build && npm prune

EXPOSE 3001
VOLUME ["/app/data"]
HEALTHCHECK --interval=60s --timeout=30s --start-period=300s CMD node extra/healthcheck.js
CMD ["npm", "run", "start-server"]

FROM release AS nightly
RUN npm run mark-as-nightly
