# frozen_string_literal: true

require 'rubyXL'

# StockitDataMigrator - helper method class
class StockitDataMigrator
  attr_accessor :workbook, :bar

  def initialize(filename)
    @filename = filename
    @workbook = RubyXL::Parser.parse(Rails.root.join('tmp', filename))
    @bar = RakeProgressbar.new(worksheet.sheet_data.rows.size)
  end

  def logger(&block)
    puts "*****Starting #{@filename}*****"
    ActiveRecord::Base.logger.silence do
      block.call
    end
    puts "*****Finished #{@filename}*****"
  end

  def worksheet
    @worksheet ||= workbook.worksheets[0]
  end

  def format_time(time_str, format_str = '%d/%m/%Y %H:%M:%s')
    DateTime.strptime(time_str, format_str).in_time_zone
  end
end

# Correct "sent_on" date for "L" orders
class ImportSentDates < StockitDataMigrator
  def import
    logger do
      worksheet.collect do |row|
        next if row[0].value == 'designation_id'

        designation_code = row[1].value.strip
        closed_date = row[2].value

        update_fields(designation_code, closed_date)
        bar.inc
      end
    ensure
      bar.finished
    end
  end

  def update_fields(designation_code, closed_date)
    order = Order.find_by(code: designation_code)
    order&.update(closed_date: closed_date)
  end
end

# Map old organisations to new/official organisations
class StockitOrganisationToOrganisationMapper < StockitDataMigrator
  def import
    logger do
      worksheet.collect do |row|
        next unless row&.index_in_collection && row.index_in_collection > 1

        organisation = StockitOrganisation.find_by(name: row[0].value)
        gc_organisation_id = row[1].value

        records = Order.where(stockit_organisation: organisation)
        update_fields(records, gc_organisation_id)
        bar.inc
      end
    ensure
      bar.finished
    end
  end

  def update_fields(records, organisation_id)
    Organisation.find_by(id: organisation_id) && records.update_all(organisation_id: organisation_id)
  end
end

# Import missing shipments for historical reporting
class ImportMissingShipments < StockitDataMigrator
  def import
    logger do
      worksheet.collect do |row|
        next if row.index_in_collection.zero?

        code = row[1]&.value
        next unless code

        order = Order.find_or_initialize_by(code: code)
        attributes = { created_at: row[6]&.value,
                       updated_at: row[7]&.value || row[6]&.value,
                       closed_at: row[21]&.value,
                       detail_type: row[2]&.value,
                       country_id: row[10]&.value,
                       state: row[14]&.value,
                       staff_note: row[33]&.value,
                       continuous: false,
                       shipment_date: row[36]&.value }

        order.assign_attributes(attributes)
        # need to validate without save
        # as a model validation is trigerred for condition shipment_date >= Date.current
        order.save(validate: false)
        bar.inc
      end
    end
  ensure
    bar.finished
  end
end

# Import additional country fields
class ImportCountry < StockitDataMigrator
  def import
    add_new_countries
    remove_old_countries
    update_new_column_values_for_existing_records
  end

  private

  def add_new_countries
    new_countries = [{ name_en: 'British Indian Ocean Territory',
                       preferred_region: 'Africa',
                       preferred_sub_region: 'Eastern Africa',
                       m49: 86,
                       iso_alpha2: 'IO',
                       iso_alpha3: 'IOT',
                       developing: 'Developing' },
                     {
                       name_en: 'Saint Barthélemy',
                       preferred_region: 'Americas',
                       preferred_sub_region: 'Caribbean',
                       m49: 652,
                       iso_alpha2: 'BL',
                       iso_alpha3: 'BLM',
                       developing: 'Developing'
                     },
                     {
                       name_en: 'Saint Martin (French Part)',
                       preferred_region: 'Americas',
                       preferred_sub_region: 'Caribbean',
                       m49: 663,
                       iso_alpha2: 'MF',
                       iso_alpha3: 'MAF',
                       developing: 'Developing'
                     },
                     {
                       name_en: 'Bouvet Island',
                       preferred_region: 'Americas',
                       preferred_sub_region: 'South America',
                       m49: 74,
                       iso_alpha2: 'BV',
                       iso_alpha3: 'BVT',
                       developing: 'Developing'
                     },
                     {
                       name_en: 'South Georgia and the South Sandwich Islands',
                       preferred_region: 'Americas',
                       preferred_sub_region: 'South America',
                       m49: 239,
                       iso_alpha2: 'GS',
                       iso_alpha3: 'SGS',
                       developing: 'Developing'
                     },
                     {
                       name_en: 'United States Minor Outlying Islands',
                       preferred_region: 'Oceania',
                       preferred_sub_region: 'Micronesia',
                       m49: 581,
                       iso_alpha2: 'UM',
                       iso_alpha3: 'UMI',
                       developing: 'Developing'
                     },
                     {
                       name_en: 'French Southern Territories',
                       preferred_region: 'Africa',
                       preferred_sub_region: 'Eastern Africa',
                       m49: 260,
                       iso_alpha2: 'TF',
                       iso_alpha3: 'ATF',
                       developing: 'Developing'
                     },
                     {
                       name_en: 'Antarctica',
                       preferred_region: 'Antarctica',
                       preferred_sub_region: 'Antarctica',
                       m49: 10,
                       iso_alpha2: 'AQ',
                       iso_alpha3: 'ATA'
                     },
                     {
                       name_en: 'Bonaire, Sint Eustatius and Saba',
                       preferred_region: 'Americas',
                       preferred_sub_region: 'Caribbean',
                       m49: 535,
                       iso_alpha2: 'BQ',
                       iso_alpha3: 'BES',
                       sids: true,
                       developing: 'Developing'
                     },
                     {
                       name_en: 'Curaçao',
                       preferred_region: 'Americas',
                       preferred_sub_region: 'Caribbean',
                       m49: 531,
                       iso_alpha2: 'CW',
                       iso_alpha3: 'CUW',
                       sids: true,
                       developing: 'Developing'
                     },
                     {
                       name_en: 'Sint Maarten (Dutch part)',
                       preferred_region: 'Americas',
                       preferred_sub_region: 'Caribbean',
                       m49: 534,
                       iso_alpha2: 'SX',
                       iso_alpha3: 'SXM',
                       sids: true,
                       developing: 'Developing'
                     },
                     {
                       name_en: 'Guernsey',
                       preferred_region: 'Europe',
                       preferred_sub_region: 'Northern Europe',
                       m49: 831,
                       iso_alpha2: 'GG',
                       iso_alpha3: 'GGY',
                       developing: 'Developed'
                     },
                     {
                       name_en: 'Jersey',
                       preferred_region: 'Europe',
                       preferred_sub_region: 'Northern Europe',
                       m49: 832,
                       iso_alpha2: 'JE',
                       iso_alpha3: 'JEY',
                       developing: 'Developed'
                     },
                     {
                       name_en: 'Sark',
                       preferred_region: 'Europe',
                       preferred_sub_region: 'Northern Europe',
                       m49: 680,
                       iso_alpha2: 'CQ',
                       iso_alpha3: 'CRQ',
                       developing: 'Developed'
                     }]

    new_countries.map do |country|
      record = Country.find_or_initialize_by(name_en: country[:name_en])
      record.assign_attributes(country)
      record.save!
    end
  end

  def remove_old_countries
    ids = [187, 202, 211]
    records = Country.where(id: ids)
    records.destroy_all
  end

  def update_new_column_values_for_existing_records
    logger do
      worksheet.collect do |row|
        next if row[0].value == 'reporting_name'
        next unless row[19].value.is_a? Integer

        country = Country.find_by(id: row[19].value)
        next unless country

        attrs = { preferred_region: row[1].value.strip,
                  preferred_sub_region: row[2].value.strip,
                  m49: row[12].value,
                  iso_alpha2: row[13].value&.strip,
                  iso_alpha3: row[14].value&.strip,
                  ldc: row[15].value.nil? ? false : true,
                  lldc: row[16].value.nil? ? false : true,
                  sids: row[17].value.nil? ? false : true,
                  developing: row[18].value&.strip }
        country.update!(attrs)

        bar.inc
      end
    ensure
      bar.finished
    end
  end
end

# Stockit Data Import
class StockitDataImporter
  def self.import_sent_dates
    ImportSentDates.new('Sent dates for import.xlsx').import
  end

  def self.map_stockit_organisation_to_organisation
    StockitOrganisationToOrganisationMapper.new('LocalOrder Org Mappings.xlsx').import
  end

  def self.import_missing_shipments
    ImportMissingShipments.new('database_ord_table_shipment_for-DB-entry.xlsx').import
  end

  def self.import_additional_country
    ImportCountry.new('Countries and regions_for-GC-DB-update.xlsx').import
  end
end
