# frozen_string_literal: true

require 'rails_helper'

# GET /api/v1/users/browse — the paged list of accounts, on a route of its own. Request specs: routing, apipie, CanCan
# and the controller run as they do for a real client.
#
# The legacy examples build the expected body with the pre-change action, verbatim (index and
# search_user_and_render_json, which this branch doesn't touch), so every request a current client sends is answered
# exactly as before.
RSpec.describe 'GET /api/v1/users/browse', type: :request do
  let(:supervisor) do
    create(:user, :with_token, :with_can_read_or_modify_user_permission, :with_can_manage_user_roles_permission,
           role_name: 'Supervisor', first_name: 'Sam', last_name: 'Supervisor')
  end

  def headers_for(user)
    jwt = Rails.application.secrets.jwt
    payload = { iss: jwt[:issuer], exp: 14.days.from_now.to_i, user_id: user.id, iat: Time.current.to_i }
    {
      'Authorization' => "Bearer #{JWT.encode(payload, jwt[:secret_key], jwt[:hmac_sha_algo])}",
      'X-GOODCITY-APP-NAME' => 'stock.goodcity'
    }
  end

  let(:headers) { headers_for(supervisor) }

  # methods, not lets: an example makes several requests, and each must be read afresh
  def body
    JSON.parse(response.body)
  end

  def ids
    body['users'].map { |u| u['id'] }
  end

  let(:reviewer_role) { Role.find_by(name: 'Reviewer') || create(:role, name: 'Reviewer', level: 5) }
  let(:order_role) { Role.find_by(name: 'Order fulfilment') || create(:role, name: 'Order fulfilment', level: 5) }

  # Thirteen people whose names sort in a known order (last name, then first name, then id; a missing last name last).
  let!(:people) do
    names = [%w[Ann Zebra], %w[Bea Abbot], %w[Cat Abbot], %w[Dan Moss], %w[Eve moss], %w[Fay Nash], %w[Gus Nash],
             %w[Hal Owen], %w[Ida Owen], %w[Jo Price], %w[Kim Quinn], ['Lou', nil], %w[Max Abbot]]
    names.map { |first, last| create(:user, first_name: first, last_name: last) }
  end
  let!(:disabled) { create(:user, first_name: 'Ned', last_name: 'Disabled', disabled: true) }

  before do
    supervisor
    create(:user_role, user: people[3], role: reviewer_role, expires_at: nil)
    create(:user_role, user: people[3], role: order_role, expires_at: nil)
    create(:user_role, user: people[5], role: order_role, expires_at: 3.days.from_now)
    create(:user_role, user: people[6], role: order_role, expires_at: 3.days.ago) # expired: not in roles=
  end

  # Everyone the supervisor may list, as the browse list orders them.
  def expected_order
    User.exclude_system_users.to_a.sort_by { |u| [u.last_name.nil? ? 1 : 0, u.last_name.to_s.downcase, u.first_name.to_s.downcase, u.id] }.map(&:id)
  end

  def browse(params, as: headers)
    get '/api/v1/users/browse', params: params, headers: as
  end

  describe 'GET /users/browse: paged, ordered, counted, slim' do
    it 'pages 50 at a time by default, by last name, first name and id, with meta' do
      browse({})
      expect(response.status).to eq(200), response.body
      expect(ids).to eq(expected_order.first(50))
      expect(body['meta']).to eq('page' => 1, 'per_page' => 50, 'total_count' => expected_order.size, 'total_pages' => 1)
    end

    it 'honours page and per_page; pages never overlap and together hold everyone once' do
      seen = []
      (1..4).each do |page|
        browse(page: page, per_page: 5)
        expect(body['meta']).to include('page' => page, 'per_page' => 5, 'total_count' => expected_order.size,
                                        'total_pages' => (expected_order.size / 5.0).ceil)
        seen.concat(ids)
      end
      expect(seen).to eq(expected_order)
    end

    it 'caps per_page at 100, and reads a missing, zero or junk per_page as 50' do
      create_list(:user, 101)
      browse(per_page: 500)
      expect(body['users'].size).to eq(100)
      expect(body['meta']['per_page']).to eq(100)
      %w[0 -3 abc].each do |junk|
        browse(per_page: junk)
        expect(body['users'].size).to eq(50)
      end
    end

    it 'holds exactly the people the plain list holds (disabled people in, system users out)' do
      browse(per_page: 100)
      expect(ids).to include(disabled.id)
      paged = ids
      get '/api/v1/users', headers: headers
      expect(paged).to match_array(body['users'].map { |u| u['id'] })
    end

    it 'rows are slim: no mobile, email, address or sign-in times; grants with their roles and end dates, memberships' do
      org = create(:organisation, name_en: 'Zebra Charity')
      create(:organisations_user, user: people[3], organisation: org, status: 'pending')
      browse(per_page: 100)
      dan = body['users'].find { |u| u['id'] == people[3].id }
      expect(dan.keys).to match_array(%w[id first_name last_name title disabled created_at user_role_ids organisations_user_ids])
      expect(body.to_json).not_to include(people[3].mobile)
      expect(body.to_json).not_to include(people[3].email)
      expect(dan['user_role_ids'].size).to eq(2)
      grants = body['user_roles'].select { |g| g['user_id'] == people[3].id }
      expect(grants.map { |g| body['roles'].find { |r| r['id'] == g['role_id'] }['name'] }).to match_array(['Reviewer', 'Order fulfilment'])
      fay = body['user_roles'].find { |g| g['user_id'] == people[5].id }
      expect(Time.zone.parse(fay['expires_at'])).to be_within(1.second).of(people[5].user_roles.first.expires_at)
      membership = body['organisations_users'].find { |m| m['user_id'] == people[3].id }
      expect(membership['status']).to eq('pending')
      expect(body['organisations']).to include('id' => org.id, 'name_en' => 'Zebra Charity', 'name_zh_tw' => org.name_zh_tw)
    end

    it 'a fixed handful of queries a page, whatever its size (no per-row queries)' do
      create_list(:user, 40)
      count = lambda do |per_page|
        n = 0
        counter = ->(*, payload) { n += 1 unless payload[:name] == 'SCHEMA' || payload[:sql] =~ /\A\s*(BEGIN|COMMIT|SAVEPOINT|RELEASE)/ }
        ActiveSupport::Notifications.subscribed(counter, 'sql.active_record') { browse(per_page: per_page) }
        n
      end
      small = count.call(5)
      large = count.call(50)
      # (a preload whose rows are empty skips its query, so a page with memberships may run one more)
      expect(large).to be <= small + 2
      expect(large).to be <= 15
    end

    it 'roles= narrows it to people holding one of those roles now (each person once)' do
      browse(roles: ['Reviewer', 'Order fulfilment'])
      expect(ids).to eq([people[3].id, people[5].id])
      expect(body['meta']['total_count']).to eq(2)
    end

    it 'a role that may not list people is refused, as for the plain list' do
      donor = create(:user)
      browse({}, as: headers_for(donor))
      expect(response.status).to eq(403)
      get '/api/v1/users', headers: headers_for(donor)
      expect(response.status).to eq(403)
    end
  end

  # --- every request today's clients send, answered as before (byte for byte: compared parsed, keys and array order) ---

  # The pre-change index, verbatim, for the signed-in supervisor (CanCan lets a supervisor list every user).
  def legacy_json(params, as: supervisor)
    User.current_user = as
    users = User.accessible_by(Api::V1::Ability.new(as), :index).exclude_system_users
    if params['searchText'].present?
      records = users.limit(25).filter_users(params)
      data = ActiveModel::ArraySerializer.new(records, each_serializer: Api::V1::UserDetailsSerializer,
                                                       include_user_roles: true, root: 'users').as_json
      return { 'meta': { 'search': params['searchText'] } }.merge(data).to_json
    end

    users = users.with_roles(params['roles']) if params['roles'].present?
    if params['ids'].present?
      ids = params['ids'].is_a?(String) ? params['ids'].split(',') : params['ids'].map(&:to_i)
      users = users.where(id: ids)
    end
    ActiveModel::ArraySerializer.new(users.with_eager_loading, each_serializer: Api::V1::UserSerializer, root: 'users').to_json
  end

  describe 'legacy request shapes: identical responses' do
    def expect_legacy(params)
      get '/api/v1/users', params: params, headers: headers
      expect(response.status).to eq(200), response.body
      wire = params.transform_keys(&:to_s).transform_values { |v| v.is_a?(Array) ? v.map(&:to_s) : v.to_s }
      expect(JSON.parse(response.body)).to eq(JSON.parse(legacy_json(wire)))
      expect((JSON.parse(response.body)['meta'] || {}).keys).not_to include('total_count', 'total_pages')
    end

    it 'no params: every user, unpaged (UserSerializer)' do
      expect_legacy({})
      expect(JSON.parse(response.body)['users'].size).to eq(User.exclude_system_users.count)
    end

    it 'page + per_page with a blank searchText (stock Manage Users / admin donor search with the box emptied): still the unpaged list' do
      expect_legacy(page: 1, per_page: 25, searchText: '', stockRequest: true)
      expect(JSON.parse(response.body)['users'].size).to eq(User.exclude_system_users.count)
      expect_legacy(page: 2, per_page: 25)
      expect(JSON.parse(response.body)['users'].size).to eq(User.exclude_system_users.count)
    end

    it 'stock Manage Users and User Details › Merge: searchText + page + per_page 25 + stockRequest' do
      expect_legacy(page: 1, per_page: 25, searchText: 'Abbot', stockRequest: true)
      expect(JSON.parse(response.body)['users'].size).to eq(3)
      expect_legacy(page: 2, per_page: 25, searchText: 'Abbot', stockRequest: true) # page still ignored, as before
    end

    it 'admin offer › search users: searchText + per_page 25 + page' do
      expect_legacy(searchText: 'Nash', per_page: 25, page: 1)
    end

    it 'roles (a name, or roles[]): the people holding it now' do
      expect_legacy(roles: 'Order fulfilment')
      expect(JSON.parse(response.body)['users'].map { |u| u['id'] }).to match_array([people[3].id, people[5].id])
      expect_legacy(roles: ['Reviewer', 'Order fulfilment'])
    end

    it 'ids[] (Ember Data coalesced findMany, the stock app’s user adapter)' do
      expect_legacy(ids: [people[0].id, people[1].id])
    end

    it 'a blank searchText with page and per_page (an emptied search box): still the unpaged list' do
      expect_legacy(searchText: '', page: 1, per_page: 25)
      expect(JSON.parse(response.body)['users'].size).to eq(User.exclude_system_users.count)
    end

    # Steve's rules (30 Oct): each app's own kind of user, with every permission of that role and that app's header.
    def role_user(role_name)
      permissions = YAML.load_file(Rails.root.join('db', 'permissions_roles.yml'))[role_name].flatten
      role = create("#{role_name.parameterize.underscore}_role", :with_permissions, permissions: permissions)
      create(:user, first_name: 'Zed', last_name: "Replay #{role_name}").tap { |u| create(:user_role, user: u, role: role) }
    end

    [
      ['stock.goodcity Manage Users, as a Stock administrator', 'Stock administrator', 'stock.goodcity',
       { page: 1, per_page: 25, searchText: 'Abbot', stockRequest: true }],
      ['stock.goodcity Manage Users with the box emptied, as a Stock administrator', 'Stock administrator', 'stock.goodcity',
       { page: 1, per_page: 25, searchText: '', stockRequest: true }],
      ['admin.goodcity offer › search users, as a Reviewer', 'Reviewer', 'admin.goodcity',
       { searchText: 'Nash', per_page: 25, page: 1 }]
    ].each do |label, role_name, app, params|
      it "#{label}: answered as before" do
        staff = role_user(role_name)
        User.current_user = nil
        get '/api/v1/users', params: params, headers: headers_for(staff).merge('X-GOODCITY-APP-NAME' => app)
        expect(response.status).to eq(200), response.body
        wire = params.transform_keys(&:to_s).transform_values(&:to_s)
        expect(JSON.parse(response.body)).to eq(JSON.parse(legacy_json(wire, as: staff)))
      ensure
        User.current_user = nil
      end
    end

    it 'show is untouched' do
      get "/api/v1/users/#{people[3].id}", headers: headers
      User.current_user = supervisor
      expect(JSON.parse(response.body)).to eq(JSON.parse(Api::V1::UserDetailsSerializer.new(people[3].reload, root: 'user').to_json))
    end
  end
end
