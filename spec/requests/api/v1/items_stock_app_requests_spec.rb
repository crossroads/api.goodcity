# frozen_string_literal: true

require 'rails_helper'

# GET /api/v1/items as the legacy stock app sends it (stock.goodcity 78b3c19), replayed through the router, apipie,
# CanCan and the controller: a Stock fulfilment user with every permission of that role, the stock app header and the
# exact params each screen sends. None of them sends location_id, so each answer must be what it was before the
# location_id filter. The same examples pass unchanged on master.
#
#   - Items search (app/controllers/items/index.js, loadMoreItems): stockRequest, state (the state filters, or
#     "received"), location (the location filter, "<building>-<area>", when one is set), searchText, shallow,
#     per_page=25, page. Empty values are dropped by trimQuery.
#   - Designate an item to an order (app/controllers/orders/items.js): stockRequest, restrictMultiQuantity (when
#     the setting is on), searchText, shallow, per_page=25, page.
#   - Add an item to a box, pallet or set (app/components/goodcity/item-search-overlay.js): searchText, shallow,
#     per_page=10, page, associated_package_types_for, storage_type_name, states (the API doesn't read `states`).
RSpec.describe 'GET /api/v1/items: the stock app\'s own requests', type: :request do
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
  let(:headers) { headers_for(stock_user, 'stock.goodcity') }

  let!(:package_storage) { create(:storage_type, :with_pkg) }
  let!(:box_storage) { create(:storage_type, :with_box) }
  let!(:shelf) { Location.create!(building: 'Legacy51', area: 'Shelf') }
  let!(:floor) { Location.create!(building: 'Legacy51', area: 'Floor') }
  # base_package_type: no child types from db/package_types.yml, so each type holds only itself (the overlay test
  # below must not depend on which two codes the factory sequence hands out).
  let!(:chair_type) { create(:base_package_type) }
  let!(:table_type) { create(:base_package_type) }

  let!(:chair) { create(:package, :with_inventory_number, state: 'received', received_quantity: 1, package_type: chair_type, notes: 'legacy replay chair') }
  let!(:chairs) { create(:package, :with_inventory_number, state: 'received', received_quantity: 3, package_type: chair_type, notes: 'legacy replay chairs') }
  let!(:table) { create(:package, :with_inventory_number, state: 'received', received_quantity: 1, package_type: table_type, notes: 'legacy replay table') }
  let!(:no_number) { create(:package, state: 'received', received_quantity: 1, package_type: chair_type, inventory_number: nil) }

  before do
    User.current_user = stock_user
    initialize_inventory(chair, location: shelf)
    initialize_inventory(chairs, location: shelf)
    initialize_inventory(table, location: floor)
    initialize_inventory(no_number, location: shelf)
    # Each request signs in by its own token: nothing an earlier example left in User.current_user may help it pass.
    User.current_user = nil
  end

  after { User.current_user = nil }

  def body
    JSON.parse(response.body)
  end

  def ids
    body['items'].map { |i| i['id'] }
  end

  def items(params)
    get '/api/v1/items', params: params, headers: headers
    expect(response.status).to eq(200), response.body
  end

  describe 'Items search (items/index.js)' do
    it 'opening the list: stockRequest, state=received, shallow, per_page 25, page 1' do
      items(stockRequest: 'true', state: 'received', shallow: 'true', per_page: '25', page: '1')
      expect(ids).to eq([table.id, chairs.id, chair.id])
      expect(body['meta']).to eq('total_pages' => 1, 'search' => nil)
      expect(body.keys).to include('meta', 'items', 'packages_locations')
      row = body['items'].find { |i| i['id'] == chair.id }
      expect(row['inventory_number']).to eq(chair.inventory_number)
      expect(row['package_type_id']).to eq(chair_type.id)
      expect(body['packages_locations'].map { |pl| [pl['package_id'], pl['location_id']] })
        .to include([chair.id, shelf.id], [chairs.id, shelf.id], [table.id, floor.id])
    end

    it 'with the state and location filters set: state=in_stock,received and location=<building>-<area>' do
      items(stockRequest: 'true', state: 'in_stock,received', location: 'Legacy51-Shelf', shallow: 'true', per_page: '25', page: '1')
      expect(ids).to eq([chairs.id, chair.id])
      items(stockRequest: 'true', state: 'received', location: 'Legacy51-(All areas)', shallow: 'true', per_page: '25', page: '1')
      # "(All areas)" reads only the building's first location, so the table on the Floor is not listed: today's
      # behaviour (OA-13), kept as it is.
      expect(ids).to eq([chairs.id, chair.id])
    end

    it 'a typed search: searchText (an inventory number) with the default state' do
      items(stockRequest: 'true', state: 'received', searchText: chair.inventory_number, shallow: 'true', per_page: '25', page: '1')
      expect(ids).to eq([chair.id])
      expect(body['meta']).to eq('total_pages' => 1, 'search' => chair.inventory_number)
    end

    it 'the next page: page 2 of 25 is empty here, as before' do
      items(stockRequest: 'true', state: 'received', shallow: 'true', per_page: '25', page: '2')
      expect(ids).to eq([])
      expect(body['meta']['total_pages']).to eq(1)
    end
  end

  describe 'Designate to an order (orders/items.js)' do
    it 'stockRequest, searchText, shallow, per_page 25, page 1' do
      items(stockRequest: 'true', searchText: 'legacy replay', shallow: 'true', per_page: '25', page: '1')
      expect(ids).to match_array([table.id, chairs.id, chair.id])
    end

    it 'with restrictMultiQuantity on (the "only designate singletons" setting)' do
      items(stockRequest: 'true', restrictMultiQuantity: 'true', searchText: 'legacy replay', shallow: 'true', per_page: '25', page: '1')
      expect(ids).to match_array([table.id, chair.id])
    end
  end

  describe 'Add an item to a box, pallet or set (item-search-overlay.js)' do
    it 'searchText, shallow, per_page 10, page 1, associated_package_types_for, storage_type_name, states' do
      items(searchText: 'legacy replay', shallow: 'true', per_page: '10', page: '1',
            associated_package_types_for: chair_type.code, storage_type_name: 'Box', states: 'in_stock,designated')
      expect(ids).to match_array([chairs.id, chair.id])
      items(searchText: 'legacy replay', shallow: 'true', per_page: '10', page: '1',
            associated_package_types_for: table_type.code, storage_type_name: 'Package', states: 'in_stock,designated')
      expect(ids).to eq([table.id])
    end
  end

  it 'the same requests as an Order fulfilment user (the other stock role) answer the same rows' do
    params = { stockRequest: 'true', state: 'received', shallow: 'true', per_page: '25', page: '1' }
    items(params)
    as_stock = response.body
    get '/api/v1/items', params: params, headers: headers_for(role_user('Order fulfilment'), 'stock.goodcity')
    expect(response.status).to eq(200)
    expect(JSON.parse(response.body)['items'].map { |i| i['id'] }).to eq(JSON.parse(as_stock)['items'].map { |i| i['id'] })
  end
end
