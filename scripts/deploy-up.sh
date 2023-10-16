#!/bin/bash

echo "Deployment Started"

if [ -x "$(command -v docker-compose)" ]; then
  docker-compose --env-file .env up -d --force-recreate
else
  docker compose --env-file .env up -d --force-recreate
fi

echo "Deployment Completed"
