require "rails_helper"

RSpec.describe Api::V1::OrganisationsUsersController, type: :controller do
  let(:superuser) { create(:user, :with_can_manage_organisations_users_permission) }
  let(:organisation) { create :organisation }
  let(:other_organisation) { create :organisation }
  let(:user) { create :user}
  let(:other_user) { create :user}
  let(:parsed_body) { JSON.parse(response.body) }

  let(:organisations_user_payload) {
    {
      organisation_id:          organisation.id,
      user_id:                  user.id,
      position:                 "Conductor",
      preferred_contact_number: "99999999",
      status:                   'pending'
    }
  }

  let(:user_attributes) {
    {
      first_name: user.first_name,
      last_name:  user.last_name,
      mobile:     user.mobile,
      email:      user.email,
      title:      user.title
    }
  }


  # --------------------
  # Super User
  # --------------------

  context "as a super user with 'can_manage_organisations_users' permission" do
    before { generate_and_set_token(superuser) }

    describe "POST organisations_user" do
      it "creates new organisations user", :show_in_doc do
        expect {
          post :create, format: :json, params: { organisations_user: organisations_user_payload.merge(status: 'approved') }
        }.to change(OrganisationsUser, :count).by(1)

        expect(OrganisationsUser.last.status).to eq('approved')
        expect(response.status).to eq(201)
      end

      it "defaults to the 'pending' status", :show_in_doc do
        expect {
          post :create, format: :json, params: { organisations_user: organisations_user_payload.except(:status) }
        }.to change(OrganisationsUser, :count).by(1)

        expect(OrganisationsUser.last.status).to eq('pending')
        expect(response.status).to eq(201)
      end

      it 'converts status to lower case before saving' do
        organisations_user_payload[:status] = 'Approved'
        post :create, organisations_user: organisations_user_payload
        expect(parsed_body['organisations_user']['status']).to eq('approved')
      end

      describe 'Modifying the user props with nested attributes (:user_attributes)' do

        it "allows modifying the user's attributes during the creation or the organisations_user", :show_in_doc do
          payload = {
            **organisations_user_payload,
            user_attributes: user_attributes.merge(first_name: 'Shteve')
          }

          expect {
            post :create, format: :json, params: { organisations_user: payload }
          }.to change(OrganisationsUser, :count).by(1)

          expect(user.reload.first_name).to eq('Shteve')
          expect(response.status).to eq(201)
        end

        context 'when setting the mobile number' do
          before do
            user.mobile = ''
            user.is_mobile_verified = false
            user.save!(validate: false)
          end

          it "sends error if new organisations_user is with invalid mobile number", :show_in_doc do
            payload = {
              **organisations_user_payload,
              user_attributes: user_attributes.merge(mobile: '1234')
            }

            expect {
              post :create, format: :json, params: { organisations_user: payload }
            }.not_to change(OrganisationsUser, :count)

            expect(response.status).to eq(422)
            expect(parsed_body["error"]).to match('Mobile is invalid')
          end

          it "sends error if the mobile belongs to someone else", :show_in_doc do
            create :user, mobile: '+85299775522'

            payload = {
              **organisations_user_payload,
              user_attributes: user_attributes.merge(mobile: '+85299775522')
            }

            expect {
              post :create, format: :json, params: { organisations_user: payload }
            }.not_to change(OrganisationsUser, :count)

            expect(response.status).to eq(403)
            expect(parsed_body["error"]).to match('The email or mobile already exists')
          end
        end


        context 'when setting the email number' do
          before do
            user.email = ''
            user.is_email_verified = false
            user.save!(validate: false)
          end

          it "sends error if new organisations_user is with invalid email number", :show_in_doc do
            payload = {
              **organisations_user_payload,
              user_attributes: user_attributes.merge(email: '1234')
            }

            expect {
              post :create, format: :json, params: { organisations_user: payload }
            }.not_to change(OrganisationsUser, :count)

            expect(response.status).to eq(422)
            expect(parsed_body["error"]).to match('Email is invalid')
          end

          it "sends error if the email belongs to someone else", :show_in_doc do
            create :user, email: 'some@other.email'

            payload = {
              **organisations_user_payload,
              user_attributes: user_attributes.merge(email: 'some@other.email')
            }

            expect {
              post :create, format: :json, params: { organisations_user: payload }
            }.not_to change(OrganisationsUser, :count)

            expect(response.status).to eq(403)
            expect(parsed_body["error"]).to match('The email or mobile already exists')
          end
        end
      end

      describe 'Error cases' do
        it "does not create the organisations_user if user already belongs to organisation" do
          create :organisations_user, user: user, organisation: organisation
          expect {
            post :create, format: :json, params: { organisations_user: organisations_user_payload }
          }.not_to change(OrganisationsUser, :count)

          expect(response.status).to eq(409)
          expect(parsed_body['error']).to eq('User already exists in this organisation')
        end

        context 'missing params' do
          [:user_id, :organisation_id].each do |param|
            it "fails if the '#{param}' param is missing'" do
              expect {
                post :create, format: :json, params: { organisations_user: organisations_user_payload.except(param) }
              }.not_to change(OrganisationsUser, :count)

              expect(response.status).to eq(422)
              expect(parsed_body['error']).to eq("Missing parameter #{param}")
            end
          end
        end
      end
    end

    describe "PUT organisations_user/1" do
      let(:organisations_user) { create :organisations_user, user: user, organisation: organisation, status: 'approved' }

      before { touch(organisations_user) }

      it "updates the existing organisations_user", :show_in_doc do
        expect {
          put :update, params: { id: organisations_user.id, organisations_user: organisations_user_payload.merge(status: 'expired') }
        }.to change {
          organisations_user.reload.status
        }.from('approved').to('expired')

        expect(response.status).to eq(200)
      end

      describe 'Modifying the user props with nested attributes (:user_attributes)' do

        it "allows modifying the user's attributes during the creation or the organisations_user", :show_in_doc do
          payload = {
            **organisations_user_payload,
            user_attributes: user_attributes.merge(first_name: 'Shteve')
          }

          expect {
            put :update, params: { id: organisations_user.id, organisations_user: payload }
          }.not_to change(OrganisationsUser, :count)

          expect(user.reload.first_name).to eq('Shteve')
          expect(response.status).to eq(200)
        end

        context 'when setting the mobile number' do
          before do
            user.mobile = ''
            user.is_mobile_verified = false
            user.save!(validate: false)
          end

          it "sends error if new organisations_user is with invalid mobile number", :show_in_doc do
            payload = {
              **organisations_user_payload,
              user_attributes: user_attributes.merge(mobile: '1234')
            }

            expect {
              put :update, params: { id: organisations_user.id, organisations_user: payload }
            }.not_to change(OrganisationsUser, :count)

            expect(response.status).to eq(422)
            expect(parsed_body["error"]).to match('Mobile is invalid')
          end

          it "sends error if the mobile belongs to someone else", :show_in_doc do
            create :user, mobile: '+85299775522'

            payload = {
              **organisations_user_payload,
              user_attributes: user_attributes.merge(mobile: '+85299775522')
            }

            expect {
              put :update, params: { id: organisations_user.id, organisations_user: payload }
            }.not_to change(OrganisationsUser, :count)

            expect(response.status).to eq(403)
            expect(parsed_body["error"]).to match('The email or mobile already exists')
          end
        end

        it 'converts status to lower case before updating' do
          organisations_user_payload[:status] = 'Approved'
          put :update, id: organisations_user.id, organisations_user: organisations_user_payload
          expect(parsed_body['organisations_user']['status']).to eq('approved')
          expect(organisations_user.reload.status).to eq('approved')
        end

        context 'when setting the email number' do
          before do
            user.email = ''
            user.is_email_verified = false
            user.save!(validate: false)
          end

          it "sends error if new organisations_user is with invalid email number", :show_in_doc do
            payload = {
              **organisations_user_payload,
              user_attributes: user_attributes.merge(email: '1234')
            }

            expect {
              put :update, params: { id: organisations_user.id, organisations_user: payload }
            }.not_to change(OrganisationsUser, :count)

            expect(response.status).to eq(422)
            expect(parsed_body["error"]).to match('Email is invalid')
          end

          it "sends error if the email belongs to someone else", :show_in_doc do
            create :user, email: 'some@other.email'

            payload = {
              **organisations_user_payload,
              user_attributes: user_attributes.merge(email: 'some@other.email')
            }

            expect {
              put :update, params: { id: organisations_user.id, organisations_user: payload }
            }.not_to change(OrganisationsUser, :count)

            expect(response.status).to eq(403)
            expect(parsed_body["error"]).to match('The email or mobile already exists')
          end
        end
      end

      describe 'Error cases' do
        context 'readonly params' do
          it "forbids changing the user_id field" do
            expect {
              put :update, params: { id: organisations_user.id, organisations_user: organisations_user_payload.update(user_id: other_user.id) }
            }.not_to change(OrganisationsUser, :count)

            expect(response.status).to eq(403)
            expect(parsed_body['error']).to eq("The 'user_id' field cannot be modified")
          end

          it "forbids changing the organisation_id field" do
            expect {
              put :update, params: { id: organisations_user.id, organisations_user: organisations_user_payload.update(organisation_id: other_organisation.id) }
            }.not_to change(OrganisationsUser, :count)

            expect(response.status).to eq(403)
            expect(parsed_body['error']).to eq("The 'organisation_id' field cannot be modified")
          end
        end

        context 'missing params' do
          [:user_id, :organisation_id].each do |param|
            it "fails if the '#{param}' param is missing'" do
              expect {
                post :create, format: :json, params: { organisations_user: organisations_user_payload.except(param) }
              }.not_to change(OrganisationsUser, :count)

              expect(response.status).to eq(422)
              expect(parsed_body['error']).to eq("Missing parameter #{param}")
            end
          end
        end
      end
    end
  end

  # --------------------
  # Normal User
  # --------------------

  context "as a normal user without any permission" do
    before { generate_and_set_token(user) }

    describe "POST organisations_user" do
      it "creates new organisations user for himself/herself", :show_in_doc do
        expect {
          post :create, format: :json, params: { organisations_user: organisations_user_payload }
        }.to change(OrganisationsUser, :count).by(1)

        organisations_user = OrganisationsUser.last
        expect(organisations_user.status).to eq('pending')
        expect(organisations_user.user_id).to eq(user.id)
        expect(organisations_user.organisation_id).to eq(organisation.id)
        expect(organisations_user.position).to eq('Conductor')
        expect(response.status).to eq(201)
      end

      it "defaults to the 'pending' status", :show_in_doc do
        expect {
          post :create, format: :json, params: { organisations_user: organisations_user_payload.except(:status) }
        }.to change(OrganisationsUser, :count).by(1)

        expect(OrganisationsUser.last.status).to eq('pending')
        expect(response.status).to eq(201)
      end

      describe 'Modifying the user props with nested attributes (:user_attributes)' do

        it "allows modifying the user's attributes during the creation or the organisations_user", :show_in_doc do
          payload = {
            **organisations_user_payload,
            user_attributes: user_attributes.merge(first_name: 'Shteve')
          }

          expect {
            post :create, format: :json, params: { organisations_user: payload }
          }.to change(OrganisationsUser, :count).by(1)

          expect(user.reload.first_name).to eq('Shteve')
          expect(response.status).to eq(201)
        end

        context 'when setting the mobile number' do
          before do
            user.mobile = ''
            user.is_mobile_verified = false
            user.save!(validate: false)
          end

          it "sends error if new organisations_user is with invalid mobile number", :show_in_doc do
            payload = {
              **organisations_user_payload,
              user_attributes: user_attributes.merge(mobile: '1234')
            }

            expect {
              post :create, format: :json, params: { organisations_user: payload }
            }.not_to change(OrganisationsUser, :count)

            expect(response.status).to eq(422)
            expect(parsed_body["error"]).to match('Mobile is invalid')
          end

          it "sends error if the mobile belongs to someone else", :show_in_doc do
            create :user, mobile: '+85299775522'

            payload = {
              **organisations_user_payload,
              user_attributes: user_attributes.merge(mobile: '+85299775522')
            }

            expect {
              post :create, format: :json, params: { organisations_user: payload }
            }.not_to change(OrganisationsUser, :count)

            expect(response.status).to eq(403)
            expect(parsed_body["error"]).to match('The email or mobile already exists')
          end
        end


        context 'when setting the email number' do
          before do
            user.email = ''
            user.is_email_verified = false
            user.save!(validate: false)
          end

          it "sends error if new organisations_user is with invalid email number", :show_in_doc do
            payload = {
              **organisations_user_payload,
              user_attributes: user_attributes.merge(email: '1234')
            }

            expect {
              post :create, format: :json, params: { organisations_user: payload }
            }.not_to change(OrganisationsUser, :count)

            expect(response.status).to eq(422)
            expect(parsed_body["error"]).to match('Email is invalid')
          end

          it "sends error if the email belongs to someone else", :show_in_doc do
            create :user, email: 'some@other.email'

            payload = {
              **organisations_user_payload,
              user_attributes: user_attributes.merge(email: 'some@other.email')
            }

            expect {
              post :create, format: :json, params: { organisations_user: payload }
            }.not_to change(OrganisationsUser, :count)

            expect(response.status).to eq(403)
            expect(parsed_body["error"]).to match('The email or mobile already exists')
          end
        end
      end

      describe 'Error cases' do
        it "does not create the organisations_user if user already belongs to organisation" do
          create :organisations_user, user: user, organisation: organisation
          expect {
            post :create, format: :json, params: { organisations_user: organisations_user_payload }
          }.not_to change(OrganisationsUser, :count)

          expect(response.status).to eq(409)
          expect(parsed_body['error']).to eq('User already exists in this organisation')
        end

        it "does not create the organisations_user for another user" do
          create :organisations_user, user: user, organisation: organisation
          expect {
            post :create, format: :json, params: { organisations_user: organisations_user_payload.merge(user_id: other_user.id) }
          }.not_to change(OrganisationsUser, :count)

          expect(response.status).to eq(403)
          expect(parsed_body['error']).to eq('Access Denied')
        end

        it "prevents the user from modifying his/her verified email through nested attributes" do
          user.update!(is_email_verified: true)

          payload = {
            **organisations_user_payload,
            user_attributes: user_attributes.merge(email: 'some@new.email')
          }

          expect {
            post :create, format: :json, params: { organisations_user: payload }
          }.not_to change(OrganisationsUser, :count)

          expect(response.status).to eq(422)
          expect(parsed_body['error']).to eq("The 'email' field cannot be modified")
        end

        it "prevents the user from modifying his/her verified mobile through nested attributes" do
          user.update!(is_mobile_verified: true)

          payload = {
            **organisations_user_payload,
            user_attributes: user_attributes.merge(mobile: '98541236')
          }

          expect {
            post :create, format: :json, params: { organisations_user: payload }
          }.not_to change(OrganisationsUser, :count)

          expect(response.status).to eq(422)
          expect(parsed_body['error']).to eq("The 'mobile' field cannot be modified")
        end

        [:approved, :expired, :denied].each do |status|
          it "prevents a user from setting his/her status as '#{status}'" do
            expect {
              post :create, format: :json, params: { organisations_user: organisations_user_payload.merge(status: status.to_s) }
            }.not_to change(OrganisationsUser, :count)

            expect(response.status).to eq(403)
            expect(parsed_body['error']).to eq('Access Denied')
          end
        end

        context 'missing params' do
          [:user_id, :organisation_id].each do |param|
            it "fails if the '#{param}' param is missing'" do
              expect {
                post :create, format: :json, params: { organisations_user: organisations_user_payload.except(param) }
              }.not_to change(OrganisationsUser, :count)

              expect(response.status).to eq(422)
              expect(parsed_body['error']).to eq("Missing parameter #{param}")
            end
          end
        end
      end
    end

    describe "PUT organisations_user/1" do
      let(:organisations_user) { create :organisations_user, user: user, organisation: organisation, status: 'approved', position: 'Conductor' }

      before { touch(organisations_user) }

      it "updates the existing organisations_user", :show_in_doc do
        expect {
          put :update, params: { id: organisations_user.id, organisations_user: organisations_user_payload.merge(position: 'El Conductor') }
        }.to change {
          organisations_user.reload.position
        }.from('Conductor').to('El Conductor')

        expect(response.status).to eq(200)
      end

      describe 'Modifying the user props with nested attributes (:user_attributes)' do

        it "allows modifying the user's attributes during the creation or the organisations_user", :show_in_doc do
          payload = {
            **organisations_user_payload,
            user_attributes: user_attributes.merge(first_name: 'Shteve')
          }

          expect {
            put :update, params: { id: organisations_user.id, organisations_user: payload }
          }.not_to change(OrganisationsUser, :count)

          expect(user.reload.first_name).to eq('Shteve')
          expect(response.status).to eq(200)
        end

        context 'when setting the mobile number' do
          before do
            user.mobile = ''
            user.is_mobile_verified = false
            user.save!(validate: false)
          end

          it "sends error if new organisations_user is with invalid mobile number", :show_in_doc do
            payload = {
              **organisations_user_payload,
              user_attributes: user_attributes.merge(mobile: '1234')
            }

            expect {
              put :update, params: { id: organisations_user.id, organisations_user: payload }
            }.not_to change(OrganisationsUser, :count)

            expect(response.status).to eq(422)
            expect(parsed_body["error"]).to match('Mobile is invalid')
          end

          it "sends error if the mobile belongs to someone else", :show_in_doc do
            create :user, mobile: '+85299775522'

            payload = {
              **organisations_user_payload,
              user_attributes: user_attributes.merge(mobile: '+85299775522')
            }

            expect {
              put :update, params: { id: organisations_user.id, organisations_user: payload }
            }.not_to change(OrganisationsUser, :count)

            expect(response.status).to eq(403)
            expect(parsed_body["error"]).to match('The email or mobile already exists')
          end
        end


        context 'when setting the email number' do
          before do
            user.email = ''
            user.is_email_verified = false
            user.save!(validate: false)
          end

          it "sends error if new organisations_user is with invalid email number", :show_in_doc do
            payload = {
              **organisations_user_payload,
              user_attributes: user_attributes.merge(email: '1234')
            }

            expect {
              put :update, params: { id: organisations_user.id, organisations_user: payload }
            }.not_to change(OrganisationsUser, :count)

            expect(response.status).to eq(422)
            expect(parsed_body["error"]).to match('Email is invalid')
          end

          it "sends error if the email belongs to someone else", :show_in_doc do
            create :user, email: 'some@other.email'

            payload = {
              **organisations_user_payload,
              user_attributes: user_attributes.merge(email: 'some@other.email')
            }

            expect {
              put :update, params: { id: organisations_user.id, organisations_user: payload }
            }.not_to change(OrganisationsUser, :count)

            expect(response.status).to eq(403)
            expect(parsed_body["error"]).to match('The email or mobile already exists')
          end
        end
      end

      describe 'Error cases' do

        it "prevents updating someone else's organisations_user record" do
          other_record = create :organisations_user, user: other_user, organisation: organisation

          expect {
            put :update, params: { id: other_record.id, organisations_user: organisations_user_payload.merge(user_id: other_user.id) }
          }.not_to change(OrganisationsUser, :count)

          expect(response.status).to eq(403)
          expect(parsed_body['error']).to eq('Access Denied')
        end

        it "prevents the user from modifying his/her verified email through nested attributes" do
          user.update!(is_email_verified: true)

          payload = {
            **organisations_user_payload,
            user_attributes: user_attributes.merge(email: 'some@new.email')
          }

          expect {
            put :update, params: { id: organisations_user.id, organisations_user: payload }
          }.not_to change(OrganisationsUser, :count)

          expect(response.status).to eq(422)
          expect(parsed_body['error']).to eq("The 'email' field cannot be modified")
        end

        it "prevents the user from modifying his/her verified mobile through nested attributes" do
          user.update!(is_mobile_verified: true)

          payload = {
            **organisations_user_payload,
            user_attributes: user_attributes.merge(mobile: '98541236')
          }

          expect {
            put :update, params: { id: organisations_user.id, organisations_user: payload }
          }.not_to change(OrganisationsUser, :count)

          expect(response.status).to eq(422)
          expect(parsed_body['error']).to eq("The 'mobile' field cannot be modified")
        end

        [:approved, :expired, :denied].each do |status|
          it "prevents a user from setting his/her status as '#{status}'" do
            expect {
              put :update, params: { id: organisations_user.id, organisations_user: organisations_user_payload.merge(status: status.to_s) }
            }.not_to change(OrganisationsUser, :count)

            expect(response.status).to eq(403)
            expect(parsed_body['error']).to eq('Access Denied')
          end
        end

        context 'readonly params' do
          it "forbids changing the user_id field" do
            expect {
              put :update, params: { id: organisations_user.id, organisations_user: organisations_user_payload.update(user_id: other_user.id) }
            }.not_to change(OrganisationsUser, :count)

            expect(response.status).to eq(403)
            expect(parsed_body['error']).to eq("The 'user_id' field cannot be modified")
          end

          it "forbids changing the organisation_id field" do
            expect {
              put :update, params: { id: organisations_user.id, organisations_user: organisations_user_payload.update(organisation_id: other_organisation.id) }
            }.not_to change(OrganisationsUser, :count)

            expect(response.status).to eq(403)
            expect(parsed_body['error']).to eq("The 'organisation_id' field cannot be modified")
          end
        end

        context 'missing params' do
          [:user_id, :organisation_id].each do |param|
            it "fails if the '#{param}' param is missing'" do
              expect {
                post :create, format: :json, params: { organisations_user: organisations_user_payload.except(param) }
              }.not_to change(OrganisationsUser, :count)

              expect(response.status).to eq(422)
              expect(parsed_body['error']).to eq("Missing parameter #{param}")
            end
          end
        end
      end

      describe '/GET all_status' do
        it 'returns 200' do
          get :status_list
          expect(response).to have_http_status(:success)
        end

        it 'returns all status' do
          get :status_list
          expect(parsed_body['status']).to match_array(OrganisationsUser.all_status)
        end
      end
    end
  end
end
