#api: bundle exec puma -C config/puma.rb
api: bundle exec rails server --binding=0.0.0.0
sidekiq: bundle exec sidekiq
socketio: (cd ../socket.io-webservice/ && PORT=1337 npm start)
