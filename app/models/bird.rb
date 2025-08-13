class Bird < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  validates :species, presence: true, uniqueness: true
end
