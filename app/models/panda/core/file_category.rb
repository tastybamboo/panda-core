# frozen_string_literal: true

module Panda
  module Core
    class FileCategory < ApplicationRecord
      self.table_name = "panda_core_file_categories"

      belongs_to :parent, class_name: "Panda::Core::FileCategory", optional: true
      has_many :children, class_name: "Panda::Core::FileCategory", foreign_key: :parent_id, dependent: :nullify
      has_many :file_categorizations, class_name: "Panda::Core::FileCategorization", dependent: :destroy
      has_many :blobs, through: :file_categorizations

      validates :name, presence: true
      validates :slug, presence: true, uniqueness: true,
        format: {with: /\A[a-z0-9-]+\z/, message: "must contain only lowercase letters, numbers, and hyphens"}

      before_validation :generate_slug, if: -> { slug.blank? && name.present? }
      before_destroy :prevent_system_deletion

      scope :roots, -> { where(parent_id: nil) }
      scope :ordered, -> { order(:position, :name) }
      scope :system_categories, -> { where(system: true) }
      scope :custom_categories, -> { where(system: false) }

      # Returns all blob IDs for this category and its children
      def all_blob_ids
        category_ids = [id] + children.pluck(:id)
        Panda::Core::FileCategorization.where(file_category_id: category_ids).pluck(:blob_id)
      end

      private

      def generate_slug
        self.slug = name.parameterize
      end

      def prevent_system_deletion
        return unless system?

        errors.add(:base, "System categories cannot be deleted")
        throw(:abort)
      end
    end
  end
end
