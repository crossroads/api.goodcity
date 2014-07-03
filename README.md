# Goodcity server prototype

This is the server prototype that will form the foundations of the Goodcity server API.

In it's current form it will provide a basic set of database models, validations, relationships, tests and API for interaction with Ember and mobile apps.

## Installation

To get started, download this code and run the following commands:

    bundle install
    rake db:create db:migrate db:seed

Then bootup your rails console and you should have a DB with data.

(There is no API access just yet)

## Tests

Simply run rake

    rake

For individual specs, run rspec

    rspec spec/serializers

## Deployment

Using capistrano, commit all changes to master branch and push to github. Then type:

    cap production deploy

This will deploy changes to api.goodcity.hk

## Documentation

Generate model/controller documentation using the railroady gem. (You must have graphviz packages installed on your machine first.)

    mkdir doc/
    rake diagram:all

Then move the doc folder into public/ so we can serve it over http.

    mv -f doc public/
