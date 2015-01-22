#api: bundle exec puma -C config/puma.rb
api: bundle exec rails server --binding=127.0.0.1
sidekiq: bundle exec sidekiq
socketio: (cd ../socket.io-webservice/ && PORT=1337 NODE_ENV=development node app.js)
