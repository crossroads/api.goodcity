# frozen_string_literal: true

require 'rails_helper'

# GET /api/v1/organisations with the optional filters (organisation_type_id, country_id, has_orders, has_members,
# has_registration) and meta.total_count. Request specs: routing, apipie's param check, CanCan and the controller run
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
  let!(:schooled) { org('Zebra Harbour Beta', type: school, registration: '   ') }
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

  # The pre-change index action, verbatim (find_record_and_render_json before this branch), serialized as the signed-in
  # supervisor (UserSerializer shows staff the users' addresses and mobiles).
  def legacy_body(params)
    User.current_user = supervisor
    records = if params[:ids].present?
                Organisation.where(id: params[:ids]).page(params[:page]).per(params[:per_page] || DEFAULT_SEARCH_COUNT)
              else
                Organisation.with_order.search(params[:searchText]).page(params[:page]).per(params[:per_page] || DEFAULT_SEARCH_COUNT)
              end
    data = ActiveModel::ArraySerializer.new(records, each_serializer: Api::V1::OrganisationSerializer, root: 'organisations', include_orders_count: true).as_json
    JSON.parse({ "meta": { total_pages: records.total_pages, "search": params[:searchText] } }.merge(data).to_json)
  end

  describe 'without filters: unchanged (plus meta.total_count)' do
    it 'a name search answers the same body, with total_count beside total_pages' do
      search(searchText: 'Zebra Harbour', per_page: 4, page: 2)
      expected = legacy_body(searchText: 'Zebra Harbour', per_page: 4, page: 2)
      expect(body['meta']).to eq(expected['meta'].merge('total_count' => 6))
      expect(body.except('meta')).to eq(expected.except('meta'))
      expect(body['meta'].keys).to eq(%w[total_pages total_count search])
    end

    it 'an empty or missing term still lists nothing' do
      search(searchText: '')
      expect(body['organisations']).to eq([])
      expect(body['meta']).to include('total_pages' => 0, 'total_count' => 0)
      search({})
      expect(body['organisations']).to eq([])
    end

    it 'ids[] answers the same rows, and ignores any filter' do
      search(ids: [busy.id, plain.id])
      expected = legacy_body(ids: [busy.id, plain.id])
      expect(body.except('meta')).to eq(expected.except('meta'))
      search(ids: [busy.id, plain.id], has_orders: 'false')
      expect(ids).to match_array([busy.id, plain.id])
    end

    it '/organisations/names ignores the filters (it is open to every role)' do
      get '/api/v1/organisations/names', params: { searchText: 'Zebra Harbour', has_orders: 'true' }, headers: headers
      expect(JSON.parse(response.body)['organisations'].size).to eq(6)
    end
  end

  describe 'with a term: the filters narrow its matches' do
    it 'type, or none' do
      search(searchText: 'Zebra Harbour', organisation_type_id: school.id)
      expect(ids).to eq([schooled.id])
      search(searchText: 'Zebra Harbour', organisation_type_id: 'none')
      expect(ids).to eq([untyped.id])
      expect(body['meta']['total_count']).to eq(1)
    end

    it 'country, or none' do
      search(searchText: 'Zebra Harbour', country_id: other_country.id)
      expect(ids).to eq([abroad.id])
      search(searchText: 'Zebra Harbour', country_id: 'none')
      expect(ids).to eq([stateless.id])
    end

    it 'orders: any order at all, or none' do
      search(searchText: 'Zebra Harbour', has_orders: 'true')
      expect(ids).to eq([busy.id])
      expect(body['organisations'][0]['orders_count']).to eq(3)
      search(searchText: 'Zebra Harbour', has_orders: 'false')
      expect(ids).to match_array([plain, schooled, untyped, abroad, stateless].map(&:id))
    end

    it 'members are pending or approved; expired and denied are not' do
      search(searchText: 'Zebra Harbour', has_members: 'true')
      expect(ids).to match_array([busy.id, plain.id])
      search(searchText: 'Zebra Harbour', has_members: 'false')
      expect(ids).to match_array([schooled, untyped, abroad, stateless].map(&:id))
    end

    it 'registration: filled in, or empty (blank counts as empty)' do
      search(searchText: 'Zebra Harbour', has_registration: 'true')
      expect(ids).to match_array([plain, abroad, busy].map(&:id))
      search(searchText: 'Zebra Harbour', has_registration: 'false')
      expect(ids).to match_array([schooled, untyped, stateless].map(&:id))
    end

    it 'combined: every filter must pass; a row is never repeated however many orders or members it has' do
      search(searchText: 'Zebra Harbour', organisation_type_id: ngo.id, country_id: hong_kong.id, has_orders: 'true', has_members: 'true', has_registration: 'true')
      expect(ids).to eq([busy.id])
      search(searchText: 'Zebra Harbour', has_members: 'true', per_page: 25)
      expect(ids.uniq.size).to eq(ids.size)
      expect(body['meta']['total_count']).to eq(2)
    end

    it 'keeps the best-match order' do
      search(searchText: 'Zebra Harbour Zeta', has_registration: 'true')
      expect(ids).to match_array([busy, plain, abroad].map(&:id))
      expect(ids.first).to eq(busy.id)
    end
  end

  describe 'with no term and at least one filter: browse' do
    it 'lists every organisation that passes, by English name, paged, with total_count' do
      search(has_members: 'true', per_page: 2, page: 1)
      expect(ids).to eq([elsewhere.id, plain.id]) # Quokka Lane…, Zebra Harbour Alpha
      expect(body['meta']).to include('total_pages' => 2, 'total_count' => 3)
      search(has_members: 'true', per_page: 2, page: 2)
      expect(ids).to eq([busy.id])
    end

    it 'an empty searchText browses too; the rows carry the same attributes and sideloads as a search' do
      search(searchText: '', has_orders: 'true')
      expect(ids).to eq([elsewhere.id, busy.id])
      row = body['organisations'].find { |o| o['id'] == busy.id }
      expect(row['orders_count']).to eq(3)
      expect(row['organisations_user_ids'].size).to eq(2)
      expect(body['organisations_users'].map { |u| u['organisation_id'] }.uniq).to match_array([elsewhere.id, busy.id])
    end

    it 'none, and false, work without a term' do
      search(organisation_type_id: 'none')
      expect(ids).to eq([untyped.id])
      search(has_registration: 'false', country_id: hong_kong.id)
      expect(ids).to eq([schooled.id, untyped.id])
    end

    it 'a filter nothing passes is an empty page, not an error' do
      search(organisation_type_id: 999_999)
      expect(ids).to eq([])
      expect(body['meta']).to include('total_pages' => 0, 'total_count' => 0)
    end
  end

  describe 'bad values are refused, never ignored (ignoring one would list everything)' do
    [
      { has_orders: 'yes' }, { has_members: '1' }, { has_registration: '' },
      { organisation_type_id: 'abc' }, { country_id: '' }, { country_id: '12x' }
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
    get '/api/v1/organisations', params: { has_orders: 'true' }, headers: headers.merge('Authorization' => "Bearer #{JWT.encode(payload, jwt[:secret_key], jwt[:hmac_sha_algo])}")
    expect(response.status).to eq(403)
  end
end
