module Api::V1

  class DonorConditionSerializer < ApplicationSerializer
    attributes :id, :name

    def name__sql
      if @options[:include_stock_condition]
        "(CASE WHEN donor_conditions.id=1 THEN 'New'
              WHEN donor_conditions.id=2 THEN 'Mixed'
              WHEN donor_conditions.id=3 THEN 'Used'
              WHEN donor_conditions.id=4 THEN 'Broken'
        END)"
      else
        "name_#{current_language}"
      end
    end

    def name
      if @options[:include_stock_condition]
        case object.id
          when 1 then 'New'
          when 2 then 'Mixed'
          when 3 then 'Used'
          when 4 then 'Broken'
        end
      else
        object.name
      end
    end

  end

end
