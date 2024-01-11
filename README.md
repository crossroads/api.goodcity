# GoodCity API
[![Circle CI](https://circleci.com/gh/crossroads/api.goodcity.svg?style=svg)](https://circleci.com/gh/crossroads/api.goodcity)
[![Code Climate](https://codeclimate.com/github/crossroads/api.goodcity/badges/gpa.svg)](https://codeclimate.com/github/crossroads/api.goodcity)
[![Test Coverage](https://codeclimate.com/github/crossroads/api.goodcity/badges/coverage.svg)](https://codeclimate.com/github/crossroads/api.goodcity)

The GoodCity server is a [rails-api](https://github.com/rails-api/rails-api) based JSON API server for the GoodCity.hk project.

It provides a set of database models, validations, relationships, tests and JSON API endpoints for interaction with frontend Ember web-apps and mobile apps.

## Prerequisties

* ruby 2.7 ([rvm](http://rvm.io/) can make this easy)
* [postgresql](http://www.postgresql.org/) (v12 or greater)
* [socket.io-webservice](https://github.com/crossroads/socket.io-webservice)
* [redis](http://redis.io/)

## Installation

Clone this repository and run the following commands:

    sudo apt install libpq-dev
    bundle install
    rake db:create db:migrate db:seed sidekiq:clear

Then bootup your rails console and you should have a DB with data.

In production mode, you will also need a local redis server, type one of the following:

    yum install redis (RedHat)
    apt-get install redis (Debian)
    brew install redis (Mac OS X with Homebrew)

## Development

    rake db:create
    rake db:schema:load / rake db:migrate
    rake db:seed
    rake db:demo

## Tests

    RAILS_ENV=test rake db:schema:load / rake db:migrate
    rake

For individual specs, use rspec

    rspec spec/serializers
    rspec spec/serializers/district_serializer_spec.rb:9

## Background Jobs

Using the ActiveJob gem, some jobs are queued in Redis and then run later using Sidekiq workers.
For example, Twilio SMS, exception notification, and email delivery.

In development mode, use

    bundle exec sidekiq

to start the sidekiq worker. Configuration is set in ```config/sidekiq.yml```

You can also view the sidekiq jobs dashboard by running the crossroads/docker-sidekiq-web repo (see https://github.com/crossroads/docker-sidekiq-web).

## Foreman

You can run each component individually (useful for debugging) or use ```foreman``` to get everything up and running at once.
The following command will start the ```rails server```, ```sidekiq workers``` and the ```socket.io-webservice``` (assuming it is located in ../socket.io-webservice folder)

    foreman start

## Deployment

Commit all changes to master or live branch and push to GitHub. CircleCI will pick up the changes and run specs and deploy automatically.

For manual deployment, ensure the code is pushed to GitHub and then type:

    bundle exec cap production deploy
    bundle exec cap staging deploy

This will deploy changes to api.goodcity.hk or api-staging.goodcity.hk (make sure your ssh keys are loaded)

You can also run rake tasks on staging or live using Capistrano. For example, to shrink uploaded Cloudinary images, use:

    bundle exec cap production invoke:rake TASK=cloudinary:optimize
    bundle exec cap production invoke:rake TASK=db:demo MULTIPLE=100


### Resetting up the staging database

This step might require kill additional db connections

```bash
systemctl stop nginx sidekiq
rake db:drop RAILS_ENV=staging
rake db:create RAILS_ENV=staging
rake db:migrate RAILS_ENV=staging
psql --host=<DB_HOST> --username=<DB_USER> -W goodcity_server_staging < /opt/rails/goodcity_server/shared/dump-goodcity_server_staging-202006041601.sql
systemctl start nginx sidekiq
```

## Docker

Note: the staging environment currently runs on Azure as a suite of docker containers.

You can build the docker image using the following commands. You will need to enter a valid GITHUB_TOKEN which will provide access to the private repos. See https://github.com/settings/tokens

```
export GITHUB_TOKEN=...
docker build --build-arg GITHUB_TOKEN -t api.goodcity .
docker run -p 3000:3000 --env-file .env.staging api.goodcity

docker login <registry>.azurecr.io
docker tag api.goodcity <registry>.azurecr.io/api.goodcity:master
docker push <registry>.azurecr.io/api.goodcity:master
docker push <registry>.azurecr.io/api.goodcity:live
```

Alternatively, you can use the ACR cloud service to build the image.

```
az acr build --build-arg GITHUB_TOKEN --registry goodregistry --image api.goodcity:master .
```

## Documentation

* API documentation is available online at http://api.goodcity.hk/api/docs
* Generate model/controller documentation using Railroady. Note: you must have [graphviz](http://www.graphviz.org/) packages installed on your machine first.

    gem install railroady
    rake diagram:all

To update documentation examples ensure test has `:show_in_doc` and then run:

    APIPIE_RECORD=examples rspec                                *for all tests*
    APIPIE_RECORD=examples rspec spec/models/offer_spec.rb:29   *for specific test*

To update specific model diagrams, use the following commands:

    railroady --hide-magic -M -j -t -s app/models/order*,app/models/stockit_local_order* | dot -Tpng > doc/models_orders.png
    railroady --hide-magic -M -j -t -s app/models/package.rb,app/models/pallet*,app/models/box*,app/models/item*,app/models/package_type*,app/models/packages_location.rb | dot -Tpng > doc/models_packages.png
    railroady --hide-magic -M -j -t -s app/models/package.rb,app/models/item.rb,app/models/offer.rb,app/models/message.rb,app/models/user.rb,app/models/delivery.rb,app/models/schedule.rb,app/models/address.rb,app/models/contact.rb | dot -Tpng > doc/models_offers.png
    railroady --hide-magic -M -j -t -s app/models/user.rb,app/models/role.rb,app/models/permission.rb,app/models/role_permission.rb,app/models/user_role.rb,app/models/auth_token.rb,app/models/organisation.rb,app/models/organisations_user.rb,app/models/address.rb | dot -Tpng > doc/models_users.png

## License

Copyright © 2022 by [Crossroads Foundation Ltd](https://www.crossroads.org.hk)

All rights reserved. No part of this software may be reproduced, distributed, or transmitted in any form or by any means, including photocopying, recording, or other electronic or mechanical methods, without the prior written permission of Crossroads Foundation Ltd. For permission requests, write to Crossroads Foundation Ltd., addressed “Attention: CTO” using the general contact details found on [www.crossroads.org.hk](https://www.crossroads.org.hk).
