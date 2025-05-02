#!/bin/bash
set -e

# Start Nginx in background (since it's in same container)
service nginx start

# Ensure the database is ready and then migrate
echo "Creating and migrating database..."
bundle exec rails db:create db:migrate

# Start Puma
echo "Starting Puma..."
exec bundle exec puma -C config/puma.rb
