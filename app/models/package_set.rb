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

  watch [Package], on: [:update, :destroy] do |package, event|
    package_set_id = package.package_set_id_changed? ? package.package_set_id_was : package.package_set_id

    package_set = PackageSet.find_by(id: package_set_id)
    package_set.destroy! if package_set.present? && package_set.packages.length < 2
  end

  private

  def unlink_packages
    Package.where(package_set_id: id).update_all(package_set_id: nil)
  end

  def ensure_type_integrity
    errors.add(:errors, I18n.t('package_sets.cannot_change_type')) if package_type_id_changed? && packages.size.positive?
  end
end
