require 'rails_helper'

describe Watcher do

  class Sample
    include Watcher

    @@calls = 0

    class << self
      def calls; @@calls; end
      def inc;  @@calls += 1; end
    end

    watch([Package]) do
      Sample.inc
    end
  end

  it "triggers when the watched Model receives changes" do
    expect {
      create(:package)
    }.to change {
      Sample.calls
    }.by(1)
  end
end
