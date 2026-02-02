# frozen_string_literal: true

module Panda
  module Core
    module Seeds
      module FileCategories
        DEFAULTS = [
          {name: "Media Library", slug: "media-library", icon: "fa-solid fa-photo-film", position: 0},
          {name: "Page Images", slug: "page-images", icon: "fa-solid fa-file-image", position: 1},
          {name: "Post Images", slug: "post-images", icon: "fa-solid fa-newspaper", position: 2},
          {name: "User Avatars", slug: "user-avatars", icon: "fa-solid fa-user-circle", position: 3},
          {name: "Website Avatars", slug: "website-avatars", icon: "fa-solid fa-users", position: 4},
          {name: "Form Uploads", slug: "form-uploads", icon: "fa-solid fa-file-arrow-up", position: 5},
          {name: "Social Media", slug: "social-media", icon: "fab fa-instagram", position: 6}
        ].freeze

        def self.seed!
          DEFAULTS.each do |attrs|
            Panda::Core::FileCategory.find_or_create_by!(slug: attrs[:slug]) do |category|
              category.name = attrs[:name]
              category.icon = attrs[:icon]
              category.position = attrs[:position]
              category.system = true
            end
          end
        end
      end
    end
  end
end
