require 'goodcity/package_setup'

namespace :goodcity do

  desc 'Initializes the package sets'
  task init_package_sets: :environment do
    results = ActiveRecord::Base.connection.execute <<-SQL
      WITH item_packages_count AS (
        SELECT packages.*, COUNT(id) OVER (PARTITION BY item_id) AS number_of_packages
        FROM packages
        WHERE (item_id IS NOT NULL AND package_set_id IS NULL)
      )
      SELECT id, item_id from item_packages_count WHERE (
        package_set_id IS NULL AND number_of_packages > 1
      ) ORDER BY item_id, id;
    SQL

    item_ids = results.map { |r| r['item_id'] }.compact.uniq.map(&:to_i)

    bar = RakeProgressbar.new(item_ids.length) 

    item_ids.each do |id|
      item      = Item.find_by(id: id)

      return unless item.present?

      packages  = item.packages

      next unless item.package_type.present? || packages.length < 2

      package_set = PackageSet.create(description: item.package_type.name_en, package_type_id: item.package_type.id)

      packages.each do |package|
        next if package.package_set_id.present?
        package.update!(package_set_id: package_set.id)
      end

      bar.inc
    end

    bar.finished
  end
end
