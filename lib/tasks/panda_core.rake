# frozen_string_literal: true

namespace :panda do
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

  desc "Check for Panda Core dev tools updates"
  task :check_updates do
    version_file = ".panda-dev-tools-version"
    current_version = "1.0.0"

    if File.exist?(version_file)
      installed_version = File.read(version_file).strip
      if installed_version != current_version
        puts "Update available! Installed: #{installed_version}, Current: #{current_version}"
        puts "Run 'rails generate panda:core:dev_tools --force' to update"
      else
        puts "Panda Core dev tools are up to date (#{current_version})"
      end
    else
      puts "Panda Core dev tools not installed. Run 'rails generate panda:core:dev_tools' to install"
    end
  end
end
