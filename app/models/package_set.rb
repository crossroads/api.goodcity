class PackageSet < ActiveRecord::Base
  include Watcher

  has_many   :packages
  belongs_to :package_type

  after_destroy   :unlink_packages
  validate        :ensure_type_integrity, on: [:update]
  validates       :package_type_id, presence: true

  # ---------------------
  # Auto-destroy
  # ---------------------

  watch [Package], on: [:update, :destroy] do |package|
    package_set_id = package.package_set_id_changed? ? package.package_set_id_was : package.package_set_id

    package_set = PackageSet.find_by(id: package_set_id)
    package_set.destroy! if package_set.present? && package_set.packages.length < 2
  end


  # ---------------------
  # Auto-create
  # ---------------------

  ##
  #
  # Upon creation of a package, it is added to a set IF:
  #   * It belongs to an item
  #   * It has sibling packages (via the item)
  #   * It does not currently belong to a set
  #
  watch [Package], on: [:create] do |package|
    item = package.item
    siblings = [package, *item&.packages].uniq

    next if item.blank? || package.package_set_id.present? || siblings.length < 2 || item.package_type.blank?

    link_packages(siblings, item.package_type)
  end

  ##
  # When an item has it's type set for the first time, we initialize the set for its packages
  #
  watch [Item], on: [:update] do |item|
    next unless item.package_type_id_changed? && item.package_type_id_was.blank?

    children = Package.where(item: item)

    link_packages(children, item.package_type) if children.length > 1
  end

  private

  def self.link_packages(packages, package_type)
    package_set = packages.find { |p| p.package_set_id.present? }&.package_set
    package_set ||= PackageSet.create(description: package_type.name_en, package_type_id: package_type.id)

    packages.select { |p| p.package_set_id.blank? }.each do |package|
      package.update(package_set_id: package_set.id)
    end
  end

  def unlink_packages
    Package.where(package_set_id: id).update_all(package_set_id: nil)
  end

  def ensure_type_integrity
    errors.add(:errors, I18n.t('package_sets.cannot_change_type')) if package_type_id_changed? && packages.size.positive?
  end
end