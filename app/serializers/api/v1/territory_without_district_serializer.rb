module Api::V1
 class TerritoryWithoutDistrictSerializer < ApplicationSerializer
   embed :ids, include: true
   attributes :id, :name

   def name__sql
     "name_#{current_language}"
   end
 end
end
