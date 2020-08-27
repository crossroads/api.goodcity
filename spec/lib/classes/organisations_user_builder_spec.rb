require "rails_helper"

describe OrganisationsUserBuilder do

  # :organisations_user: {
  #   :organisation_id,
  #   :user_id,
  #   :position,
  #   :status,
  #   :preferred_contact_number,
  #   user_attributes: {
  #     :first_name,
  #     :last_name,
  #     :mobile,
  #     :email
  #   }

  let(:user) { create :user, mobile: '+85291112222', email: 'verified@email.com', is_email_verified: true, is_mobile_verified: true }
  let(:other_user) { create :user }
  let(:super_user) { create :user, :with_can_manage_organisations_users_permission }
  let(:organisation) { create :organisation }
  let(:other_organisation) { create :organisation }
  let(:change_author) { super_user }

  # ---- Helpers

  def build_params(params = {})
    {
      organisation_id:          params[:organisation_id] || organisation.id,
      user_id:                  params[:user_id] || user.id,
      position:                 params[:position] || "Artist",
      preferred_contact_number: params[:preferred_contact_number] || "99999999",
      status:                   params[:status] || 'pending',
      user_attributes: {
        first_name: params.dig(:user_attributes, :first_name) || "Steve",
        last_name:  params.dig(:user_attributes, :last_name)  || "Evets",
        mobile:     params.dig(:user_attributes, :mobile)     || "+85298888888",
        email:      params.dig(:user_attributes, :email)      || "steve@steve.org"
      },

      change_author: params[:change_author] || change_author
    }
  end

  # ---- Specs

  describe "Creating a new organisations_user" do

    it "creates an organisations_user record linking the user to the organisation" do
      expect {
        OrganisationsUserBuilder.create(build_params)
      }.to change(OrganisationsUser, :count).by(1)
    end

    it "sets the organisations_user params properly" do
      payload = build_params

      OrganisationsUserBuilder.create(payload)

      [:organisation_id, :user_id, :status, :preferred_contact_number, :position].each do |key|
        expect(OrganisationsUser.last.try(key)).to eq(payload[key])
      end
    end

    it "applies the user_attributes to the user record" do
      payload = build_params

      user = OrganisationsUserBuilder.create(payload).user
      
      [:first_name, :last_name, :mobile, :email].each do |key|
        expect(OrganisationsUser.last.user.try(key)).to eq(payload.dig(:user_attributes, key))
      end
    end

    it "initializes the status to 'PENDING' if not provided" do
      OrganisationsUserBuilder.create(build_params.except(:status))
      expect(OrganisationsUser.last.status).to eq('pending')
    end

    it "sends an sms to the user after creation organisations_user creation" do
      user = User.find(build_params[:user_id])

      expect(TwilioService).to receive(:new).with(user).and_call_original
      expect_any_instance_of(TwilioService).to receive(:send_welcome_msg)
      OrganisationsUserBuilder.create(build_params)
    end

    describe "Error management" do

      it "fails if the user doesn't exist" do
        expect {
          OrganisationsUserBuilder.create(build_params(user_id: 12345678))
        }.to raise_error(Goodcity::BadOrMissingRecord)
      end

      it "fails if the organisation doesn't exist" do
        expect {
          OrganisationsUserBuilder.create(build_params(organisation_id: 12345678))
        }.to raise_error(Goodcity::BadOrMissingRecord)
      end

      it "fails if the user already is in the organisation" do
        payload = build_params(user_id: user.id, organisation_id: organisation.id)

        create :organisations_user, user: user, organisation: organisation
        
        expect {
          OrganisationsUserBuilder.create(payload)
        }.to raise_error(Goodcity::DuplicateRecordError).with_message(/User already exists in this organisation/)
      end

      it "fails to set the user's mobile if already in use by another user" do
        mobile  = '+85299997777'
        payload = build_params(user_attributes: { mobile: mobile })
        
        create(:user, mobile: mobile)

        expect {
          OrganisationsUserBuilder.create(payload)
        }.to raise_error(Goodcity::AccessDeniedError).with_message(/The email or mobile already exists/)
      end

      it "fails to set the user's email if already in use by another user" do
        email   = 'foo@bar.xyz'
        payload = build_params(user_attributes: { email: email })
        
        create(:user, email: email)

        expect {
          OrganisationsUserBuilder.create(payload)
        }.to raise_error(Goodcity::AccessDeniedError).with_message(/The email or mobile already exists/)
      end

      [:user_id, :organisation_id].each do |param|
        it "fails if the '#{param}' param is missing" do
          payload = build_params.except(param)

          expect {
            OrganisationsUserBuilder.create(payload)
          }.to raise_error(Goodcity::BadOrMissingRecord)
        end
      end

      context "as a normal user" do

        let(:change_author) { user }
        
        it "fails to modify another user's records" do
          payload = build_params(user_id: other_user.id)

          expect {
            OrganisationsUserBuilder.create(payload)
          }.to raise_error(Goodcity::AccessDeniedError)
        end

        it "fails to set a status to anything other than PENDING" do
          payload = build_params(status: 'approved')

          expect {
            OrganisationsUserBuilder.create(payload)
          }.to raise_error(Goodcity::AccessDeniedError)
        end

        context "trying to modify his/her user attributes (mobile, ...)" do
          before do
            expect(change_author.is_email_verified).to eq(true)
            expect(change_author.is_mobile_verified).to eq(true)
          end

          it "fails to modify a verified mobile" do
            payload = build_params(user_attributes: { mobile: '+85294444444' })
            expect {
              OrganisationsUserBuilder.create(payload)
            }.to raise_error(Goodcity::ReadOnlyFieldError)
          end

          it "fails to modify a verified email" do
            payload = build_params(user_attributes: { email: 'another@email.com' })
            expect {
              OrganisationsUserBuilder.create(payload)
            }.to raise_error(Goodcity::ReadOnlyFieldError)
          end
        end
      end
    end
  end


  describe "Updating an existing organisations_user" do
    let(:organisations_user) { create(:organisations_user, user: user, organisation: organisation) }
    let(:other_organisations_user) { create(:organisations_user, user: other_user, organisation: other_organisation) }

    it "updates the organisations_user params properly" do
      OrganisationsUserBuilder.update(organisations_user.id, build_params(
        status: 'approved',
        position: 'rockstar',
        preferred_contact_number: '87654567'
      ))

      organisations_user.reload
      expect(organisations_user.status).to eq('approved')
      expect(organisations_user.position).to eq('rockstar')
      expect(organisations_user.preferred_contact_number).to eq('87654567')
    end

    it "applies the user_attributes to the user record" do
      payload = build_params

      OrganisationsUserBuilder.update organisations_user.id, build_params(
        user_attributes: {
          first_name: "Freddy",
          last_name: "Mercury",
          mobile: "+85292223376",
          email: "singer@queen.com"
        }
      )

      user = organisations_user.reload.user
      expect(user.first_name).to eq("Freddy")
      expect(user.last_name).to eq("Mercury")
      expect(user.mobile).to eq("+85292223376")
      expect(user.email).to eq("singer@queen.com")
    end

    describe "Error management" do

      it "forbids changing the user_id" do
        expect {
          OrganisationsUserBuilder.update(organisations_user.id, build_params(user_id: other_user.id))
      }.to raise_error(Goodcity::ReadOnlyFieldError).with_message("The 'user_id' field cannot be modified")
      end

      it "forbids changing the organisation_id" do
        expect {
          OrganisationsUserBuilder.update(organisations_user.id, build_params(organisation_id: other_organisation.id))
        }.to raise_error(Goodcity::ReadOnlyFieldError).with_message("The 'organisation_id' field cannot be modified")
      end

      it "fails to update the user's mobile if already in use by another user" do
        mobile  = '+85299997777'
        payload = build_params(user_attributes: { mobile: mobile })
        
        create(:user, mobile: mobile)

        expect {
          OrganisationsUserBuilder.update(organisations_user.id, payload)
        }.to raise_error(Goodcity::AccessDeniedError).with_message(/The email or mobile already exists/)
      end

      it "fails to update the user's email if already in use by another user" do
        email   = 'foo@bar.xyz'
        payload = build_params(user_attributes: { email: email })
        
        create(:user, email: email)

        expect {
          OrganisationsUserBuilder.update(organisations_user.id, payload)
        }.to raise_error(Goodcity::AccessDeniedError).with_message(/The email or mobile already exists/)
      end

      context "as a normal user" do

        let(:change_author) { user }
        
        it "fails to modify another user's records" do
          payload = build_params(user_id: other_user.id, organisation_id: other_organisation.id, position: 'Rock climber')

          expect {
            OrganisationsUserBuilder.update(other_organisations_user.id, payload)
          }.to raise_error(Goodcity::AccessDeniedError).with_message('Access Denied')
        end

        it "fails to set a status to anything other than PENDING" do
          payload = build_params(status: 'approved').except(:user_attributes)

          expect {
            OrganisationsUserBuilder.update(organisations_user.id, payload)
          }.to raise_error(Goodcity::AccessDeniedError).with_message('Access Denied')
        end

        context "trying to modify his/her user attributes (mobile, ...)" do
          before do
            expect(change_author.is_email_verified).to eq(true)
            expect(change_author.is_mobile_verified).to eq(true)
          end

          it "fails to modify a verified mobile" do
            payload = build_params(user_attributes: { mobile: '+85294444444' })
            expect {
              OrganisationsUserBuilder.update(organisations_user.id, payload)
            }.to raise_error(Goodcity::ReadOnlyFieldError)
          end

          it "fails to modify a verified email" do
            payload = build_params(user_attributes: { email: 'another@email.com' })
            expect {
              OrganisationsUserBuilder.update(organisations_user.id, payload)
            }.to raise_error(Goodcity::ReadOnlyFieldError)
          end
        end
      end
    end
  end
end
