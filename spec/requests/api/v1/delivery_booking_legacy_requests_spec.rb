# frozen_string_literal: true

require 'rails_helper'

# Booking a delivery as the legacy apps do it, replayed through the router, apipie, CanCan and the controller, in
# English and in Chinese. Every booking pushes a sentence to reviewers (Delivery#notify_reviewers), which is where this
# branch's locale strings and zh-tw ordinals are read. The donor app and the admin app share these screens
# (shared.goodcity e357a9c):
#   - app/controllers/offer/plan_delivery.js: store.createRecord("delivery", { offer }).save()     POST /deliveries
#   - app/controllers/delivery/drop_off_schedule.js                                              POST /confirm_delivery
#       delivery: { id, deliveryType: "Drop Off", offerId, scheduleAttributes: { slot, scheduledAt, slotName } }
#   - app/controllers/delivery/book_timeslot.js, then contact_details.js (Crossroads collects)    POST /confirm_delivery
#       delivery: { id, deliveryType: "Alternate", offerId, scheduleAttributes: { zone, resource, scheduledAt, slot,
#       slotName }, contactAttributes: { name, mobile, addressAttributes: { street, flat, building, districtId,
#       addressType } } }
#   - app/controllers/delivery/confirm_van.js (GoGoVan)                                          POST /confirm_delivery
#       delivery: { id, deliveryType: "Gogovan", offerId, scheduleAttributes, contactAttributes }, gogovanOrder: {...}
# The donor signs in with the donor app header (a non-staff user); a reviewer books for a donor from the admin app.
# The confirm_delivery body is form-encoded, as jQuery sends it; the delivery create is Ember Data's JSON.
#
# "every booking still succeeds" passes unchanged on master. "the push to reviewers is a sentence" is what this branch
# fixes: on master the Alternate text, and every Chinese date, read "translation missing" (API-61, API-63).
RSpec.describe 'Booking a delivery: the legacy apps\' own requests', type: :request do
  def role_user(role_name)
    permissions = YAML.load_file(Rails.root.join('db', 'permissions_roles.yml'))[role_name].flatten
    role = create("#{role_name.parameterize.underscore}_role", :with_permissions, permissions: permissions)
    create(:user).tap { |u| create(:user_role, user: u, role: role) }
  end

  def headers_for(user, app, language)
    jwt = Rails.application.secrets.jwt
    payload = { iss: jwt[:issuer], exp: 14.days.from_now.to_i, user_id: user.id, iat: Time.current.to_i }
    { 'Authorization' => "Bearer #{JWT.encode(payload, jwt[:secret_key], jwt[:hmac_sha_algo])}",
      'X-GOODCITY-APP-NAME' => app, 'Accept-Language' => language }
  end

  let(:offer) { create :offer, :reviewed }
  let(:donor) { offer.created_by }
  let(:district) { create :district }
  # A weekday a few weeks ahead, never a holiday here, written as a browser's Date#toString.
  let(:day) { (Date.current + 21.days).then { |d| d.saturday? ? d + 2 : (d.sunday? ? d + 1 : d) } }
  let(:scheduled_at) { "#{day.strftime('%a %b %d %Y')} 00:00:00 GMT+0800 (Hong Kong Standard Time)" }
  let(:pushes) { [] }

  before do
    allow_any_instance_of(PushService).to receive(:send_update_store)
    allow_any_instance_of(PushService).to receive(:send_notification) { |_service, *args| pushes << args }
    User.current_user = nil
  end

  after { User.current_user = nil }

  # plan_delivery.js: a new delivery record with only its offer set, saved by Ember Data (JSON).
  def start_delivery(headers)
    post '/api/v1/deliveries',
         params: { delivery: { start: nil, finish: nil, offer_id: offer.id.to_s, contact_id: nil, schedule_id: nil,
                               delivery_type: nil, gogovan_order_id: nil } }.to_json,
         headers: headers.merge('CONTENT_TYPE' => 'application/json')
    expect(response.status).to eq(201), response.body
    JSON.parse(response.body)['delivery']['id']
  end

  def drop_off(delivery_id)
    { delivery: { id: delivery_id.to_s, deliveryType: 'Drop Off', offerId: offer.id.to_s,
                  scheduleAttributes: { slot: '2', scheduledAt: scheduled_at, slotName: '2PM-4PM' } } }
  end

  def crossroads_collects(delivery_id)
    { delivery: { id: delivery_id.to_s, deliveryType: 'Alternate', offerId: offer.id.to_s,
                  scheduleAttributes: { zone: 'Zone 1', resource: 'Truck 1', scheduledAt: scheduled_at, slot: '1', slotName: '10AM-1PM' },
                  contactAttributes: { name: 'Replay Donor', mobile: '+85251111111',
                                       addressAttributes: { street: '1 Replay Street', flat: '1A', building: 'Replay Building',
                                                            districtId: district.id.to_s, addressType: 'collection' } } } }
  end

  def confirm(body, headers)
    post '/api/v1/confirm_delivery', params: body, headers: headers
    expect(response.status).to eq(200), response.body
    JSON.parse(response.body)
  end

  [
    ['the donor app, as the donor', 'app.goodcity', -> { donor }],
    ['the admin app, as a reviewer booking for the donor', 'admin.goodcity', -> { role_user('Reviewer') }]
  ].each do |who, app, user_fn|
    %w[en zh-tw].each do |language|
      describe "#{who}, Accept-Language #{language}" do
        let(:headers) { headers_for(instance_exec(&user_fn), app, language) }

        it 'every booking still succeeds: a drop-off, then a Crossroads collection on the same offer' do
          id = start_delivery(headers)
          body = confirm(drop_off(id), headers)
          expect(body['delivery']['delivery_type']).to eq('Drop Off')
          expect(offer.reload.state).to eq('scheduled')

          id = start_delivery(headers)
          body = confirm(crossroads_collects(id), headers)
          expect(body['delivery']['delivery_type']).to eq('Alternate')
          expect(Delivery.find(id).contact.name).to eq('Replay Donor')
          expect(Delivery.find(id).schedule.slot_name).to eq('10AM-1PM')
        end

        it 'the push to reviewers is a sentence naming the donor and the date, for both kinds' do
          confirm(drop_off(start_delivery(headers)), headers)
          confirm(crossroads_collects(start_delivery(headers)), headers)
          messages = pushes.map { |(_channel, _app, data)| data[:message] }
          expect(messages.size).to eq(2)
          messages.each do |message|
            expect(message).not_to match(/translation missing/i)
            expect(message).to include(donor.full_name)
            expect(message).to include(day.day.to_s)
            expect(message).to include(day.strftime('%b %Y'))
          end
          expect(messages.last).to include('Crossroads will collect') if language == 'en'
        end
      end
    end
  end
end
