namespace :goodcity do
  # Base usage:
  #   > rake goodcity:initialize_packages_inventory
  #
  # Rehearsal
  #   > rake goodcity:initialize_packages_inventory[rehearsal]
  #
  # With force flag:
  #   > rake goodcity:initialize_packages_inventory[force]
  #
  desc 'Update package with grade and donor_condition_id'
  task :initialize_packages_inventory, [:param] => [:environment] do |_, args|
    PackagesInventoriesImporter.import({
      force: args[:force].eql?('force'),
      rehearsal: args[:param].eql?('rehearse')
    })
  end
end
