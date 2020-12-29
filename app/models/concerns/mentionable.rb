# frozen_string_literal: true
module Mentionable
  extend ActiveSupport::Concern
  module Messageables
    ALLOWED_MESSAGEABLES                          = %w[Offer Order Item Package].freeze
    MENTIONABLE_ROLES                             = ['Reviewer', 'Supervisor', 'Order administrator', 'Order fulfilment',
                                                     'Stock administrator', 'Stock fulfilment'].freeze
    CREATOR_MENTIONABLE_ROLES                     = ['Order administrator', 'Order fulfilment'].freeze
  end

  def set_mentioned_users
    user_ids = extract_user_ids_from_message_body
    return if user_ids.nil?

    format_message_body
    add_mentions_lookup(user_ids)
  end

  def add_mentions_lookup(user_ids)
    lookup = {}
    lookup_ids = parse_id_from_decorated_ids(parse_id_from_mention_text)
    lookup_ids.map.with_index do |lookup_id, idx|
      user = User.find_by_id(user_ids[idx])
      # TODO: Create a more complex decorator (ex: [@#id#@] or convert mentioned username into a encoded hash value)
      # Logic to handle if input has any decorator type text. Ex: [:12]
      if user
        lookup[lookup_id] = { type: 'User', id: user.id, display_name: user.full_name }
      else
        self.body = body.gsub("[:#{lookup_id}]", "[:#{user_ids[idx]}]")
      end
    end
    update(lookup: lookup)
  end

  def extract_user_ids_from_message_body
    ids = parse_id_from_mention_text
    ids = parse_id_from_decorated_ids(ids)
    ids
  end

  def format_message_body
    ref_count = 0
    self.body = body.gsub(/\[:\d+\]/) do
      ref_count += 1
      "[:#{ref_count}]"
    end
  end

  def parse_id_from_mention_text
    body.scan(/\[:\d+\]/)
  end

  def parse_id_from_decorated_ids(ids)
    ids.map { |id| id.match(/\d+/).to_s }
  end

  included do
    def self.mentionable_users(roles:, messageable_id:, messageable_type:, is_private: false)
      messageable = construct_messageable(messageable_type, messageable_id) unless [messageable_id, messageable_type].all?(&:nil?)
      users = User.active.exclude_user(User.current_user.id)
                  .with_roles(mentionable_roles(roles))
                  .joins(:active_roles)
                  .distinct.to_a
      creator = add_creator(messageable) unless bool_cast(is_private)
      users << creator unless users.include? creator
      users.compact
    end

    def self.add_creator(messageable)
      valid_roles = User.current_user.roles.pluck(:name) & Messageables::CREATOR_MENTIONABLE_ROLES
      return unless valid_roles.present?

      messageable&.created_by
    end

    def self.construct_messageable(type, id)
      raise Goodcity::BadOrMissingRecord.new(:messageable) unless Messageables::ALLOWED_MESSAGEABLES.include?(type)

      record = type&.classify&.constantize&.find_by(id: id)
      raise Goodcity::BadOrMissingRecord.new(:messageable) if record.nil?

      record
    end

    def self.mentionable_roles(roles)
      Messageables::MENTIONABLE_ROLES & roles.split(',').map(&:strip).uniq
    end

    def self.bool_cast(val)
      ActiveModel::Type::Boolean.new.cast(val)
    end
  end
end
