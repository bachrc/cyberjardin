FROM node:20-slim as builder
WORKDIR /usr/src/app
COPY package.json .
COPY package-lock.json* .
RUN npm ci

FROM node:20-slim
WORKDIR /usr/src/app
RUN apt update && apt install -y git
COPY --from=builder /usr/src/app/ /usr/src/app/
COPY . .
COPY .git/ ./.git/
CMD ["npx", "quartz", "build", "--serve"]