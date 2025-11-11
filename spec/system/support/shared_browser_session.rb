module SharedBrowserSession
  def self.included(base)
    base.before(:all) do
      @__initial_driver = Capybara.current_driver
      Capybara.current_driver = :cuprite
    end

    base.after(:each) do
      Capybara.reset_sessions!
    end

    base.after(:all) do
      Capybara.current_driver = @__initial_driver
    end
  end
end

RSpec.configure do |config|
  config.include SharedBrowserSession, type: :system
end
