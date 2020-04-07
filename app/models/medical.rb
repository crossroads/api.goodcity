# frozen_string_literal: true

# Medical model
class Medical < ActiveRecord::Base
  has_paper_trail class_name: 'Version'

  belongs_to :country
end
