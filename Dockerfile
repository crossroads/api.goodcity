FROM ruby:2.7.3-alpine

ARG GITHUB_TOKEN

RUN apk update \
  && apk upgrade \
  && apk add --update --no-cache build-base postgresql-dev nodejs git tzdata openssh \
  && rm -rf /var/cache/apk/* \
  && echo "root:Docker!" | chpasswd
COPY sshd_config /etc/ssh/
RUN mkdir -p /tmp
COPY ssh_setup.sh /tmp
RUN chmod +x /tmp/ssh_setup.sh \
    && (sleep 1;/tmp/ssh_setup.sh 2>&1 > /dev/null)

RUN adduser -D -u 1000 deployer
WORKDIR /app/
RUN chown deployer:deployer /app
USER deployer

# Use GITHUB_TOKEN because go_go_van_api.git is a private repo
COPY --chown=deployer Gemfile* /app/
RUN git config --global url."https://${GITHUB_TOKEN}:x-oauth-basic@github.com/crossroads/go_go_van_api.git".insteadOf "git@github.com:crossroads/go_go_van_api.git" \
  && BUNDLE_VERSION=$(grep "BUNDLED WITH" -A 1 Gemfile.lock | grep -v "BUNDLED WITH" | sed 's/^ *//g') \
  && gem install bundler:${BUNDLE_VERSION} --no-document \
  && bundle config set --local deployment 'true' \
  && bundle config set --local jobs '4' \
  && bundle config set --local without 'development test' \
  && bundle install \
  && rm ~/.gitconfig
COPY --chown=deployer . /app/
RUN cp /app/config/database.yml.docker /app/config/database.yml

EXPOSE 3000 2222

# CMD ["bundle", "exec", "sidekiq", "-C", "config/sidekiq.yml"]
CMD ["bundle", "exec", "rails", "server", "-p", "3000", "-b", "0.0.0.0"]
