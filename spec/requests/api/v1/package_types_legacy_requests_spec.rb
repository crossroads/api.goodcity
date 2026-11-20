# frozen_string_literal: true

require 'rails_helper'

# GET /api/v1/package_types as the legacy apps send it, replayed through the router, CanCan and the controller with
# each app's header and its kind of user, plus the one legacy reader of every version's location_id. None of the apps
# sends admin=true or calls the new member routes, so each answer must be the cached body it is today: compared here,
# parsed, with the body the pre-change serializer builds from the database. The same examples pass unchanged on
# master.
#
#   admin.goodcity (d2ed17b0), a Reviewer:   PRELOAD_AUTHORIZED_TYPES "package_type"      GET /package_types
#   browse.goodcity (c4b54b5f), before and after sign-in: PRELOAD_TYPES "package_type"     GET /package_types
#   stock.goodcity (78b3c19), Stock fulfilment: app/mixins/preload_data.js, app/routes/search_code.js,
#     app/routes/orders/add_request.js: store.query("code", { stock: true })            GET /package_types?stock=true
#   stock.goodcity: app/routes/index.js, app/routes/item_filters.js                    GET /locations?recently_used=true
#     (reads every version's object_changes -> location_id; package types now keep versions)
# No legacy app creates, edits or deletes a package type.
RSpec.describe 'GET /api/v1/package_types: the legacy apps\' own requests', type: :request do
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

  let(:stock_user) { role_user('Stock fulfilment') }
  # base_package_type: no child types from db/package_types.yml, and created first, so no later factory call can hand
  # back one of these rows (the factory finds a type by its code) or depend on which codes the sequence gives out.
  let!(:box) { create(:base_package_type, allow_box: true, allow_package: false) }
  let!(:chair) { create(:base_package_type) }
  let!(:retired_type) { create(:base_package_type, allow_package: false, allow_box: false, allow_pallet: false, visible_in_selects: false) }

  before do
    create(:subpackage_type, package_type: box, child_package_type: chair, is_default: false)
    Rails.cache.clear
    User.current_user = nil
  end

  after { User.current_user = nil }

  # Every list in a body (the types and their sideloaded locations), each keyed by id: the cached list carries no
  # ORDER BY, so only the order of rows may differ.
  def by_id(body)
    body.transform_values { |rows| rows.index_by { |r| r['id'] } }
  end

  # The body the pre-change serializer builds, uncached, for this reader: it adds the child codes only for a signed-in
  # one (PackageTypeSerializer#include_attribute?).
  def expected(scope, root, as:)
    User.current_user = as
    by_id(JSON.parse(ActiveModel::ArraySerializer.new(scope.with_eager_load, each_serializer: Api::V1::PackageTypeSerializer, root: root).as_json.to_json))
  ensure
    User.current_user = nil
  end

  def read(path, headers, root)
    get path, headers: headers
    expect(response.status).to eq(200), response.body
    by_id(JSON.parse(response.body)).tap { |body| expect(body.keys).to include(root) }
  end

  {
    'admin.goodcity, a Reviewer' => ['admin.goodcity', -> { role_user('Reviewer') }],
    'browse.goodcity, a charity user' => ['browse.goodcity', -> { create(:user, :charity) }],
    'browse.goodcity, not signed in' => ['browse.goodcity', -> { nil }]
  }.each do |label, (app, user_fn)|
    it "#{label}: GET /package_types is every type, as the pre-change serializer builds it, cold and from the cache" do
      user = instance_exec(&user_fn)
      headers = headers_for(user, app)
      want = expected(PackageType.all, 'package_types', as: user)
      expect(want['package_types'].keys).to include(box.id, chair.id, retired_type.id)
      expect(read('/api/v1/package_types', headers, 'package_types')).to eq(want)
      expect(read('/api/v1/package_types', headers, 'package_types')).to eq(want)
    end
  end

  it 'stock.goodcity, Stock fulfilment: GET /package_types?stock=true is the visible types, cold and from the cache' do
    headers = headers_for(stock_user, 'stock.goodcity')
    want = expected(PackageType.visible, 'codes', as: stock_user)
    expect(want['codes'].keys).to include(box.id, chair.id)
    expect(want['codes'].keys).not_to include(retired_type.id)
    expect(read('/api/v1/package_types?stock=true', headers, 'codes')).to eq(want)
    expect(read('/api/v1/package_types?stock=true', headers, 'codes')).to eq(want)
  end

  it 'stock.goodcity: a box type lists its allowed child types as before' do
    codes = read('/api/v1/package_types?stock=true', headers_for(stock_user, 'stock.goodcity'), 'codes')
    expect(codes['codes'][box.id]).to eq(expected(PackageType.visible, 'codes', as: stock_user)['codes'][box.id])
    expect(codes['codes'][box.id].to_s).to include(chair.code)
  end

  it 'stock.goodcity: recently_used lists only the places stock was moved to, never a goods type\'s default location', versioning: true do
    yard = Location.create!(building: 'Replay53', area: 'Yard')
    shelf = Location.create!(building: 'Replay53', area: 'Shelf')
    type_home = Location.create!(building: 'Replay53', area: 'TypeHome')
    other_home = Location.create!(building: 'Replay53', area: 'OtherHome')
    PaperTrail.request(whodunnit: stock_user.id.to_s) do
      User.current_user = stock_user
      pkg = create(:package, :with_inventory_number, state: 'received', received_quantity: 2)
      initialize_inventory(pkg, location: yard)
      Package::Operations.move(1, pkg, from: yard.id, to: shelf.id)
      # The same person edits goods types: one created with a default location, then moved to another.
      edited = create(:base_package_type, location: type_home)
      edited.update!(location: other_home, name_en: 'Replay renamed')
    end
    User.current_user = nil
    get '/api/v1/locations', params: { recently_used: 'true' }, headers: headers_for(stock_user, 'stock.goodcity')
    expect(response.status).to eq(200)
    ids = JSON.parse(response.body)['locations'].map { |l| l['id'] }
    expect(ids.first).to eq(shelf.id)
    expect(ids).not_to include(type_home.id, other_home.id)
  end
end
