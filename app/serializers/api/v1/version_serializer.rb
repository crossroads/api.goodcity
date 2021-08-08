module Api::V1
  class VersionSerializer < ApplicationSerializer
    embed :ids, include: true
    attributes :id, :event, :item_id, :item_type, :whodunnit, :whodunnit_name,
               :state, :created_at, :object_changes

    def state
      object.object_changes && object.object_changes["state"].try(:last)
    end

    def whodunnit_name
      User.find_by(id: whodunnit).try(:full_name)
    end
  end
end
