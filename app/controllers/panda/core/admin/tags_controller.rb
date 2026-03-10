# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class TagsController < BaseController
        before_action :set_initial_breadcrumb
        before_action :set_tag, only: %i[edit update destroy]

        def index
          tenant = resolve_tenant
          @tags = Tag.for_tenant(tenant).ordered

          if params[:q].present?
            @tags = @tags.search_by_name(params[:q])
          end

          respond_to do |format|
            format.html
            format.json { render json: @tags.limit(10).map { |t| {id: t.id, name: t.name, colour: t.display_colour} } }
          end
        end

        def new
          @tag = Tag.new
        end

        def create
          tenant = resolve_tenant
          @tag = Tag.new(tag_params.merge(tenant: tenant))

          if @tag.save
            redirect_to admin_tags_path, success: "Tag created."
          else
            render :new, status: :unprocessable_entity
          end
        end

        def edit
        end

        def update
          if @tag.update(tag_params)
            redirect_to admin_tags_path, success: "Tag updated."
          else
            render :edit, status: :unprocessable_entity
          end
        end

        def destroy
          @tag.destroy
          redirect_to admin_tags_path, success: "Tag deleted."
        end

        private

        def set_tag
          @tag = Tag.for_tenant(resolve_tenant).find(params[:id])
        end

        def tag_params
          params.require(:tag).permit(:name, :colour)
        end

        def set_initial_breadcrumb
          add_breadcrumb "Settings", admin_settings_path
          add_breadcrumb "Tags", admin_tags_path
        end

        def resolve_tenant
          return ActsAsTenant.current_tenant if defined?(ActsAsTenant) && ActsAsTenant.current_tenant
          nil
        end
      end
    end
  end
end
