namespace :goodcity do
  # rake goodcity:add_stockit_user
  desc 'Add Stockit User'
  task add_stockit_user: :environment do
    mobile = Rails.application.secrets.twilio["voice_number"]

    if mobile
      stockit_user = User.where(first_name: "Stockit", last_name: "User", mobile: mobile).first_or_create
      role =  Role.where(name: 'api-write').first_or_create
      stockit_user.user_roles.where(role: role).first_or_create
      if stockit_user.save
        stockit_user.auth_tokens.delete_all
        api_token = Token.new.generate_api_token(user_id: stockit_user.id)
        puts "STOCKIT API TOKEN = #{api_token}"
      else
        puts stockit_user.errors.full_messages
      end
    else
      puts "Add Stockit User failed: Missing twilio voice number"
    end
  end
end
