namespace :goodcity do

  # rake goodcity:add_stockit_user
  desc 'Add Stockit User'
  task add_stockit_user: :environment do
    mobile = Rails.application.secrets.twilio["voice_number"]

    if mobile
      stockit_user = User.where(first_name: "Stockit", last_name: "User", mobile: mobile.to_s.prepend("+")).first_or_create

      stockit_user.permission = Permission.api_write
      stockit_user.save

      if stockit_user.valid?
        stockit_user.auth_tokens.delete_all
        api_token = Token.new.generate_api_token(user_id: stockit_user.id)
        puts "STOCKIT API TOKEN = #{api_token}"
      end
    end
  end
end
