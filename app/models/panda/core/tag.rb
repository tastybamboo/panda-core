# frozen_string_literal: true

module Panda
  module Core
    class Tag < ApplicationRecord
      self.table_name = "panda_core_tags"

      belongs_to :tenant, polymorphic: true, optional: true
      has_many :taggings, class_name: "Panda::Core::Tagging", dependent: :destroy

      validates :name, presence: true,
        uniqueness: {scope: [:tenant_type, :tenant_id], case_sensitive: false}
      validates :colour, format: {with: /\A#[0-9a-fA-F]{6}\z/, message: "must be a hex colour (e.g. #ff0000)"},
        allow_blank: true

      before_validation :normalize_name

      scope :for_tenant, ->(tenant) { tenant ? where(tenant: tenant) : where(tenant_type: nil) }
      scope :ordered, -> { order(:name) }
      scope :search_by_name, ->(q) { where("name ILIKE ?", "%#{sanitize_sql_like(q)}%") }

      def display_colour
        colour.presence || "#6b7280"
      end

      private

      def normalize_name
        self.name = name&.strip
      end
    end
  end
end
