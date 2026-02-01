
FROM node:20-alpine AS build

WORKDIR /app


ARG VITE_APP_API_ENDPOINT_URL
ARG VITE_APP_TMDB_V3_API_KEY

ENV VITE_APP_API_ENDPOINT_URL=$VITE_APP_API_ENDPOINT_URL
ENV VITE_APP_TMDB_V3_API_KEY=$VITE_APP_TMDB_V3_API_KEY

# اما نيجي نرن بقا نديله كدا 

# docker build \
#   --build-arg VITE_APP_API_ENDPOINT_URL=https://api.themoviedb.org/3 \
#   --build-arg VITE_APP_TMDB_V3_API_KEY= Hade7olak لسه اهبل انا  \
#   -t netflix-app .


COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile

COPY . .
RUN yarn build

FROM node:20-slim

WORKDIR /app

RUN yarn global add serve

COPY --from=build /app/dist ./dist

EXPOSE 5000

CMD ["serve", "-s", "dist", "-l", "5000"]
