namespace :goodcity do
  desc 'change allow_web_publish to false if package.available_quantity = 0'
  task change_allow_web_publish_to_false: :environment do
    sql = "UPDATE packages SET allow_web_publish=false WHERE available_quantity=0 AND allow_web_publish!=false"
    Package.connection.execute(sql)
  end
end
