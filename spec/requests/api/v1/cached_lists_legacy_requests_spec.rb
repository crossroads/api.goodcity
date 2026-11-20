# frozen_string_literal: true

require 'rails_helper'

# The cached taxonomy lists (CacheableJson) as each legacy app preloads them, replayed through the router, CanCan
# and the controller, with that app's header and its kind of user (or no sign-in, where the app reads the list before
# one). Every CacheableJson list shares one cache key, which this branch changes, so each list is read twice (the
# second read comes from the cache), after an insert and after an edit, and must list exactly the rows it lists
# today. The same examples pass unchanged on master.
#
# Where each request comes from (preload lists in each app's config/environment.js):
#   admin.goodcity  PRELOAD_TYPES territory; PRELOAD_AUTHORIZED_TYPES package_type, donor_condition, rejection_reason,
#                   role, location (and others that are not cached lists)
#   stock.goodcity  PRELOAD_TYPES booking_type, identity_type, district, role; app/mixins/preload_data.js
#                   store.query("code", { stock: true }) = GET /package_types?stock=true
#   browse.goodcity PRELOAD_TYPES package_type, district, territory, package_category, donor_condition (before and
#                   after sign-in); PRELOAD_AUTHORIZED_TYPES booking_type
#   app.goodcity    PRELOAD_TYPES territory; PRELOAD_AUTHORIZED_TYPES donor_condition, permission
RSpec.describe 'Cached taxonomy lists as the legacy apps preload them', type: :request do
  def role_user(role_name)
    permissions = YAML.load_file(Rails.root.join('db', 'permissions_roles.yml'))[role_name].flatten
    role = create("#{role_name.parameterize.underscore}_role", :with_permissions, permissions: permissions)
    create(:user).tap { |u| create(:user_role, user: u, role: role) }
  end

  def headers_for(user, app)
    headers = { 'X-GOODCITY-APP-NAME' => app, 'Accept-Language' => 'en' }
    return headers if user.nil?

    jwt = Rails.application.secrets.jwt
    payload = { iss: jwt[:issuer], exp: 14.days.from_now.to_i, user_id: user.id, iat: Time.current.to_i }
    headers.merge('Authorization' => "Bearer #{JWT.encode(payload, jwt[:secret_key], jwt[:hmac_sha_algo])}")
  end

  # path, the JSON root, the rows the list holds (computed here, never from the cache), and a factory call that
  # adds one more row to that list.
  lists_by_name = {
    package_types:    ['/api/v1/package_types', 'package_types', -> { PackageType.pluck(:id) }, -> { create(:base_package_type) }],
    stock_codes:      ['/api/v1/package_types?stock=true', 'codes', -> { PackageType.visible.pluck(:id) }, -> { create(:base_package_type).tap { |t| t.update!(allow_package: true) } }],
    locations:        ['/api/v1/locations', 'locations', -> { Location.pluck(:id) }, -> { Location.create!(building: "LR#{SecureRandom.hex(3)}", area: 'A') }],
    territories:      ['/api/v1/territories', 'territories', -> { Territory.pluck(:id) }, -> { create(:territory) }],
    districts:        ['/api/v1/districts', 'districts', -> { District.pluck(:id) }, -> { create(:district) }],
    donor_conditions: ['/api/v1/donor_conditions', 'donor_conditions', -> { DonorCondition.pluck(:id) }, -> { create(:donor_condition) }],
    rejection_reasons: ['/api/v1/rejection_reasons', 'rejection_reasons', -> { RejectionReason.pluck(:id) }, -> { create(:rejection_reason) }],
    roles:            ['/api/v1/roles', 'roles', -> { Role.visible.pluck(:id) }, -> { create(:role, name: "Legacy replay #{SecureRandom.hex(3)}") }],
    permissions:      ['/api/v1/permissions', 'permissions', -> { Permission.visible.pluck(:id) }, -> { create(:permission, name: "can_replay_#{SecureRandom.hex(3)}") }],
    booking_types:    ['/api/v1/booking_types', 'booking_types', -> { BookingType.pluck(:id) }, -> { create(:booking_type, identifier: "replay#{SecureRandom.hex(3)}") }],
    identity_types:   ['/api/v1/identity_types', 'identity_types', -> { IdentityType.pluck(:id) }, -> { create(:identity_type) }],
    package_categories: ['/api/v1/package_categories', 'package_categories', -> { PackageCategory.pluck(:id) }, -> { create(:package_category) }]
  }.freeze

  apps = {
    'admin.goodcity (Reviewer)' => ['admin.goodcity', -> { role_user('Reviewer') }, %i[territories package_types donor_conditions rejection_reasons roles locations]],
    'stock.goodcity (Stock fulfilment)' => ['stock.goodcity', -> { role_user('Stock fulfilment') }, %i[booking_types identity_types districts roles stock_codes]],
    'browse.goodcity (charity user)' => ['browse.goodcity', -> { create(:user, :charity) }, %i[package_types districts territories package_categories donor_conditions booking_types]],
    'browse.goodcity (not signed in)' => ['browse.goodcity', -> { nil }, %i[package_types districts territories package_categories donor_conditions]],
    'app.goodcity (donor)' => ['app.goodcity', -> { create(:user) }, %i[territories donor_conditions permissions]],
    'app.goodcity (not signed in)' => ['app.goodcity', -> { nil }, %i[territories]]
  }.freeze

  before do
    Rails.cache.clear
    2.times do
      lists_by_name.each_value { |(_, _, _, add)| instance_exec(&add) }
    end
    User.current_user = nil
  end

  after { User.current_user = nil }

  def read(path, headers)
    get path, headers: headers
    expect(response.status).to eq(200), "#{path}: #{response.status} #{response.body.first(300)}"
    response.body
  end

  def ids_in(body, root)
    JSON.parse(body).fetch(root).map { |row| row['id'] }
  end

  it 'runs against a real cache store, so the second read of each list really comes from the cache' do
    expect(Rails.cache).not_to be_a(ActiveSupport::Cache::NullStore)
    Rails.cache.write('legacy-replay-probe', 1)
    expect(Rails.cache.read('legacy-replay-probe')).to eq(1)
  end

  apps.each do |label, (app, user_fn, lists)|
    describe label do
      lists.each do |list|
        path, root, rows, add = lists_by_name.fetch(list)

        it "GET #{path} lists exactly its rows, from the cache the second time, and follows an insert and an edit" do
          headers = headers_for(instance_exec(&user_fn), app)

          first = read(path, headers)
          expect(ids_in(first, root)).to match_array(instance_exec(&rows))
          expect(read(path, headers)).to eq(first)

          added = instance_exec(&add)
          expect(ids_in(read(path, headers), root)).to include(added.id)
          expect(ids_in(response.body, root)).to match_array(instance_exec(&rows))

          added.update_column(:updated_at, 1.minute.from_now)
          expect(ids_in(read(path, headers), root)).to match_array(instance_exec(&rows))
        end
      end
    end
  end
end
