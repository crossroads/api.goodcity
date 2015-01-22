# GoodCity API
[![Circle CI](https://circleci.com/gh/crossroads/api.goodcity.svg?style=svg)](https://circleci.com/gh/crossroads/api.goodcity)
[![Code Climate](https://codeclimate.com/github/crossroads/api.goodcity/badges/gpa.svg)](https://codeclimate.com/github/crossroads/api.goodcity)
[![Test Coverage](https://codeclimate.com/github/crossroads/api.goodcity/badges/coverage.svg)](https://codeclimate.com/github/crossroads/api.goodcity)

The GoodCity server is a [rails-api](https://github.com/rails-api/rails-api) based JSON API server for the GoodCity.hk project.

It provides a set of database models, validations, relationships, tests and JSON API endpoints for interaction with frontend Ember web-apps and mobile apps.

## Prerequisties

* ruby 2.2 ([rvm](http://rvm.io/) can make this easy)
* [postgresql](http://www.postgresql.org/) (v9.4 or greater)
* [socket.io-webservice](https://github.com/crossroads/socket.io-webservice)
* redis

## Installation

Clone this repository and run the following commands:

    bundle install
    rake db:create db:migrate db:seed

Then bootup your rails console and you should have a DB with data.

In production mode, you will also need a local [redis](http://redis.io/) server, type one of the following:

    yum install redis (RedHat)
    apt-get install redis (Debian)
    brew install redis (Mac OS X with Homebrew)

## Tests

Simply run

    rake

For individual specs, use rspec

    rspec spec/serializers
    rspec spec/serializers/district_serializer_spec.rb:9

## Background Jobs

Using the ActiveJob gem, some jobs are queued in Redis and then run later using Sidekiq workers.
For example, Twilio SMS, exception notification (airbrake) and email delivery.

In development mode, use

    bundle exec sidekiq

to start the sidekiq worker. Configuration is set in ```config/sidekiq.yml```

You can also view the sidekiq jobs dashboard at ```/sidekiq``` but must first set

    SIDEKIQ_USERNAME
    SIDEKIQ_PASSWORD

in the ```.env``` file. To prevent accidental data leakage, blank usernames and passwords are not accepted.

## Foreman

You can run each component individually (useful for debugging) or use ```foreman``` to get everything up and running at once.
The following command will start the ```rails server```, ```sidekiq workers``` and the ```socket.io-webservice``` (assuming it is located in ../socket.io-webservice folder)

    foreman start


## Deployment

Using capistrano, commit all changes to master branch and push to github. Then type:

    bundle exec cap production deploy

This will deploy changes to [api.goodcity.hk](http://api.goodcity.hk) (make sure your ssh keys are loaded)

## Documentation

* API documentation is available online at http://api.goodcity.hk/api/docs
* Generate model/controller documentation using the [railroady](https://github.com/preston/railroady) gem. (You must have [graphviz](http://www.graphviz.org/) packages installed on your machine first.)

    gem install railroady
    rake diagram:all

To update documentation examples ensure test has `:show_in_doc` and then run:

    APIPIE_RECORD=examples rspec                                *for all tests*
    APIPIE_RECORD=examples rspec spec/models/offer_spec.rb:29   *for specific test*

## License

Copyright © 2014 by [Crossroads Foundation Ltd](https://www.crossroads.org.hk)

All rights reserved. No part of this software may be reproduced, distributed, or transmitted in any form or by any means, including photocopying, recording, or other electronic or mechanical methods, without the prior written permission of Crossroads Foundation Ltd. For permission requests, write to Crossroads Foundation Ltd., addressed “Attention: CTO” using the general contact details found on [www.crossroads.org.hk](https://www.crossroads.org.hk).
