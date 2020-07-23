namespace :goodcity do
  desc 'Use rake: goodcity:resync_duplicate_users do sync any duplicate users created in browse app' do
    task resync_duplicate_users: :environment do
      ResyncDuplicateUsers.apply
    end
  end
end
