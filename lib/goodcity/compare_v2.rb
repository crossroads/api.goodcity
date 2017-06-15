require 'benchmark'
require 'ostruct'
require 'squeel'
require 'classes/diff'

module Goodcity
  class CompareV2

    attr :diffs, :object_name

    OBJECT_NAMES = %w(activities boxes codes countries locations pallets
      contacts local_orders organisations items orders).freeze

    # x=Goodcity::CompareV2.new("activities")
    # x.compare
    def initialize(object_name)
      @diffs = []
      @seen_stockit_ids = []
      @object_name = object_name
      (raise ValueError, "#{object_name} is not handled") unless OBJECT_NAMES.include?(object_name)
    end

    def compare
      if use_pagination?
        paginated_json do |batch|
          @stockit_objects = batch # cheating with memoization
          compare_stockit_objects
        end
      else
        compare_stockit_objects
      end
      compare_goodcity_objects
    end

    def summary
      number_of_diffs = @diffs.reject(&:identical?).size
      percent = (number_of_diffs.to_f / @diffs.size * 100).round(2)
      "#{number_of_diffs} differences / #{@diffs.size} objects (#{percent}%)"
    end

    def in_words
      sorted_diffs.reject(&:identical?).map(&:in_words)
    end

    def sorted_diffs
      @diffs.sort_by(&:id)
    end

    # def compare_contacts
    #   stockit_contacts = stockit_json(Stockit::ContactSync, "contacts")
    #   compare_objects(StockitContact, stockit_contacts, [:first_name, :last_name, :phone_number, :mobile_phone_number])
    # end

    # def compare_local_orders
    #   stockit_local_orders = stockit_json(Stockit::LocalOrderSync, "local_orders")
    #   compare_objects(StockitLocalOrder, stockit_local_orders, [:purpose_of_goods, :hkid_number, :reference_number, :client_name])
    # end

    # def compare_organisations
    #   stockit_organisations = stockit_json(Stockit::OrganisationSync, "organisations")
    #   compare_objects(StockitOrganisation, stockit_organisations, [:name])
    # end

    def compare_orders
      # TODO: pagination
      # Not in Stockit JSON
      # :processed_by_id, :purpose_description, :stockit_organisation_id
      # TODO: to be mapped
      # Stockit : GoodCity
      # contact_id : stockit_contact_id
      # activity_id : stockit_activity_id
      # organisation_id : stockit_organisation -> stockit_id
      # detail_id : detail.stockit_id
      stockit_designations = stockit_json(Stockit::DesignationSync, "designations")
      compare_objects(Order, stockit_designations, [:code, :country_id, :description, :detail_type, :status])
    end

    private

    # Iterate over Stockit objects and look for differences and what's missing from GoodCity
    def compare_stockit_objects
      bm('compare_stockit_objects') do
        stockit_objects.each_value do |stockit_obj|
          stockit_id = stockit_obj["id"]
          @seen_stockit_ids << stockit_id
          goodcity_obj = goodcity_objects_by_stockit_id[stockit_id] || OpenStruct.new(id: nil, stockit_id: stockit_id)
          goodcity_struct = OpenStruct.new
          stockit_struct = OpenStruct.new.tap{|x| x.id = stockit_id}
          attributes_to_compare.each do |a|
            goodcity_struct[a] = goodcity_obj[a]
            stockit_struct[a] = stockit_obj[a]
          end
          @diffs << Diff.new(object_name, goodcity_struct, stockit_struct, attributes_to_compare).compare
        end
      end
    end

    # must be called AFTER compare_stockit_objects
    # Having run compare_stockit_objects, now iterate over unseen objects in GoodCity and find what's missing in Stockit
    # Handle 2 cases where item exists in GoodCity but not in Stockit
    def compare_goodcity_objects
      # 1. GoodCity objs where stockit_id is nil
      goodcity_klass.where(stockit_id: nil).pluck(:id).each do |id|
        goodcity_struct = OpenStruct.new(id: id, stockit_id: nil)
        stockit_struct = OpenStruct.new(id: nil)
        @diff << Diff.new(object_name, goodcity_struct, stockit_struct, attributes_to_compare).compare
      end
      # 2. GoodCity objs where stockit_id was not found in Stockit
      missing_stockit_ids = goodcity_klass.pluck("DISTINCT stockit_id") - @seen_stockit_ids
      missing_stockit_ids.in_groups_of(100) do |ids|
      begin
        goodcity_klass.where(stockit_id: ids) do |obj|
          goodcity_struct = OpenStruct.new(id: obj.id, stockit_id: obj.stockit_id)
          stockit_struct = OpenStruct.new(id: nil)
          @diffs << Diff.new(object_name, goodcity_struct, stockit_struct, attributes_to_compare).compare
        end
      rescue
        byebug
        puts
      end
      end
    end

    def stockit_objects
      @stockit_objects ||= begin
        bm('stockit_objects') do
          json_data = stockit_sync_klass.index
          data = JSON.parse(json_data[object_name]) || []
          data.inject({}){|h,k| h[k['id']]=k; h}
        end
      end
    end

    def paginated_json(per_page=1000, &block)
      offset = 0
      loop do
        json = stockit_sync_klass.index(nil, offset, per_page)
        json_objects = JSON.parse(json[object_name])
        if json_objects.present?
          yield json_objects.inject({}){|h,k| h[k['id']]=k; h}
        else
          break
        end
        offset = offset + per_page
      end
    end

    def goodcity_objects_by_stockit_id
      @goodcity_objects_by_stockit_id ||= begin
        bm('Preloading goodcity_objects_by_stockit_id') do
          @goodcity_objects_by_stockit_id = {}
          sql_for_goodcity_model.find_each do |obj|
            ostruct = OpenStruct.new
            attributes_to_compare.each{ |a| ostruct[a] = obj[a] }
            @goodcity_objects_by_stockit_id[obj.stockit_id] = ostruct
          end
          @goodcity_objects_by_stockit_id
        end
      end
      @goodcity_objects_by_stockit_id
    end

    # goodcity_klass.eager_load(joins).select(select_columns).find_each do |obj|
    # Using squeel gem for outer joins
    # WORKING PackageType.joins{location.outer}.select("locations.stockit_id AS location_id").where(id: 1)
    # WORKING Package.joins{box.outer}.joins{package_type.outer}.to_sql
    # WORKING Package.joins{js.map{|j| __send__(j).outer}}.to_sql
    def sql_for_goodcity_model
      relations = join_relations # need to bring inside this function scope for squeel
      cols = select_columns
      cols << ", #{table_name}.state" if %w(items).include?(object_name)
      goodcity_klass.joins{relations.map{|j| __send__(j).outer}}.select(cols)
    end

    def table_name
      @table_name ||= goodcity_klass.table_name
    end

    def select_columns
      attribute_map.map do |stockit_attr, goodcity_attr|
        (stockit_attr == goodcity_attr) ? stockit_attr : "#{goodcity_attr} AS #{stockit_attr}"
      end.join(", ")
    end

    def join_relations
      @join_relations ||= {
        "boxes" => [:pallet],
        "codes" => [:location],
        "items" => [:box, :package_type, :pallet, :locations, :order]
      }
      @join_relations[object_name] || []
    end

    def attributes_to_compare
      attribute_map.keys
    end

    # Maps field name in GoodCity table to field name in stockit JSON to ease comparision
    # Piped directly into select query
    def attribute_map
      @attribute_map ||= {
        "activities" => { "name" => "stockit_activities.name" },
        "boxes" => {
          "description" => "boxes.description",
          "box_number" => "boxes.box_number",
          "comments" => "boxes.comments",
          "pallet_id" => "pallets.stockit_id"},
        "codes" => {
          "code" => "package_types.code",
          "description_en" => "package_types.name_en",
          "description_zht" => "package_types.name_zh_tw",
          "location_id" => "locations.stockit_id" },
        "countries" => {
           "name_en" => "countries.name_en",
           "name_zh" => "countries.name_zh_tw" },
        "locations" => {
            "area" => "locations.area",
            "building" => "locations.building" },
        "items" =>  {
          # Missing mappings
          # Stockit : GoodCity
          # : deleted_at
          # : designation_name
          # : stockit_sent_by_id
          # : stockit_moved_on
          # : stockit_moved_by_id
          # : stockit_designated_on
          # : stockit_designated_by_id
          "box_id" => "boxes.stockit_id",
          "case_number" => "packages.case_number",
          "code_id" => "package_types.stockit_id",
          #"condition" => "CASE WHEN donor_conditions.name_en = "New" then "N" WHEN donor_conditions.name_en = "Lightly Used" then "M" WHEN donor_conditions.name_en = "Heavily Used" then "U" WHEN donor_conditions.name_en = "Broken" then "B" END",
          "description" => "packages.notes",
          "grade" => "packages.grade",
          "height" => "packages.height",
          "length" => "packages.length",
          "width" => "packages.width",
          "sent_on" => "packages.stockit_sent_on",
          "quantity" => "packages.received_quantity",
          "pallet_id" => "pallets.stockit_id",
          "location_id" => "locations.stockit_id",
          "inventory_number" => "packages.inventory_number",
          "designation_code" => "orders.code",
          "designation_id" => "orders.stockit_id"},
        "pallets" => {
          "pallet_number" => "pallets.pallet_number",
          "description" => "pallets.description",
          "comments" => "pallets.comments" },
      }
      (@attribute_map[object_name] || {}).merge("id" => "#{table_name}.id", "stockit_id" => "#{table_name}.stockit_id")
    end

    # Applied pattern "Stockit::#{object_name}Sync" unless overridden in h below
    def stockit_sync_klass
      @stockit_sync_klass ||= begin
        h = {}
        h[object_name] || "Stockit::#{object_name.singularize.classify}Sync".constantize
      end  
    end

    # Turns object_name into singular model unless overridden below
    def goodcity_klass
      @goodcity_klass ||= begin
        h = {
          "activities" => StockitActivity,
          "items" => Package,
          "codes" => PackageType
        }
        h[object_name] || object_name.singularize.classify.constantize
      end
    end

    # Stockit queries that should be paginated
    def use_pagination?
      %w(items).include?(object_name)
    end

    def bm(label = '', &block)
      result = nil
      time = Benchmark.measure(label) do
        result = yield
      end
      (puts time.format("%n %r")) if %w(development staging).include?(Rails.env)
      result
    end

  end
end
