FROM node:lts as builderenv

WORKDIR /app

# Install dependencies
RUN apt-get update && apt-get install -y build-essential

# We use Tini to handle signals and PID1
ENV TINI_VERSION v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini

# Copy package files
COPY package.json ./
COPY package-lock.json ./
RUN npm ci

# Build the app
COPY . .
RUN npm run build

# Remove dev dependencies
RUN npm ci --production

########################## END OF BUILD STAGE ##########################

FROM node:lts

# NODE_ENV is used to configure some runtime options
ENV NODE_ENV production

WORKDIR /app
COPY --from=builderenv /app /app
COPY --from=builderenv /tini /tini

EXPOSE 8082

ENTRYPOINT ["/tini", "--"]
CMD [ "/usr/local/bin/node", "--trace-warnings", "--abort-on-uncaught-exception", "--unhandled-rejections=strict", "dist/index.js" ]