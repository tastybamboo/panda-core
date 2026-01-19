# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::Admin::FileGalleryComponent do
  describe "initialization and property access" do
    it "accepts files property without NameError" do
      component = described_class.new(files: [], selected_file: nil)
      expect(component).to be_a(described_class)
    end

    it "accepts selected_file property without NameError" do
      file = instance_double("File", id: 1)
      component = described_class.new(files: [file], selected_file: file)
      expect(component).to be_a(described_class)
    end

    it "has default values for properties" do
      component = described_class.new
      expect(component).to be_a(described_class)
    end
  end

  describe "file_container_classes" do
    it "renders base container classes when not selected" do
      component = described_class.new(files: [], selected_file: nil)
      
      classes = component.send(:file_container_classes, false)
      expect(classes).to include("group")
      expect(classes).to include("overflow-hidden")
      expect(classes).to include("rounded-lg")
      expect(classes).to include("bg-gray-100")
    end

    it "includes focus styling when not selected" do
      component = described_class.new(files: [], selected_file: nil)
      
      classes = component.send(:file_container_classes, false)
      expect(classes).to include("focus-within:outline")
      expect(classes).to include("focus-within:outline-indigo-600")
    end

    it "includes selected outline when selected" do
      component = described_class.new(files: [], selected_file: nil)
      
      classes = component.send(:file_container_classes, true)
      expect(classes).to include("outline")
      expect(classes).to include("outline-panda-dark")
    end
  end

  describe "file_image_classes" do
    it "includes base image classes" do
      component = described_class.new(files: [], selected_file: nil)
      
      classes = component.send(:file_image_classes, false)
      expect(classes).to include("pointer-events-none")
      expect(classes).to include("aspect-10/7")
      expect(classes).to include("object-cover")
    end

    it "includes hover opacity when not selected" do
      component = described_class.new(files: [], selected_file: nil)
      
      classes = component.send(:file_image_classes, false)
      expect(classes).to include("group-hover:opacity-75")
    end

    it "excludes hover opacity when selected" do
      component = described_class.new(files: [], selected_file: nil)
      
      classes = component.send(:file_image_classes, true)
      expect(classes).not_to include("group-hover:opacity-75")
    end
  end

  describe "number_to_human_size helper" do
    it "formats zero bytes" do
      component = described_class.new(files: [], selected_file: nil)
      
      result = component.send(:number_to_human_size, 0)
      expect(result).to eq("0 Bytes")
    end

    it "formats bytes" do
      component = described_class.new(files: [], selected_file: nil)
      
      result = component.send(:number_to_human_size, 512)
      expect(result).to match(/^\d+\.\d+\s+Bytes$/)
    end

    it "formats kilobytes" do
      component = described_class.new(files: [], selected_file: nil)
      
      result = component.send(:number_to_human_size, 1024)
      expect(result).to match(/^\d+\.\d+\s+KB$/)
    end

    it "formats megabytes" do
      component = described_class.new(files: [], selected_file: nil)
      
      result = component.send(:number_to_human_size, 1024 * 1024)
      expect(result).to match(/^\d+\.\d+\s+MB$/)
    end

    it "formats gigabytes" do
      component = described_class.new(files: [], selected_file: nil)
      
      result = component.send(:number_to_human_size, 1024 * 1024 * 1024)
      expect(result).to match(/^\d+\.\d+\s+GB$/)
    end

    it "formats terabytes" do
      component = described_class.new(files: [], selected_file: nil)
      
      result = component.send(:number_to_human_size, 1024 * 1024 * 1024 * 1024)
      expect(result).to match(/^\d+\.\d+\s+TB$/)
    end
  end

  describe "url_for helper" do
    it "returns hash symbol for non-existent file" do
      component = described_class.new(files: [], selected_file: nil)
      
      result = component.send(:url_for, Object.new)
      expect(result).to eq("#")
    end
  end


  describe "initialization with various inputs" do
    it "accepts empty files list" do
      component = described_class.new(files: [])
      expect(component.files).to eq([])
    end

    it "accepts multiple files" do
      files = [
        instance_double("File", id: 1),
        instance_double("File", id: 2)
      ]
      component = described_class.new(files: files)
      expect(component.files).to eq(files)
    end

    it "accepts nil selected_file" do
      component = described_class.new(selected_file: nil)
      expect(component.selected_file).to be_nil
    end

    it "accepts file object as selected_file" do
      file = instance_double("File", id: 1)
      component = described_class.new(selected_file: file)
      expect(component.selected_file).to eq(file)
    end
  end
end
