FROM node:16

WORKDIR /app
RUN npm init --yes \
    && npm install zenn-cli \
    && npx zenn init 
COPY articles articles
COPY books books

ENTRYPOINT ["npx", "zenn", "preview"]

