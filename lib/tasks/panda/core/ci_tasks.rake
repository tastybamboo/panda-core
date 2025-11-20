# frozen_string_literal: true

# TODO: These should ideally move to the panda: namespace and lint across all loaded modules

namespace :panda do
  namespace :core do
    desc "Run all linters"
    task :lint do
      puts "Running Ruby linter..."
      sh "bundle exec standardrb"
      puts "Running YAML linter..."
      sh "yamllint -c .yamllint ."
    end

    namespace :lint do
      desc "Run Ruby linter"
      task :ruby do
        sh "bundle exec standardrb"
      end

      desc "Run YAML linter"
      task :yaml do
        sh "yamllint -c .yamllint ."
      end
    end

    desc "Run security checks"
    task :security do
      puts "Running Brakeman..."
      sh "bundle exec brakeman --quiet"
      puts "Running Bundler Audit..."
      sh "bundle exec bundle-audit --update"
    end

    desc "Run all quality checks"
    task quality: [:lint, :security]
  end
end
