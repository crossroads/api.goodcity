# Goodcity server prototype

The GoodCity server is a rails-api based JSON API server for the GoodCity.hk project.

It provides a set of database models, validations, relationships, tests and JSON API endpoints for interaction with frontend Ember web-apps and mobile apps.

## Installation

To get started, download this code and run the following commands:

    bundle install
    rake db:create db:migrate db:seed

Then bootup your rails console and you should have a DB with data.

In production mode, you will also need a local redis server.

    yum install redis
    apt-get install redis

## Tests

Simply run rake

    rake

For individual specs, run rspec

    rspec spec/serializers

## Deployment

Using capistrano, commit all changes to master branch and push to github. Then type:

    cap production deploy

This will deploy changes to api.goodcity.hk (make sure your ssh keys are loaded)

## Documentation

Generate model/controller documentation using the railroady gem. (You must have graphviz packages installed on your machine first.)

    gem install railroady
    rake diagram:all
