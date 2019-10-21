namespace :goodcity do

  # Base usage:
  #   > rake goodcity:initialize_packages_inventory
  #
  # With force flag:
  #   > rake goodcity:initialize_packages_inventory[force]
  #
  desc 'Update package with grade and donor_condition_id'
  task :initialize_packages_inventory, [:force] do |t, args|
    force = args[:force].eql?('force')
    # PackagesInventoriesImporter.import(force: force)
  end
end
