namespace :goodcity do

  # rake goodcity:add_stockit_user
  desc 'Add Stockit User'
  task add_stockit_user: :environment do
    mobile = Rails.application.secrets.twilio["voice_number"]

    if mobile
      stockit_user = User.where(first_name: "Stockit", last_name: "User", mobile: mobile).first_or_create
      stockit_user.permission = Permission.api_write
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
