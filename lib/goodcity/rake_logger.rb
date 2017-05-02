module Goodcity
  class RakeLogger < Logger
    def initialize(task)
      super("#{Rails.root}/log/rake_log.log")
      @task = task
    end

    def info(msg)
      super("task=#{@task} #{msg}")
    end

    def error(msg)
      super("task=#{@task} #{msg}")
    end

    def debug(msg)
      super("task=#{@task} #{msg}")
    end

    def warn(msg)
      super("task=#{@task} #{msg}")
    end

    def close
      super
    end
  end
end
