#!/usr/bin/env bash

set -euo pipefail

# Download CockroachDB. NB: currently this uses an alpha, due to feature requirements.
VERSION=v2.0-alpha.20171218
wget -qO- https://binaries.cockroachdb.com/cockroach-$VERSION.linux-amd64.tgz | tar  xvz
readonly COCKROACH=./cockroach-$VERSION.linux-amd64/cockroach
# Make sure cockroach can be found on the path. This is required for the
# ActiveRecord Rakefile that rebuilds the test database.
export PATH=$(pwd)/cockroach-$VERSION.linux-amd64/:$PATH
readonly urlfile=cockroach-url

# Start a CockroachDB server, wait for it to become ready, and arrange for it to
# be force-killed when the script exits.
rm -f "$urlfile"
# Clean out a past CockroachDB instance. This happens if a build was
# canceled on an agent.
pkill cockroach || true
rm -rf cockroach-data
# Start CockroachDB.
cockroach start --insecure --host=localhost --listening-url-file="$urlfile" &
trap "echo 'Exit routine: Killing CockroachDB.' && kill -9 $! &> /dev/null" EXIT
for i in {0..3}
do
  [[ -f "$urlfile" ]] && break
  backoff=$((2 ** i))
  echo "server not yet available; sleeping for $backoff seconds"
  sleep $backoff
done

# Target the Rails dependency file.
export BUNDLE_GEMFILE=$(pwd)/rails/Gemfile

# Install ruby dependencies.
bundle install

# 'Install' our adapter. This involves symlinking it inside of
# ActiveRecord. Normally the adapter will transitively install
# ActiveRecord, but we need to execute tests from inside the Rails
# context so we cannot rely on that. We also need previous links to make
# tests idempotent.
rm -f rails/activerecord/lib/active_record/connection_adapters/cockroachdb_adapter.rb
ln -s $(pwd)/lib/active_record/connection_adapters/cockroachdb_adapter.rb rails/activerecord/lib/active_record/connection_adapters/cockroachdb_adapter.rb
rm -rf rails/activerecord/lib/active_record/connection_adapters/cockroachdb
ln -s $(pwd)/lib/active_record/connection_adapters/cockroachdb rails/activerecord/lib/active_record/connection_adapters/cockroachdb

# Run the tests.
cp build/config.teamcity.yml rails/activerecord/test/config.yml
echo "Rebuilding database"
(cd rails/activerecord && bundle exec rake db:cockroachdb:rebuild)
echo "Starting tests"
(cd rails/activerecord && bundle exec rake test:cockroachdb)

# Attempt a clean shutdown for good measure. We'll force-kill in the atexit
# handler if this fails.
cockroach quit --insecure
trap - EXIT
