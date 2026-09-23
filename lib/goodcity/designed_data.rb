require 'active_support/testing/time_helpers'

module Goodcity
  #
  # Builds the designed demo dataset.
  #
  # Everything is realised through the app's own models, Package::Operations and
  # state-machine events, each one performed "at" its own moment in time, so that
  # versions, the packages_inventories ledger, message timestamps and derived
  # quantities all agree with each other. Nothing derived is ever written directly.
  #
  # The data lives in db/demo/designed/*.yml (the spine and the people) and
  # profile.json (aggregate distributions from a real stock snapshot, used for filler).
  #
  class DesignedData
    DEFAULT_SEED = 20260924
    ROOT = Rails.root.join('db', 'demo', 'designed')

    autoload :Context,      'goodcity/designed_data/context'
    autoload :Reference,    'goodcity/designed_data/reference'
    autoload :BaseData,     'goodcity/designed_data/base_data'
    autoload :People,       'goodcity/designed_data/people'
    autoload :Descriptions, 'goodcity/designed_data/descriptions'
    autoload :Stock,        'goodcity/designed_data/stock'
    autoload :Orders,       'goodcity/designed_data/orders'
    autoload :Filler,       'goodcity/designed_data/filler'
    autoload :Timeline,     'goodcity/designed_data/timeline'
    autoload :Checks,       'goodcity/designed_data/checks'

    def self.load_yaml(name)
      YAML.safe_load(File.read(ROOT.join("#{name}.yml")), aliases: true) || []
    end

    def self.profile
      @profile ||= JSON.parse(File.read(ROOT.join('profile.json')))
    end

    attr_reader :ctx

    def initialize(seed: DEFAULT_SEED, now: Time.zone.now)
      @ctx = Context.new(seed: seed, now: now)
    end

    def generate!
      started = Time.now
      # The server eager-loads; rake does not. Models such as PackageSet register their
      # callbacks on OTHER models (Watcher) when they load, so without this a set is
      # never linked and the dataset would behave unlike the real app.
      Rails.application.eager_load!
      spine = {
        items: DesignedData.load_yaml('items'),
        sets: DesignedData.load_yaml('sets'),
        warehouse: DesignedData.load_yaml('warehouse'),
        orders: DesignedData.load_yaml('orders'),
        people: DesignedData.load_yaml('people')
      }

      # One transaction: a build that fails part-way leaves the database as it found it.
      ActiveRecord::Base.transaction do
        ctx.quietly { build!(spine) }
      end

      Checks.new.run

      say format('done in %.0fs: %d packages (%d sets), %d orders, %d ledger rows, %d messages',
                 Time.now - started, Package.count, PackageSet.count, Order.count, PackagesInventory.count, Message.count)
    end

    private

    def build!(spine)
      ctx.reference.verify!(spine)
      say "reference data verified (seed=#{ctx.seed}, anchored to #{ctx.now.to_date})"

      BaseData.new(ctx).ensure!
      people = People.new(ctx, spine[:people]).build!
      say "people: #{User.count} users, #{OrganisationsUser.count} organisation memberships"

      timeline = Timeline.new(ctx)
      stock = Stock.new(ctx, people, timeline)
      orders = Orders.new(ctx, people, stock, timeline)
      filler = Filler.new(ctx, people, stock, orders, timeline)

      stock.plan_spine(spine[:items], spine[:sets], spine[:warehouse])
      orders.plan_spine(spine[:orders])
      filler.plan!(target_packages: ENV.fetch('PACKAGES', 750).to_i, target_orders: ENV.fetch('ORDERS', 250).to_i)

      say "timeline: #{timeline.size} events"
      timeline.run! { |n| print '.' if (n % 250).zero? }
      puts

      stock.after_timeline!
      BaseData.new(ctx).reserve_inventory_numbers!
      Checks.write_manifest(stock, orders)
    end

    def say(msg)
      puts "[designed] #{msg}"
    end
  end
end
