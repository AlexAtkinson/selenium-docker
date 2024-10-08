FROM node:lts-alpine

# make the 'app' folder the current working directory
WORKDIR /app

COPY package.json package.json

RUN npm install

COPY . .

EXPOSE 5173

ENTRYPOINT [ "npm", "run", "dev" ]
