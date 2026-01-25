# frozen_string_literal: true

module Panda
  module Core
    module Admin
      module MyProfile
        class ConnectedAccountComponent < Panda::Core::Base
          def initialize(provider:, user:)
            @provider = provider
            @user = user
            @provider_info = Panda::Core::OAuthProviders.info(provider)
            # TODO: Track which provider user logged in with
            # For now, we don't track the provider, so we can't show connection status
            @is_connected = false
          end

          def view_template
            div(class: "flex items-center justify-between p-4 border border-gray-200 rounded-lg") do
              div(class: "flex items-center gap-4") do
                # Provider icon
                div(class: "flex items-center justify-center w-12 h-12 rounded-lg bg-gray-100") do
                  i(class: "#{@provider_info[:icon]} text-2xl", style: "color: #{@provider_info[:color]};")
                end

                # Provider details
                div do
                  h3(class: "font-medium text-gray-900") { @provider_info[:name] }
                  if @is_connected
                    p(class: "text-sm text-green-600") do
                      i(class: "fa-solid fa-check-circle")
                      plain " Connected"
                    end
                  else
                    p(class: "text-sm text-gray-500") { "Not connected" }
                  end
                end
              end

              # Action button
              div do
                if @is_connected
                  render Panda::Core::Admin::ButtonComponent.new(
                    text: "Connected",
                    action: :secondary,
                    as_button: true,
                    disabled: true
                  )
                else
                  render Panda::Core::Admin::ButtonComponent.new(
                    text: "Connect",
                    action: :primary,
                    href: "#",
                    disabled: true,
                    title: "OAuth re-connection coming soon"
                  )
                end
              end
            end
          end
        end
      end
    end
  end
end
