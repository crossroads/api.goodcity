module Goodcity
  class RakeLogger
    def initialize(task)
      @task = task
      @logger = Logger.new("#{Rails.root}/log/rake_log.log")
    end

    def log_info(msg)
      @logger.info("task=#{@task} #{msg}")
    end

    def close
      @logger.close
    end
  end
end
