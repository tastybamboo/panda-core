# frozen_string_literal: true

module Panda
  module Core
    module Taggable
      extend ActiveSupport::Concern

      included do
        has_many :taggings, class_name: "Panda::Core::Tagging",
          as: :taggable, dependent: :destroy
        has_many :tags, through: :taggings, class_name: "Panda::Core::Tag"

        scope :tagged_with, ->(tag_ids) {
          joins(:taggings)
            .where(panda_core_taggings: {tag_id: Array(tag_ids)})
            .distinct
        }

        scope :tagged_with_all, ->(tag_ids) {
          tag_ids = Array(tag_ids)
          joins(:taggings)
            .where(panda_core_taggings: {tag_id: tag_ids})
            .group(arel_table[:id])
            .having("COUNT(DISTINCT panda_core_taggings.tag_id) = ?", tag_ids.size)
        }
      end

      def tag_list
        tags.map(&:name).sort.join(", ")
      end

      def tag_ids=(ids)
        self.tags = Panda::Core::Tag.where(id: Array(ids).reject(&:blank?))
      end
    end
  end
end
