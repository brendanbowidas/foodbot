docker-machine env forevermark-staging;
eval $(docker-machine env forevermark-staging);
docker stop app;
docker-compose rm -v;
docker-compose kill;
docker-compose build && docker-compose up -d;
