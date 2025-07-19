# Historical Gems

`panda-core.gemspec`:

```ruby
  # TODO: Some of these are optional dependencies or need moving to other gems?
  # spec.add_dependency "activestorage-office-previewer", "~> 0.1"
  # spec.add_dependency "aws-sdk-s3", "~> 1"
  # spec.add_dependency "faraday", "~> 2"
  # spec.add_dependency "faraday-multipart", "~> 1"
  # spec.add_dependency "faraday-retry", "~> 2"
  # spec.add_dependency "fx", "~> 0.9"
  # spec.add_dependency "image_processing", "~> 1.2"
  # spec.add_dependency "importmap-rails", "~> 2"
  # spec.add_dependency "logidze", "~> 1.3"
  # spec.add_dependency "lookbook", "~> 2.3"
  # spec.add_dependency "omniauth", "~> 2.1"
  # spec.add_dependency "omniauth-rails_csrf_protection", "~> 1.0"
  # spec.add_dependency "propshaft", "~> 1.1"
  # spec.add_dependency "redis", "~> 5.3"
  # spec.add_dependency "silencer", "~> 2.0"
  # spec.add_dependency "stimulus-rails", "~> 1.3"
  # spec.add_dependency "tailwindcss-rails"
  # spec.add_dependency "turbo-rails", "~> 2.0"
  ```

`Gemfile.lock`:

```ruby
group :test do
  gem "omniauth-google-oauth2"
  gem "omniauth-microsoft_graph"
  gem "omniauth-github"
end
```
