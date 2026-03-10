# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class TagInputComponent < Panda::Core::Base
        attr_reader :field_name, :tags_url, :selected_tags

        def initialize(tags_url:, field_name: "tag_ids[]", selected_tags: [], **attrs)
          @field_name = field_name
          @tags_url = tags_url
          @selected_tags = selected_tags
          super(**attrs)
        end

        def selected_tags_json
          selected_tags.map { |t| {id: t.id, name: t.name, colour: t.display_colour} }.to_json
        end
      end
    end
  end
end
