# Panda Core Development Tools

Panda Core provides a comprehensive set of development tools, configurations, and helpers that can be used by all Panda ecosystem gems.

## Table of Contents
- [Linting & Code Quality](#linting--code-quality)
- [Testing Helpers](#testing-helpers)
- [CI/CD Workflows](#cicd-workflows)
- [Git Hooks](#git-hooks)
- [Usage in Your Gem](#usage-in-your-gem)

## Linting & Code Quality

### StandardRB (Ruby Linting)
Panda Core includes StandardRB configuration that enforces consistent Ruby code style.

**Configuration:** `.standard.yml`
```yaml
fix: true
parallel: true
format: progress
```

**Usage:**
```bash
bundle exec standardrb          # Check for issues
bundle exec standardrb --fix    # Auto-fix issues
```

### YAML Linting
Ensures consistent YAML formatting across all configuration files.

**Configuration:** `.yamllint`

**Usage:**
```bash
yamllint -c .yamllint .
```

### Security Scanning

**Brakeman** - Static analysis security scanner for Ruby on Rails:
```bash
bundle exec brakeman --quiet
```

**Bundler Audit** - Checks for vulnerable gem dependencies:
```bash
bundle exec bundle-audit --update
```

## Testing Helpers

Panda Core provides reusable testing helpers that can be used in your gem's test suite.

### OmniAuth Test Helpers
Located in `lib/panda/core/testing/omniauth_helpers.rb`

```ruby
# In your spec_helper.rb or rails_helper.rb
require 'panda/core/testing/omniauth_helpers'

RSpec.configure do |config|
  config.include Panda::Core::Testing::OmniAuthHelpers, type: :system
end

# In your specs
it "allows admin login" do
  login_as_admin
  expect(page).to have_content("Dashboard")
end

it "allows regular user login" do
  login_as_user
  expect(page).to have_content("Welcome")
end
```

### RSpec Configuration Helper
Located in `lib/panda/core/testing/rspec_config.rb`

```ruby
# In your rails_helper.rb
require 'panda/core/testing/rspec_config'

RSpec.configure do |config|
  Panda::Core::Testing::RSpecConfig.configure(config)
  Panda::Core::Testing::RSpecConfig.setup_matchers
end
```

This provides:
- Database cleaner configuration
- OmniAuth test mode setup
- Common RSpec settings
- Custom matchers for breadcrumbs and flash messages

### Capybara Configuration Helper
Located in `lib/panda/core/testing/capybara_config.rb`

```ruby
# In your rails_helper.rb
require 'panda/core/testing/capybara_config'

Panda::Core::Testing::CapybaraConfig.configure

# Include helpers in system specs
RSpec.configure do |config|
  config.include Panda::Core::Testing::CapybaraConfig::Helpers, type: :system
end
```

Provides:
- Chrome/Cuprite driver setup
- `wait_for_ajax` helper
- `wait_for_turbo` helper
- Screenshot on failure helper

## CI/CD Workflows

### GitHub Actions Workflows

Panda Core includes GitHub Actions workflows in `.github/workflows/`:

#### CI Workflow (`ci.yml`)
Runs on every push and pull request:
- Linting (StandardRB, YAML lint)
- Security scanning (Brakeman, Bundler Audit)
- Test suite with PostgreSQL
- Coverage reporting

#### Release Workflow (`release.yml`)
Automatically releases gem when a version tag is pushed:
- Builds the gem
- Pushes to RubyGems
- Creates GitHub release

**Usage in your gem:**
```yaml
# Copy and customize the workflows for your gem
cp -r .github/workflows /path/to/your/gem/.github/
```

## Git Hooks

Panda Core uses Lefthook for git hooks management.

**Configuration:** `lefthook.yml`

Common hooks:
- Pre-commit: Run linters
- Pre-push: Run tests
- Commit-msg: Validate commit message format

**Setup:**
```bash
lefthook install
```

## Usage in Your Gem

### Setting Up Development Tools in a New Panda Gem

1. **Add panda-core to your gemspec:**
```ruby
# your-gem.gemspec
spec.add_dependency "panda-core"
spec.add_development_dependency "panda-core"
```

2. **Run the generator:**
```bash
# In your gem's directory
bundle install
rails generate panda:core:dev_tools
```

This automatically:
- Copies all linting configurations (.standard.yml, .yamllint, .rspec)
- Sets up GitHub Actions workflows for CI and releases
- Adds development dependencies to your Gemfile
- Creates testing helper configuration in spec/support/
- Adds useful rake tasks (panda:lint, panda:security, panda:quality)
- Tracks version for future updates

3. **Set up test helpers in your `spec/rails_helper.rb`:**
```ruby
require 'panda/core/testing/rspec_config'
require 'panda/core/testing/omniauth_helpers'
require 'panda/core/testing/capybara_config'

RSpec.configure do |config|
  # Apply Panda Core RSpec configuration
  Panda::Core::Testing::RSpecConfig.configure(config)
  Panda::Core::Testing::RSpecConfig.setup_matchers
  
  # Configure Capybara
  Panda::Core::Testing::CapybaraConfig.configure
  
  # Include helpers
  config.include Panda::Core::Testing::OmniAuthHelpers, type: :system
  config.include Panda::Core::Testing::CapybaraConfig::Helpers, type: :system
end
```

4. **Run linters:**
```bash
bundle exec standardrb
yamllint -c .yamllint .
bundle exec brakeman --quiet
bundle exec bundle-audit
```

### Best Practices

1. **Consistent Code Style**: Use the provided StandardRB configuration
2. **Security First**: Run Brakeman and Bundler Audit regularly
3. **Test Coverage**: Aim for high test coverage using the provided helpers
4. **CI/CD**: Use the provided GitHub Actions workflows
5. **Documentation**: Keep your gem's documentation up to date

### Available Rake Tasks

You can add these rake tasks to your gem:

```ruby
# Rakefile
require "panda/core/rake_tasks" if defined?(Panda::Core)

# This provides:
# rake lint           # Run all linters
# rake lint:ruby      # Run StandardRB
# rake lint:yaml      # Run YAML lint
# rake security       # Run security checks
# rake quality        # Run all quality checks
```

## Contributing

When contributing to Panda Core or gems using it:

1. Ensure all linters pass
2. Maintain test coverage
3. Update documentation
4. Follow the established patterns

## Support

For issues or questions about development tools:
- Open an issue on GitHub
- Check the documentation
- Review existing test examples