class PackageSet < ActiveRecord::Base
  has_many   :packages
  belongs_to :package_type

  after_destroy   :unlink_packages
  validate        :ensure_type_integrity, on: [:update]
  validates       :package_type_id, presence: true

  private

  def unlink_packages
    Package.where(package_set_id: id).update_all(package_set_id: nil)
  end

  def ensure_type_integrity
    errors.add(:errors, I18n.t('package_sets.cannot_change_type')) if package_type_id_changed? && packages.length.positive?
  end
end
