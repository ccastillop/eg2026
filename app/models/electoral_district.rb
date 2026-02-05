class ElectoralDistrict < ApplicationRecord
  has_many :candidates, dependent: :nullify

  validates :name, presence: true
  validates :code, presence: true, uniqueness: true
  validates :district_type, presence: true

  # Scopes
  scope :departments, -> { where(district_type: 'department') }
  scope :abroad, -> { where(district_type: 'abroad') }
  scope :ordered, -> { order(:name) }

  def to_s
    name
  end

  def display_name
    seats_count ? "#{name} (#{seats_count} escaños)" : name
  end
end
