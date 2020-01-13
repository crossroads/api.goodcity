require 'rails_helper'

describe EventEmitter do
  let(:emitter) { Class.new { include EventEmitter } }

  before(:each) { emitter.clear_hooks }

  it 'registers an event listener' do
    received_args = nil
    emitter.on(:toto) { |*params| received_args = params }

    emitter.fire(:toto, 1, 2, 3)

    expect(received_args).to eq([1,2,3])
  end

  it 'registers multiple event listener' do
    received_args = []
    emitter.on(:toto) { |*params| received_args << params }
    emitter.on(:toto) { |*params| received_args << params }

    emitter.fire(:toto, 1, 2, 3)

    expect(received_args).to eq([[1,2,3],[1,2,3]])
  end
end
