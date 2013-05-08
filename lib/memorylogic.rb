require 'java' if RUBY_PLATFORM =~ /java/i

module Memorylogic
  def self.included(klass)
    klass.class_eval do
      after_filter :log_memory_usage
    end
  end

  class << self
    include ActionView::Helpers::NumberHelper
  end

  def self.memory_usage
    size = if RUBY_PLATFORM =~ /java/i
      runtime = java.lang.Runtime.getRuntime()

      runtime.totalMemory() - runtime.freeMemory()
    else
      `ps -o rss= -p #{Process.pid}`.to_i * 1024
    end

    number_to_human_size(size)
  end

  private
    def log_memory_usage
      if logger
        logger.info("Memory usage: #{Memorylogic.memory_usage} | PID: #{Process.pid}")
      end
    end
end

ActiveSupport::BufferedLogger.class_eval do
  def add_with_memory_info(severity, message = nil, progname = nil, &block)
    r = add_without_memory_info(severity, message, progname, &block)
    add_without_memory_info(severity, "  \e[1;31mMemory usage:\e[0m #{Memorylogic.memory_usage}\n\n", progname, &block)
    r
  end

  alias_method_chain :add, :memory_info
end
