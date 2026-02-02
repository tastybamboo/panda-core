# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class FileCategoriesController < BaseController
        before_action :set_initial_breadcrumb
        before_action :set_file_category, only: %i[edit update destroy]

        def index
          @file_categories = FileCategory.roots.ordered.includes(:children)
        end

        def new
          @file_category = FileCategory.new
          add_breadcrumb "New Category"
        end

        def create
          @file_category = FileCategory.new(file_category_params)

          if @file_category.save
            flash[:success] = "File category has been created successfully."
            redirect_to admin_file_categories_path
          else
            add_breadcrumb "New Category"
            render :new, status: :unprocessable_content
          end
        end

        def edit
          if @file_category.system?
            flash[:warning] = "System categories cannot be edited."
            redirect_to admin_file_categories_path
            return
          end
          add_breadcrumb @file_category.name
        end

        def update
          if @file_category.system?
            flash[:warning] = "System categories cannot be edited."
            redirect_to admin_file_categories_path
            return
          end

          if @file_category.update(file_category_params)
            flash[:success] = "File category has been updated successfully."
            redirect_to admin_file_categories_path
          else
            add_breadcrumb @file_category.name
            render :edit, status: :unprocessable_content
          end
        end

        def destroy
          if @file_category.system?
            flash[:warning] = "System categories cannot be deleted."
          elsif @file_category.destroy
            flash[:success] = "File category has been deleted successfully."
          else
            flash[:error] = @file_category.errors.full_messages.to_sentence
          end

          redirect_to admin_file_categories_path, status: :see_other
        end

        private

        def set_initial_breadcrumb
          add_breadcrumb "File Categories", admin_file_categories_path
        end

        def set_file_category
          @file_category = FileCategory.find(params[:id])
        end

        def file_category_params
          params.require(:file_category).permit(:name, :icon, :position, :parent_id)
        end
      end
    end
  end
end
