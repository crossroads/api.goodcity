Sidekiq.default_worker_options = { 'backtrace' => true }
Sidekiq.logger.formatter = proc do |severity, time, program_name, message|
  c = Thread.current[:sidekiq_context]
  context =  (c && c.any? ? " #{c.join(' ')}" : '').strip
  "time=\"#{time.iso8601(3)}\" pid=\"#{::Process.pid}\" tid=\"#{Thread.current.object_id.to_s(36)}\" context=\"#{context}\" level=\"#{severity}\" msg=\"#{message.to_s.gsub('"', "'")}\"\n"
end
