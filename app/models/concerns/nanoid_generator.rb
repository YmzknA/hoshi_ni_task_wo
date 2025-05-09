# frozen_string_literal: true

module NanoidGenerator
  extend ActiveSupport::Concern

  ID_ALPHABET = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
  ID_LENGTH = 21
  MAX_RETRY = 1000

  class_methods do
    def generate_nanoid(alphabet: ID_ALPHABET, size: ID_LENGTH)
      Nanoid.generate(size:, alphabet:)
    end
  end

  def set_id
    return if id.present?

    MAX_RETRY.times do
      self.id = generate_id
      return unless self.class.exists?(id:)
    end
    raise "Failed to generate a unique public id after #{MAX_RETRY} attempts"
  end

  def generate_id
    self.class.generate_nanoid
  end
end
