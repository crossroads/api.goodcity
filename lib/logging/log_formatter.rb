# Thanks https://medium.com/@yuliaoletskaya/standardize-rails-log-output-d6ad0827a172

class LogFormatter

  def call(severity, time, progname, msg = '')
    return '' if msg.blank?
 
    if progname.present?
      return "time='#{time.iso8601(3)}' level=#{severity} progname='#{progname}' #{processed_message(msg)}\n"
    end
 
    "time='#{time.iso8601(3)}' level=#{severity} #{processed_message(msg)}\n"
  end
 
  private

  def processed_message(msg)
    if msg.is_a?(Hash) 
      msg.map { |k, v| "#{k}='#{v}'" }.join(' ')
    else
      "#{msg}"
    end
  end
end