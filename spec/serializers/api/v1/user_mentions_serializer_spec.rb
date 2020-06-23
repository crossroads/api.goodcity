# frozen_string_literal: true

require "rails_helper"

context Api::V1::UserMentionsSerializer do
  let(:user) { create :user }
  let(:serializer) { Api::V1::UserMentionsSerializer.new(user).as_json }
  let(:json) { JSON.parse(serializer.to_json) }

  it 'creates JSON' do
    expect(json['user_mentions']['first_name']).to eq(user.first_name)
    expect(json['user_mentions']['last_name']).to eq(user.last_name)
    expect(json['user_mentions']['id']).to eq(user.id)
  end
end
