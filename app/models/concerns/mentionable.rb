module Mentionable
  extend ActiveSupport::Concern

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
end
