# Panda Core

Core functionality shared between Panda Software gems:

- Panda CMS (https://github.com/tastybamboo/panda_cms)

## Installation

Add this line to your application's Gemfile:

```
gem 'panda-core'
```

And then execute:

```
bundle install
```

## Setup

### 1. Run the Install Generator

This will:

- Add required gem dependencies
- Create an initializer
- Mount the engine in your routes

```
rails generate panda:core:install
```

### 2. Install Configuration Templates

Panda Core provides standard configuration files that can be used across all Panda gems to ensure consistency.

```
rails generate panda:core:templates
```

This will copy the following configuration files to your project:

- `.github/workflows/ci.yml` - GitHub Actions CI workflow
- `.github/dependabot.yml` - Dependabot configuration
- `.erb_lint.yml` - ERB linting rules
- `.eslintrc.js` - ESLint configuration
- `.gitattributes` - Git file handling rules
- `.gitignore` - Standard git ignore rules
- `.lefthook.yml` - Git hooks configuration
- `.rspec` - RSpec configuration
- `.standard.yml` - Ruby Standard configuration

### 3. Configure Dependencies

The gems listed in the `panda-core.gemspec` will be added to your Gemfile (or, if this an engine, your `gem-name.gemspec` file).

Make sure to follow the setup instructions for each of these gems.

## Development

After checking out the repo:

1. Run setup:

```
bin/setup
```

2. Run the test suite:

```
bundle exec rspec
```

3. Run the linter:

```
bundle exec standardrb
```

## Testing

The gem includes several types of tests:

- Generator tests for installation and template copying
- System tests using Capybara
- Unit tests for core functionality

To run specific test types:

```
# Run all tests
bundle exec rspec
```

```
# Run only generator tests
bundle exec rspec spec/generators
```

```
# Run only system tests
bundle exec rspec spec/system
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b feature/my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin feature/my-new-feature`)
5. Create new Pull Request

Bug reports and pull requests are welcome on GitHub at https://github.com/tastybamboo/panda-core.

## Releasing

For e.g. v0.1.8, run the following commands:

```bash
RELEASE_VERSION=0.1.8
git checkout -b release/v$RELEASE_VERSION
gem bump --no-commit --version $RELEASE_VERSION
bundle update
git commit -am "Release $RELEASE_VERSION"
git tag -a $RELEASE_VERSION -m "Release $RELEASE_VERSION"
git push origin release/v$RELEASE_VERSION
gem release panda-core -v $RELEASE_VERSION
git checkout main && git merge release/v$RELEASE_VERSION
git push origin main
git push origin :release/v$RELEASE_VERSION
```

## License

The gem is available as open source under the terms of the [BSD 3-Clause License](https://opensource.org/licenses/BSD-3-Clause).
