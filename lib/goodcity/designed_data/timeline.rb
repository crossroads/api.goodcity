module Goodcity
  class DesignedData
    #
    # Every action in the dataset — receiving a donation, a move, a designation, an order
    # transition, a chat message — is an event with a time. They are collected first and
    # then performed in time order, so causality holds across stock and orders alike:
    # a line is designated after its item was inventorised, dispatched after the order
    # finished processing, and order codes rise with order dates as they do for real.
    #
    class Timeline
      Event = Struct.new(:at, :seq, :label, :user, :action)

      def initialize(ctx)
        @ctx = ctx
        @events = []
      end

      def add(at, label, user: nil, &action)
        @events << Event.new(@ctx.time(at, salt: label), @events.size, label, user, action)
      end

      def size
        @events.size
      end

      def run!
        @events.sort_by! { |e| [e.at, e.seq] }
        @events.each_with_index do |e, n|
          begin
            user = e.user.respond_to?(:call) ? e.user.call : e.user
            @ctx.at(e.at, user: user) { e.action.call }
          rescue StandardError => err
            raise "while performing #{e.label} at #{e.at}: #{err.class}: #{err.message}"
          end
          yield(n + 1) if block_given?
        end
      end
    end
  end
end
