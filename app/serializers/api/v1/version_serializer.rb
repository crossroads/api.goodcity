module Api::V1
  class VersionSerializer < ApplicationSerializer
    include SerializeTimeValue

    embed :ids, include: true
    attributes :id, :event, :item_id, :item_type, :whodunnit, :whodunnit_name,
      :state, :created_at

    def state
      object.object_changes && object.object_changes["state"].try(:last)
    end

    def state__sql
      "object_changes -> 'state' -> 1"
    end

    def whodunnit_name
      User.find_by(id: whodunnit).try(:full_name)
    end

    def whodunnit_name__sql
      " (select concat(first_name, ' ', last_name)
        from users u where u.id = CAST(versions.whodunnit AS INT) )"
    end
  end
end
