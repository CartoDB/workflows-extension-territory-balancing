#!/bin/bash
set -e

./build-base.sh
cd app
./build-run.sh
bq query --use_legacy_sql=false < _territory_balancing.sql