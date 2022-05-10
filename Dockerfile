FROM node:12.18.1

WORKDIR /ecs-demo

COPY ["app.js", "package.json", "package-lock.json", "."]

RUN npm install

CMD ["node", "app.js"]

