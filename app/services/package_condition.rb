class PackageCondition
  def initialize(package)
    @package = package
  end

  def get_condition
    condition = @package.try(:donor_condition).try(:name_en) ||
      @package.try(:item).try(:donor_condition).try(:name_en)
    case condition
    when "New" then "N"
    when "Lightly Used" then "M"
    when "Heavily Used" then "U"
    when "Broken" then "B"
    end
  end
end
