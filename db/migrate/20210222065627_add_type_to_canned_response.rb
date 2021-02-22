class AddTypeToCannedResponse < ActiveRecord::Migration[5.2]
  def change
    add_column    :canned_responses, :message_type ,    :string, default: "canned"
  end
end
