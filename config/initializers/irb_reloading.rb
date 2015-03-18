if defined?(IRB::Context) && !defined?(Rails::Server) && Rails.env.development?
  class IRB::Context
    def evaluate_with_reloading(line, line_no)
      ActionDispatch::Reloader.cleanup!
      ActionDispatch::Reloader.prepare!

      evaluate_without_reloading(line, line_no)
    end
    alias_method_chain :evaluate, :reloading
  end

  puts "=> IRB code reloading enabled"
end
