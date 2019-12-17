#!/bin/bash
docker exec influxdb bash -c "influx -execute 'CREATE DATABASE cadvisor'"
docker exec influxdb bash -c "influx -execute 'SHOW DATABASES'"
