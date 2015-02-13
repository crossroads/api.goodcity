namespace :log do
  namespace :tail do
    desc "Tail log files"
    task :rails do
      trap('INT') { puts; exit 0; }
      last_host = nil
      on roles(:app) do
        execute "tail -f #{shared_path}/log/#{fetch(:rails_env)}.log" do |channel, stream, data|
          puts "\n\033[34m==> #{channel[:host]}\033[0m#{data}"
          break if stream == :err
        end
      end
    end
  end
end
