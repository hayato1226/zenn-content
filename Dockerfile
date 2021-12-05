FROM node:16

WORKDIR /app
RUN npm init --yes \
    && npm install zenn-cli \
    && npx zenn init \
    git clone git@github.com:hayato1226/zenn-content.git

ENTRYPOINT ["npx", "zenn", "preview"]

