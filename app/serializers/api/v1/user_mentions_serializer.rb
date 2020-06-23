# frozen_string_literal: true

module Api::V1
  class UserMentionsSerializer < ApplicationSerializer
    embed :ids, include: true

    attributes :id, :first_name, :last_name
  end
end
