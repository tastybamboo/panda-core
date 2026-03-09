# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::SearchRegistry do
  before { described_class.reset! }

  after { described_class.reset! }

  describe ".register" do
    it "adds a provider" do
      dummy_class = Class.new
      described_class.register(name: "pages", search_class: dummy_class)

      expect(described_class.providers.length).to eq(1)
      expect(described_class.providers.first).to eq({name: "pages", search_class: dummy_class})
    end

    it "is idempotent and overwrites a provider with the same name" do
      old_class = Class.new
      new_class = Class.new

      described_class.register(name: "pages", search_class: old_class)
      described_class.register(name: "pages", search_class: new_class)

      expect(described_class.providers.length).to eq(1)
      expect(described_class.providers.first[:search_class]).to eq(new_class)
    end

    it "keeps different providers when registering with distinct names" do
      class_a = Class.new
      class_b = Class.new

      described_class.register(name: "pages", search_class: class_a)
      described_class.register(name: "posts", search_class: class_b)

      expect(described_class.providers.length).to eq(2)
    end
  end

  describe ".search" do
    it "returns results from registered providers" do
      provider_class = Class.new do
        def self.editor_search(query, limit:)
          [{href: "/pages/1", name: "Test Page", description: "A test page"}]
        end
      end

      described_class.register(name: "pages", search_class: provider_class)
      results = described_class.search("test")

      expect(results).to eq([{href: "/pages/1", name: "Test Page", description: "A test page"}])
    end

    it "returns empty array for blank query" do
      provider_class = Class.new do
        def self.editor_search(query, limit:)
          [{href: "/pages/1", name: "Test Page", description: "A test page"}]
        end
      end

      described_class.register(name: "pages", search_class: provider_class)

      expect(described_class.search("")).to eq([])
      expect(described_class.search("  ")).to eq([])
      expect(described_class.search(nil)).to eq([])
    end

    it "aggregates results from multiple providers" do
      pages_class = Class.new do
        def self.editor_search(query, limit:)
          [{href: "/pages/1", name: "Page Result", description: "From pages"}]
        end
      end

      posts_class = Class.new do
        def self.editor_search(query, limit:)
          [{href: "/posts/1", name: "Post Result", description: "From posts"}]
        end
      end

      described_class.register(name: "pages", search_class: pages_class)
      described_class.register(name: "posts", search_class: posts_class)

      results = described_class.search("test")
      expect(results.length).to eq(2)
      expect(results.map { |r| r[:name] }).to contain_exactly("Page Result", "Post Result")
    end

    it "handles provider failures gracefully" do
      failing_class = Class.new do
        def self.editor_search(query, limit:)
          raise StandardError, "something went wrong"
        end
      end

      working_class = Class.new do
        def self.editor_search(query, limit:)
          [{href: "/posts/1", name: "Post Result", description: "From posts"}]
        end
      end

      described_class.register(name: "failing", search_class: failing_class)
      described_class.register(name: "working", search_class: working_class)

      results = described_class.search("test")
      expect(results).to eq([{href: "/posts/1", name: "Post Result", description: "From posts"}])
    end
  end

  describe ".admin_search" do
    it "returns grouped results from providers that support admin_search" do
      provider_class = Class.new do
        def self.admin_search(query, limit: 5)
          [{name: "Alice Smith", description: "alice@example.com", href: "/admin/people/1"}]
        end

        def self.searchable_config
          {group: "People", icon: "fa-solid fa-users"}
        end
      end

      described_class.register(name: "people", search_class: provider_class)
      result = described_class.admin_search("alice")

      expect(result[:groups].length).to eq(1)
      expect(result[:groups].first[:name]).to eq("People")
      expect(result[:groups].first[:icon]).to eq("fa-solid fa-users")
      expect(result[:groups].first[:results].first[:name]).to eq("Alice Smith")
    end

    it "skips providers without admin_search" do
      editor_only_class = Class.new do
        def self.editor_search(query, limit:)
          [{href: "/pages/1", name: "Page", description: "A page"}]
        end
      end

      described_class.register(name: "pages", search_class: editor_only_class)
      result = described_class.admin_search("test")

      expect(result[:groups]).to be_empty
    end

    it "skips providers that return empty results" do
      empty_class = Class.new do
        def self.admin_search(query, limit: 5)
          []
        end

        def self.searchable_config
          {group: "Empty"}
        end
      end

      described_class.register(name: "empty", search_class: empty_class)
      result = described_class.admin_search("test")

      expect(result[:groups]).to be_empty
    end

    it "returns empty groups for blank query" do
      expect(described_class.admin_search("")).to eq({groups: []})
      expect(described_class.admin_search(nil)).to eq({groups: []})
    end

    it "handles provider failures gracefully" do
      failing_class = Class.new do
        def self.admin_search(query, limit: 5)
          raise StandardError, "boom"
        end

        def self.searchable_config
          {group: "Broken"}
        end
      end

      described_class.register(name: "broken", search_class: failing_class)
      result = described_class.admin_search("test")

      expect(result[:groups]).to be_empty
    end
  end

  describe ".reset!" do
    it "clears all providers" do
      described_class.register(name: "pages", search_class: Class.new)
      described_class.reset!

      expect(described_class.providers).to be_empty
    end
  end
end
