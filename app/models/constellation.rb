class Constellation < ApplicationRecord
  has_many :milestones

  def image_name
    name_hash = { "ウミヘビ座" => "umihebi.png" }

    name_hash[name]
  end
end
