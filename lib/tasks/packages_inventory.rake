namespace :goodcity do
  # Base usage:
  #   > rake goodcity:initialize_packages_inventory
  #
  # With force flag:
  #   > rake goodcity:initialize_packages_inventory[force]
  #
  desc 'Update package with grade and donor_condition_id'
  task :initialize_packages_inventory, [:force] do |_, args|
    PackagesInventoriesImporter.import({
      force: args[:force].eql?('force')
    })
  end
end
