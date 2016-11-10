#!/bin/bash

export SECRET_KEY_BASE=$(bundle exec rake secret)

bundle exec rake db:create db:migrate db:seed
bundle exec rails server -p 3000 -b 0.0.0.0
