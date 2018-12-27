# Filtering and priority logic for items is extracted here to avoid cluttering the model class
module PackageFiltering
  extend ActiveSupport::Concern

  module ClassMethods
    def filter(states: [], location: nil)
      res = where("state IN (?)", states) unless states.empty?
      res = res.filter_by_location(location) if location
      res
    end

    def filter_by_location(location)
      building_name, area_name = location.split('-')
      if area_name === "(All areas)"
        where("locations.building = (?)", building_name)
      else
        where("locations.building = (?) AND locations.area = (?)", building_name, area_name)
      end
    end
  end
end
