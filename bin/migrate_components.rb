#!/usr/bin/env ruby
# frozen_string_literal: true

# Migration script to convert Phlex components to ViewComponent
# This automates the mechanical parts of the migration:
# 1. Convert prop declarations to initialize + attr_reader
# 2. Extract view_template to .html.erb file
# 3. Update component class structure

require "fileutils"

class ComponentMigrator
  def initialize(component_path)
    @component_path = component_path
    @content = File.read(component_path)
    @props = []
    @template_content = nil
  end

  def migrate!
    puts "Migrating: #{@component_path}"

    extract_props
    extract_view_template
    generate_new_component
    generate_template_file

    puts "  ✓ Migrated successfully"
    true
  rescue => e
    puts "  ✗ Error: #{e.message}"
    puts e.backtrace.first(5)
    false
  end

  private

  def extract_props
    # Extract prop declarations: prop :name, Type, default: value
    @content.scan(/prop\s+:(\w+),\s*([^,\n]+?)(?:,\s*default:\s*(.+?))?(?:\n|$)/m) do |name, type, default|
      # Clean up the type
      type_clean = type.strip

      # Parse default value
      default_value = if default
        # Handle lambda defaults: -> {}
        if default.strip.start_with?('->')
          if default.include?('{}')
            'nil'
          else
            # Try to extract the value
            default.strip.gsub(/^->\s*\{?\s*/, '').gsub(/\s*\}?\s*$/, '').strip
          end
        else
          default.strip
        end
      else
        # Infer default from type
        case type_clean
        when /_Boolean/
          'false'
        when /_Nilable/
          'nil'
        when 'String'
          '""'
        when 'Symbol'
          ':default'
        when 'Array'
          '[]'
        when 'Hash'
          '{}'
        else
          'nil'
        end
      end

      # Fix empty hash/array defaults
      default_value = 'nil' if default_value == '{'  || default_value == '['

      @props << { name: name, type: type_clean, default: default_value }
    end

    puts "  Found #{@props.length} props: #{@props.map { |p| p[:name] }.join(', ')}"
  end

  def extract_view_template
    # Extract the view_template method body
    # Match from "def view_template" to the matching "end"
    if @content =~ /def\s+view_template.*?\n(.*?)\n\s+end/m
      @template_content = $1
      puts "  Extracted view_template (#{@template_content.lines.count} lines)"
    else
      puts "  Warning: Could not find view_template"
      @template_content = nil
    end
  end

  def generate_new_component
    # Build initialize method parameters
    params = @props.map do |prop|
      if prop[:default] && prop[:default] != 'nil' && !prop[:default].empty?
        "#{prop[:name]}: #{prop[:default]}"
      else
        "#{prop[:name]}:"
      end
    end.join(', ')

    # Build initialize method body
    assignments = @props.map { |prop| "    @#{prop[:name]} = #{prop[:name]}" }.join("\n")

    # Build attr_reader line
    attr_readers = @props.map { |prop| ":#{prop[:name]}" }.join(', ')

    # Start fresh with the original content
    lines = @content.lines

    # Find class declaration line
    class_line_idx = lines.find_index { |l| l =~ /class\s+\w+\s+<\s+Panda::Core::Base/ }

    unless class_line_idx
      raise "Could not find class declaration"
    end

    # Build new content
    new_lines = []

    # Add everything up to and including the class line
    new_lines += lines[0..class_line_idx]

    # Add the initialize method
    new_lines << "    def initialize(#{params}, **attrs)\n"
    new_lines << "#{assignments}\n"
    new_lines << "      super(**attrs)\n"
    new_lines << "    end\n"
    new_lines << "\n"
    new_lines << "    attr_reader #{attr_readers}\n"
    new_lines << "\n"

    # Find where props end and regular methods begin
    # Skip all prop lines and add everything after them
    in_props = false
    lines[(class_line_idx + 1)..-1].each do |line|
      # Skip prop declarations
      next if line =~ /^\s*prop\s+:/

      # Skip view_template method
      if line =~ /^\s*def\s+view_template/
        in_view_template = true
        next
      end

      if in_view_template
        if line =~ /^\s+end\s*$/
          in_view_template = false
        end
        next
      end

      new_lines << line
    end

    # Write the new content
    File.write(@component_path, new_lines.join)
    puts "  Updated component class"
  end

  def generate_template_file
    template_path = @component_path.sub('.rb', '.html.erb')

    if @template_content.nil?
      erb_content = "<!-- TODO: Add template content -->\n"
    else
      # For now, just create a placeholder with the original Phlex code as a comment
      # Complex conversions will be done manually
      erb_content = <<~ERB
<!-- TODO: Convert from Phlex to ERB -->
<!-- Original Phlex view_template:
#{@template_content.lines.map { |l| l }.join}
-->
      ERB
    end

    File.write(template_path, erb_content)
    puts "  Created template: #{File.basename(template_path)}"
  end
end

# Main execution
if ARGV.empty?
  puts "Usage: ruby bin/migrate_components.rb <component_path>"
  puts "   or: ruby bin/migrate_components.rb --all"
  exit 1
end

if ARGV[0] == '--all'
  components = Dir.glob('app/components/panda/core/**/*.rb').reject { |f| f.end_with?('base.rb') }
  puts "Found #{components.length} components to migrate\n\n"

  success = 0
  failed = 0

  components.sort.each do |component|
    if ComponentMigrator.new(component).migrate!
      success += 1
    else
      failed += 1
    end
    puts ""
  end

  puts "\n" + "="*50
  puts "Migration complete!"
  puts "  Successful: #{success}"
  puts "  Failed: #{failed}"
  puts "="*50
  puts "\nNext steps:"
  puts "  1. Review generated .html.erb templates"
  puts "  2. Convert Phlex DSL to ERB manually"
  puts "  3. Run: bundle exec rspec"
else
  migrator = ComponentMigrator.new(ARGV[0])
  migrator.migrate!
end
