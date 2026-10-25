# frozen_string_literal: true

require 'rails_helper'

# GET /api/v1/organisations with the optional filters (filter_organisation_type_id, filter_country_id, filter_has_orders,
# filter_has_members, filter_has_registration) and meta.total_count. Request specs: routing, apipie's param check, CanCan and the controller run
# as they do for a real client. The legacy examples build the expected body with the pre-change action, verbatim, so a
# client that sends no filter gets exactly what it got before, plus `meta.total_count`.
RSpec.describe 'GET /api/v1/organisations filters', type: :request do
  let(:supervisor) { create(:user, :with_token, :with_can_check_organisations_permission, role_name: 'Supervisor') }
  let!(:hong_kong) { create(:country, name_en: DEFAULT_COUNTRY) }
  let!(:other_country) { create(:country, name_en: 'Singapore') }
  let!(:ngo) { create(:organisation_type, name_en: 'NGO') }
  let!(:school) { create(:organisation_type, name_en: 'School') }

  let(:headers) do
    jwt = Rails.application.secrets.jwt
    payload = { iss: jwt[:issuer], exp: 14.days.from_now.to_i, user_id: supervisor.id, iat: Time.current.to_i }
    {
      'Authorization' => "Bearer #{JWT.encode(payload, jwt[:secret_key], jwt[:hmac_sha_algo])}",
      'X-GOODCITY-APP-NAME' => 'stock.goodcity'
    }
  end
  # methods, not lets: an example makes several requests, and each must be read afresh
  def body
    JSON.parse(response.body)
  end

  def ids
    body['organisations'].map { |o| o['id'] }
  end

  def org(name, type: ngo, country: hong_kong, registration: nil)
    o = create(:organisation, name_en: name, name_zh_tw: nil, organisation_type: type || ngo, country: country || hong_kong, registration: registration)
    o.update_column(:organisation_type_id, nil) if type.nil?
    o.update_column(:country_id, nil) if country.nil?
    o
  end

  # Zebra Harbour 1–6 match the term "Zebra Harbour"; Quokka Lane matches no term used here.
  let!(:plain)    { org('Zebra Harbour Alpha', registration: '91/1001') }
  let!(:schooled) { org('Zebra Harbour Beta', type: school, registration: " \t\n ") }
  let!(:untyped)  { org('Zebra Harbour Gamma', type: nil) }
  let!(:abroad)   { org('Zebra Harbour Delta', country: other_country, registration: 'S-2') }
  let!(:stateless) { org('Zebra Harbour Epsilon', country: nil) }
  let!(:busy)     { org('Zebra Harbour Zeta', registration: '91/1006') }
  let!(:elsewhere) { org('Quokka Lane Society', registration: '91/2001') }

  before do
    create_list(:order, 3, organisation: busy)
    create(:order, organisation: elsewhere)
    create(:organisations_user, :approved, organisation: busy)
    create(:organisations_user, :pending, organisation: busy)
    create(:organisations_user, :pending, organisation: plain)
    create(:organisations_user, :expired, organisation: schooled)
    create(:organisations_user, :denied, organisation: schooled)
    create(:organisations_user, :approved, organisation: elsewhere)
  end

  def search(params)
    get '/api/v1/organisations', params: params, headers: headers
    expect(response.status).to eq(200), response.body
  end

  # The pre-change action, verbatim (find_record_and_render_json before this branch), as the JSON string Rails renders,
  # serialized as the signed-in supervisor (UserSerializer shows staff the users' addresses and mobiles). Params are
  # strings, as a request carries them. `total_count:` adds the one new key where this branch puts it.
  def legacy_json(params, serializer: Api::V1::OrganisationSerializer, total_count: nil, as: supervisor)
    User.current_user = as
    records = if params['ids'].present?
                Organisation.where(id: params['ids']).page(params['page']).per(params['per_page'] || DEFAULT_SEARCH_COUNT)
              else
                Organisation.with_order.search(params['searchText']).page(params['page']).per(params['per_page'] || DEFAULT_SEARCH_COUNT)
              end
    data = ActiveModel::ArraySerializer.new(records, each_serializer: serializer, root: 'organisations', include_orders_count: true).as_json
    meta = total_count.nil? ? { total_pages: records.total_pages, "search": params['searchText'] } : { total_pages: records.total_pages, total_count: total_count, "search": params['searchText'] }
    { "meta": meta }.merge(data).to_json
  end

  # The request shapes today's apps send (see the PR's "Backwards compatibility"), each answered exactly as before (every
  # key, value and array order) except for `meta.total_count` — and with that one key taken out it is the pre-change body.
  # (Compared parsed: this harness serializes the sideloads in another key order than `render json:` does.)
  describe 'legacy request shapes: identical responses, apart from the added meta.total_count' do
    def expect_legacy(path, params, serializer: Api::V1::OrganisationSerializer)
      get path, params: params, headers: headers
      expect(response.status).to eq(200)
      wire = params.transform_keys(&:to_s).transform_values { |v| v.is_a?(Array) ? v.map(&:to_s) : v.to_s }
      count = JSON.parse(response.body)['meta']['total_count']
      expect(count).to be_a(Integer)
      body = JSON.parse(response.body)
      expect(body).to eq(JSON.parse(legacy_json(wire, serializer: serializer, total_count: count)))
      expect(body['meta'].keys).to eq(%w[total_pages total_count search])
      body['meta'].delete('total_count')
      expect(body).to eq(JSON.parse(legacy_json(wire, serializer: serializer)))
    end

    it 'stock.goodcity organisation search overlay: searchText, page, per_page 25, stockRequest' do
      expect_legacy('/api/v1/organisations', { page: 1, per_page: 25, searchText: 'Zebra Harbour', stockRequest: true })
      expect_legacy('/api/v1/organisations', { page: 2, per_page: 4, searchText: 'Zebra Harbour', stockRequest: true })
      expect(JSON.parse(response.body)['organisations'].size).to eq(2) # page 2 of 6 at 4 a page
    end

    it 'browse.goodcity organisation picker: /organisations/names with url, searchText, per_page, page' do
      expect_legacy('/api/v1/organisations/names', { url: 'organisations/names', searchText: 'Zebra Harbour', per_page: 25, page: 1 }, serializer: Api::V1::OrganisationNamesSerializer)
    end

    it 'browse.goodcity as its real caller: a charity user, the browse app header, /organisations/names' do
      charity = create(:user, :charity)
      jwt = Rails.application.secrets.jwt
      payload = { iss: jwt[:issuer], exp: 14.days.from_now.to_i, user_id: charity.id, iat: Time.current.to_i }
      params = { url: 'organisations/names', searchText: 'Zebra Harbour', per_page: 25, page: 1 }
      get '/api/v1/organisations/names', params: params, headers: { 'Authorization' => "Bearer #{JWT.encode(payload, jwt[:secret_key], jwt[:hmac_sha_algo])}", 'X-GOODCITY-APP-NAME' => 'browse.goodcity' }
      expect(response.status).to eq(200)
      body = JSON.parse(response.body)
      expect(body['meta'].delete('total_count')).to eq(6)
      expect(body).to eq(JSON.parse(legacy_json(params.transform_keys(&:to_s).transform_values(&:to_s), serializer: Api::V1::OrganisationNamesSerializer, as: charity)))
    end

    it 'ids[] (Ember Data findMany shape)' do
      expect_legacy('/api/v1/organisations', { ids: [busy.id, plain.id] })
    end

    it 'an empty or missing term lists nothing, as before' do
      expect_legacy('/api/v1/organisations', { searchText: '' })
      expect(JSON.parse(response.body)['organisations']).to eq([])
      expect_legacy('/api/v1/organisations', {})
      expect(JSON.parse(response.body)['organisations']).to eq([])
    end

    it 'the old param names stay inert: organisation_type_id, country_id, has_* on the index change nothing' do
      expect_legacy('/api/v1/organisations', { searchText: 'Zebra Harbour', organisation_type_id: school.id, country_id: other_country.id, has_orders: 'true', has_members: 'false', has_registration: 'yes' })
      expect(JSON.parse(response.body)['organisations'].size).to eq(6)
      expect_legacy('/api/v1/organisations', { has_orders: 'true' }) # no term: still nothing
    end

    it 'show and orders are untouched' do
      get "/api/v1/organisations/#{busy.id}", headers: headers
      User.current_user = supervisor
      expect(JSON.parse(response.body)).to eq(JSON.parse(Api::V1::OrganisationSerializer.new(busy.reload, root: 'organisations', include_orders_count: true).as_json.to_json))
      get "/api/v1/organisations/#{busy.id}/orders", headers: headers
      expect(JSON.parse(response.body)['designations'].size).to eq(3)
    end
  end

  describe 'the filters never reach ids[] or the names endpoint' do
    it 'ids[] ignores a filter' do
      search(ids: [busy.id, plain.id], filter_has_orders: 'false')
      expect(ids).to match_array([busy.id, plain.id])
    end

    it '/organisations/names ignores the filters (it is open to every role)' do
      get '/api/v1/organisations/names', params: { searchText: 'Zebra Harbour', filter_has_orders: 'true' }, headers: headers
      expect(JSON.parse(response.body)['organisations'].size).to eq(6)
    end
  end

  describe 'with a term (searchText) and a filter: the filtered listing, names that contain the term' do
    it 'type, or none' do
      search(searchText: 'Zebra Harbour', filter_organisation_type_id: school.id)
      expect(ids).to eq([schooled.id])
      search(searchText: 'Zebra Harbour', filter_organisation_type_id: 'none')
      expect(ids).to eq([untyped.id])
      expect(body['meta']['total_count']).to eq(1)
    end

    it 'country, or none' do
      search(searchText: 'Zebra Harbour', filter_country_id: other_country.id)
      expect(ids).to eq([abroad.id])
      search(searchText: 'Zebra Harbour', filter_country_id: 'none')
      expect(ids).to eq([stateless.id])
    end

    it 'orders: any order at all, or none' do
      search(searchText: 'Zebra Harbour', filter_has_orders: 'true')
      expect(ids).to eq([busy.id])
      expect(body['organisations'][0]['orders_count']).to eq(3)
      search(searchText: 'Zebra Harbour', filter_has_orders: 'false')
      expect(ids).to match_array([plain, schooled, untyped, abroad, stateless].map(&:id))
    end

    it 'members are pending or approved; expired and denied are not' do
      search(searchText: 'Zebra Harbour', filter_has_members: 'true')
      expect(ids).to match_array([busy.id, plain.id])
      search(searchText: 'Zebra Harbour', filter_has_members: 'false')
      expect(ids).to match_array([schooled, untyped, abroad, stateless].map(&:id))
    end

    it 'registration: filled in, or empty (spaces, tabs and newlines count as empty)' do
      search(searchText: 'Zebra Harbour', filter_has_registration: 'true')
      expect(ids).to match_array([plain, abroad, busy].map(&:id))
      search(searchText: 'Zebra Harbour', filter_has_registration: 'false')
      expect(ids).to match_array([schooled, untyped, stateless].map(&:id))
    end

    it 'combined: every filter must pass; a row is never repeated however many orders or members it has' do
      search(searchText: 'Zebra Harbour', filter_organisation_type_id: ngo.id, filter_country_id: hong_kong.id, filter_has_orders: 'true', filter_has_members: 'true', filter_has_registration: 'true')
      expect(ids).to eq([busy.id])
      search(searchText: 'Zebra Harbour', filter_has_members: 'true', per_page: 25)
      expect(ids.uniq.size).to eq(ids.size)
      expect(body['meta']['total_count']).to eq(2)
    end

    it 'is never the fuzzy search: names that contain the term, by English name' do
      # the fuzzy search ignores word order, so "Harbour Zebra" finds all six without a filter (legacy, unchanged)...
      search(searchText: 'Harbour Zebra')
      expect(ids).to match_array([plain, schooled, untyped, abroad, stateless, busy].map(&:id))
      # ...but with a filter it is a "contains" match, which no name passes
      search(searchText: 'Harbour Zebra', filter_has_registration: 'true')
      expect(ids).to eq([])
      search(searchText: 'Zebra Harbour Zeta', filter_has_registration: 'true')
      expect(ids).to eq([busy.id])
      search(searchText: 'harbour', filter_has_registration: 'true')
      expect(ids).to eq([plain, abroad, busy].map(&:id)) # Alpha, Delta, Zeta
    end

    it 'searchText and filter_name together are refused, not guessed between' do
      get '/api/v1/organisations', params: { searchText: 'Zebra', filter_name: 'Harbour', filter_has_orders: 'true' }, headers: headers
      expect(response.status).to eq(422)
      expect(body['errors'][0]['message']).to include('filter_name')
    end
  end

  describe 'filter_name: names that contain the text (the filtered listing, no fuzzy search)' do
    let!(:chinese) { create(:organisation, name_en: 'Lantau Youth Hub', name_zh_tw: '大嶼山青年中心', organisation_type: ngo, country: hong_kong) }
    let!(:percent) { create(:organisation, name_en: '100% Kids Fund', name_zh_tw: nil, organisation_type: ngo, country: hong_kong) }
    let!(:underscore) { create(:organisation, name_en: 'Under_Score Club', name_zh_tw: nil, organisation_type: ngo, country: hong_kong) }
    let!(:backslash) { create(:organisation, name_en: 'Back\\Slash Society', name_zh_tw: nil, organisation_type: ngo, country: hong_kong) }

    it 'matches anywhere in the English name, ignoring case and the spaces around it; by name, then id' do
      search(filter_name: 'ARBOUR')
      expect(ids).to eq([plain, schooled, abroad, stateless, untyped, busy].map(&:id)) # Alpha Beta Delta Epsilon Gamma Zeta
      expect(body['meta']).to include('total_count' => 6, 'search' => nil)
      search(filter_name: '  rbour gam ')
      expect(ids).to eq([untyped.id])
      search(filter_name: 'ebra Harbour Z') # the middle of a name
      expect(ids).to eq([busy.id])
    end

    it 'a short prefix finds a long name (what the fuzzy search cannot)' do
      long = create(:organisation, name_en: "Hong Kong Young Women's Christian Association Jockey Club Shatin Integrated Social Service Centre", organisation_type: ngo, country: hong_kong)
      create(:order, organisation: long)
      search(searchText: 'Hon')
      expect(ids).not_to include(long.id) # legacy fuzzy search, whole-name similarity: unchanged
      search(filter_name: 'Hon', filter_has_orders: 'true')
      expect(ids).to eq([long.id])
    end

    it 'matches the Chinese name' do
      search(filter_name: '青年')
      expect(ids).to eq([chinese.id])
      search(filter_name: '大嶼山青年中心')
      expect(ids).to eq([chinese.id])
    end

    it '%, _ and \\ are matched as themselves, never as wildcards' do
      search(filter_name: '%')
      expect(ids).to eq([percent.id])
      search(filter_name: '_')
      expect(ids).to eq([underscore.id])
      search(filter_name: '\\')
      expect(ids).to eq([backslash.id])
      search(filter_name: 'Zebra_Harbour')
      expect(ids).to eq([]) # as a wildcard, _ would match the space in all six "Zebra Harbour …"
      search(filter_name: 'Zebra%Zeta')
      expect(ids).to eq([])
      search(filter_name: "'; DROP TABLE organisations; --")
      expect(ids).to eq([])
      expect(Organisation.count).to be > 0
    end

    it 'combines with every other filter' do
      search(filter_name: 'zebra', filter_has_orders: 'true')
      expect(ids).to eq([busy.id])
      search(filter_name: 'zebra', filter_has_members: 'true', filter_has_registration: 'true')
      expect(ids).to eq([plain.id, busy.id])
      search(filter_name: 'zebra', filter_organisation_type_id: 'none')
      expect(ids).to eq([untyped.id])
      search(filter_name: 'zebra', filter_country_id: other_country.id)
      expect(ids).to eq([abroad.id])
      search(filter_name: 'zebra', filter_organisation_type_id: ngo.id, filter_country_id: hong_kong.id, filter_has_orders: 'true', filter_has_members: 'true', filter_has_registration: 'true')
      expect(ids).to eq([busy.id])
      search(filter_name: 'quokka', filter_has_orders: 'true')
      expect(ids).to eq([elsewhere.id])
    end

    it 'equal names are ordered by id; pages are capped at 100' do
      105.times { |i| create(:organisation, name_en: "Ibis Court #{format('%03d', i)}", registration: nil) }
      search(filter_name: 'ibis court', per_page: 1000)
      expect(ids.size).to eq(100)
      expect(body['meta']).to include('total_pages' => 2, 'total_count' => 105)
      expect(body['organisations'].map { |o| o['name_en'] }).to eq((0...100).map { |i| "Ibis Court #{format('%03d', i)}" })
      search(filter_name: 'ibis court', per_page: 1000, page: 2)
      expect(ids.size).to eq(5)
    end

    it 'never reaches ids[] or the names endpoint' do
      search(ids: [busy.id, plain.id], filter_name: 'Alpha')
      expect(ids).to match_array([busy.id, plain.id])
      get '/api/v1/organisations/names', params: { searchText: 'Zebra Harbour', filter_name: 'Alpha' }, headers: headers
      expect(JSON.parse(response.body)['organisations'].size).to eq(6)
    end
  end

  describe 'with no term and at least one filter: browse' do
    it 'lists every organisation that passes, by English name, paged, with total_count' do
      search(filter_has_members: 'true', per_page: 2, page: 1)
      expect(ids).to eq([elsewhere.id, plain.id]) # Quokka Lane…, Zebra Harbour Alpha
      expect(body['meta']).to include('total_pages' => 2, 'total_count' => 3)
      search(filter_has_members: 'true', per_page: 2, page: 2)
      expect(ids).to eq([busy.id])
    end

    it 'an empty searchText browses too; the rows carry the same attributes and sideloads as a search' do
      search(searchText: '', filter_has_orders: 'true')
      expect(ids).to eq([elsewhere.id, busy.id])
      row = body['organisations'].find { |o| o['id'] == busy.id }
      expect(row['orders_count']).to eq(3)
      expect(row['organisations_user_ids'].size).to eq(2)
      expect(body['organisations_users'].map { |u| u['organisation_id'] }.uniq).to match_array([elsewhere.id, busy.id])
    end

    it 'none, and false, work without a term' do
      search(filter_organisation_type_id: 'none')
      expect(ids).to eq([untyped.id])
      search(filter_has_registration: 'false', filter_country_id: hong_kong.id)
      expect(ids).to eq([schooled.id, untyped.id])
    end

    it 'pages are at most 100 rows (browse reaches the whole table); a search keeps any per_page, as before' do
      102.times { |i| create(:organisation, name_en: "Quagga Field #{i}", registration: nil) }
      search(filter_has_registration: 'false', per_page: 1000)
      expect(ids.size).to eq(100)
      expect(body['meta']).to include('total_pages' => 2, 'total_count' => 105)
      search(filter_has_registration: 'false', per_page: 1000, page: 2)
      expect(ids.size).to eq(5)
      search(filter_has_registration: 'false', per_page: 'abc')
      expect(ids.size).to eq(DEFAULT_SEARCH_COUNT)
      search(searchText: 'Quagga Field', per_page: 1000)
      expect(ids.size).to be >= 102 # a search's page is not capped
    end

    it 'a filter nothing passes is an empty page, not an error' do
      search(filter_organisation_type_id: 999_999)
      expect(ids).to eq([])
      expect(body['meta']).to include('total_pages' => 0, 'total_count' => 0)
    end
  end

  describe 'bad values are refused, never ignored (ignoring one would list everything)' do
    [
      { filter_has_orders: 'yes' }, { filter_has_members: '1' }, { filter_has_registration: '' },
      { filter_organisation_type_id: 'abc' }, { filter_country_id: '' }, { filter_country_id: '12x' },
      { filter_name: '' }, { filter_name: "  \t " }
    ].each do |bad|
      it "422 for #{bad.inspect}" do
        get '/api/v1/organisations', params: bad, headers: headers
        expect(response.status).to eq(422)
      end
    end
  end

  it 'a role without can_check_organisations is still refused' do
    charity = create(:user, :charity)
    jwt = Rails.application.secrets.jwt
    payload = { iss: jwt[:issuer], exp: 14.days.from_now.to_i, user_id: charity.id, iat: Time.current.to_i }
    get '/api/v1/organisations', params: { filter_has_orders: 'true' }, headers: headers.merge('Authorization' => "Bearer #{JWT.encode(payload, jwt[:secret_key], jwt[:hmac_sha_algo])}")
    expect(response.status).to eq(403)
  end
end
