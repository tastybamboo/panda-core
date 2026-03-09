# frozen_string_literal: true

module Panda
  module Core
    class Tagging < ApplicationRecord
      self.table_name = "panda_core_taggings"

      belongs_to :tag, class_name: "Panda::Core::Tag", counter_cache: true
      belongs_to :taggable, polymorphic: true

      validates :tag_id, uniqueness: {scope: [:taggable_type, :taggable_id]}
    end
  end
end
