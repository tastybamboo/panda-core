# frozen_string_literal: true

module Panda
  module Core
    class FileCategorization < ApplicationRecord
      self.table_name = "panda_core_file_categorizations"

      belongs_to :file_category, class_name: "Panda::Core::FileCategory"
      belongs_to :blob, class_name: "ActiveStorage::Blob"

      validates :file_category_id, uniqueness: {scope: :blob_id}
    end
  end
end
