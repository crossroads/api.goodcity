require 'socket'

class PrintLabel
  attr_accessor :printer, :label

  def initialize(printer, label)
    @printer = printer
    @label = label
  end

  def print
    Socket.tcp(@printer.host, @printer.port) do |sock|
      sock.print @label.to_s 
      sock.close_write
    end
  end

end
