FROM ruby:2.2
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs
RUN mkdir /api.goodcity
WORKDIR /api.goodcity

# go_go_van_api.git is a private repo
# The ADD command below may need updating based on your github key
RUN mkdir -p /root/.ssh
ADD ./id_rsa /root/.ssh/id_rsa
RUN chmod 600 /root/.ssh/id_rsa
RUN ssh-keyscan github.com >> /root/.ssh/known_hosts

ADD Gemfile /api.goodcity/Gemfile
ADD Gemfile.lock /api.goodcity/Gemfile.lock
RUN bundle install
ADD . /api.goodcity
