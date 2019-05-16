FROM node:10.15.3
WORKDIR /app
ADD package.json package-lock.json ./
RUN npm install -p
COPY ./ ./
CMD ["node", "app"]

