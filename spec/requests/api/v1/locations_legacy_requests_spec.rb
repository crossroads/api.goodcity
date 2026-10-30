# frozen_string_literal: true

require 'rails_helper'

# GET /api/v1/locations as the legacy apps send it, replayed through the router, apipie, CanCan and the controller with
# each app's header and its kind of user. None of them sends exclude_retired or with_counts, so each answer must be the
# lean { id, building, area } rows it is today. The same examples pass unchanged on master.
#
#   stock.goodcity (78b3c19), as a Stock fulfilment user:
#     - app/routes/items/new.js: store.findAll("location")                       GET /locations
#     - app/routes/index.js, app/routes/item_filters.js:
#       store.query("location", { recently_used: true })                        GET /locations?recently_used=true
#     - app/components/goodcity/locations-search-overlay.js (searchProps {}, perPage 10):
#                                                                               GET /locations?searchText=&per_page=10&page=1
#     - app/controllers/item_filters.js (ember-infinity, perPage 25, stockRequest): GET /locations?per_page=25&page=1&stockRequest=true&searchText=
#   admin.goodcity (d2ed17b0), as a Reviewer: PRELOAD_AUTHORIZED_TYPES "location" GET /locations
# No legacy app creates, renames or deletes a location.
RSpec.describe 'GET /api/v1/locations: the legacy apps\' own requests', type: :request do
  def role_user(role_name)
    permissions = YAML.load_file(Rails.root.join('db', 'permissions_roles.yml'))[role_name].flatten
    role = create("#{role_name.parameterize.underscore}_role", :with_permissions, permissions: permissions)
    create(:user).tap { |u| create(:user_role, user: u, role: role) }
  end

  def headers_for(user, app)
    jwt = Rails.application.secrets.jwt
    payload = { iss: jwt[:issuer], exp: 14.days.from_now.to_i, user_id: user.id, iat: Time.current.to_i }
    { 'Authorization' => "Bearer #{JWT.encode(payload, jwt[:secret_key], jwt[:hmac_sha_algo])}",
      'X-GOODCITY-APP-NAME' => app, 'Accept-Language' => 'en' }
  end

  let(:stock_user) { role_user('Stock fulfilment') }
  let(:stock) { headers_for(stock_user, 'stock.goodcity') }
  let(:admin) { headers_for(role_user('Reviewer'), 'admin.goodcity') }

  let!(:shelf) { Location.create!(building: 'Replay52', area: 'Shelf') }
  let!(:floor) { Location.create!(building: 'Replay52', area: 'Floor') }
  let!(:yard)  { Location.create!(building: 'Elsewhere52', area: 'Yard') }

  before do
    Rails.cache.clear
    User.current_user = nil
  end

  after { User.current_user = nil }

  def lean(*locations)
    locations.map { |l| { 'id' => l.id, 'building' => l.building, 'area' => l.area } }
  end

  def body
    JSON.parse(response.body)
  end

  def read(path, headers, params = {})
    get path, params: params, headers: headers
    expect(response.status).to eq(200), response.body
    body
  end

  it 'stock: findAll, every location as { id, building, area }, the same from the cache' do
    first = read('/api/v1/locations', stock)
    expect(first.keys).to eq(['locations'])
    expect(first['locations']).to match_array(lean(*Location.all))
    expect(read('/api/v1/locations', stock)).to eq(first)
  end

  it 'admin: the preload, every location as { id, building, area }' do
    expect(read('/api/v1/locations', admin)['locations']).to match_array(lean(*Location.all))
  end

  it 'stock: recently_used, the places this user last moved stock to, newest first', versioning: true do
    PaperTrail.request(whodunnit: stock_user.id.to_s) do
      pkg = create(:package, :with_inventory_number, state: 'received', received_quantity: 2)
      User.current_user = stock_user
      initialize_inventory(pkg, location: yard)
      Package::Operations.move(1, pkg, from: yard.id, to: shelf.id)
    end
    User.current_user = nil
    used = read('/api/v1/locations', stock, recently_used: 'true')
    expect(used.keys).to eq(['locations'])
    expect(used['locations'].first).to eq(lean(shelf).first)
    expect(used['locations']).to all(satisfy { |row| row.keys.sort == %w[area building id] })
    expect(used['locations'].map { |l| l['id'] }).to match_array(Location.recently_used(stock_user.id).map(&:id))
  end

  it 'stock: the location search overlay, searchText, per_page 10, page 1' do
    found = read('/api/v1/locations', stock, searchText: 'Replay52', per_page: '10', page: '1')
    expect(found['meta']).to eq('total_pages' => 1, 'search' => 'Replay52')
    expect(found['locations']).to match_array(lean(shelf, floor))
  end

  it 'stock: the item filters page, per_page 25, page 1, stockRequest, searchText' do
    found = read('/api/v1/locations', stock, per_page: '25', page: '1', stockRequest: 'true', searchText: 'Yard')
    expect(found['meta']).to eq('total_pages' => 1, 'search' => 'Yard')
    expect(found['locations']).to eq(lean(yard))
  end
end
