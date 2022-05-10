FROM node:12.18.1

WORKDIR /ecs-demo

COPY . .

RUN npm install

CMD ["node", "app.js"]

