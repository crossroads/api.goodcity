#rake goodcity:change_allow_web_publish_to_false

namespace :goodcity do
  desc 'change allow_web_publish to false if package.quantity = 0'
  task change_allow_web_publish_to_false: :environment do
    packages = Package.where("quantity = ? and allow_web_publish = ?", 0, true)
    packages.find_each do |package|
      package.update(allow_web_publish: false)
    end
  end
end
