# rails generate effective:scaffold Thing

module Effective
  module Generators
    class ScaffoldGenerator < Rails::Generators::NamedBase
      desc 'Creates an Effective Scaffold'

      argument :name, type: :string, default: nil
      argument :attributes, type: :array, default: [], banner: 'field:type field:type'

      source_root File.expand_path(('../' * 4) + 'app/scaffolds', __FILE__)

# config.generators do |g|
#   g.orm             :active_record
#   g.template_engine :erb
#   g.test_framework  :test_unit, fixture: false
#   g.stylesheets     false
#   g.javascripts     false
# end

      def initialize(args, *options)
        super
        assign_extended_options!(args)
      end

      def create_model
      end

      def create_controller
      end

      # def copy_view_files
      #   available_views.each do |view|
      #     filename = filename_with_extensions(view)
      #     template filename, File.join("app/views", controller_file_path, filename)
      #   end
      # end

      def add_to_routes
      end

      def create_model
        template 'model.rb.erb', "app/models/#{file_path}.rb"
      end

      def show_readme
        readme "README" if behavior == :invoke
      end

      protected

      def indent(attribute, tabs = 3)
        longest = attributes.map { |attribute| attribute.name.length }.max
        current = attribute.kind_of?(String) ? attribute.length : attribute.name.length
        difference = ((longest - current) / 2).to_i

        if (longest % 2 != 0) || (current % 2 != 0)
          [*0..(tabs+difference)].map { "\t" }.join()
        else
          [*1..(tabs+difference)].map { "\t" }.join()
        end
      end

      def format(options, top = true)
        case options
        when Hash
          (top ? '' : '{') + options.map { |k, v| ":#{k} => #{format(v, false)}" }.join(', ') + (top ? '' : '}')
        when Array
          '[' + options.map { |obj| format(obj, true) }.join(', ') + ']'
        when String
          "'#{options}'"
        when Symbol
          ":#{options}"
        else
          options.to_s
        end
      end

      private

      # rails generate effective:model Effective::SomethingAwful title:string:default='something in the way':validates[presence, numericality]
      # rails generate effective:model Effective::SomethingAwful title:string:default['something in the way']:validates[presence,numericality[greater_than_or_equal_to[0]]]
      def assign_extended_options!(args)
        attributes.each do |attribute|
          arg = args.find { |arg| arg.split(':').first == attribute.name }
          next unless arg

          (arg.split(':')[2..-1] || []).each do |option|
            attribute.attr_options.merge!(parse_option(option))
          end

        end
      end

      # rails generate effective:model Effective::SomethingAwful title:string:default['something in the way']:validates[presence,numericality[greater_than_or_equal_to[0]]]

      def parse_option(option, from_inner = false)
        raise 'Unbalanced brackets error' if option.count('[') != option.count(']')

        options = split_by_commas(option)

        if options.length > 1
          options.map { |option| parse_option(option) }
        else
          open = option.index('[')
          close = option.rindex(']')

          if open.nil? && close.nil? # This is a singular value
            value = (Integer(option) rescue nil) || (Float(option) rescue nil)
            value ||= (from_inner ? option.to_s : option.to_sym)
          else
            outer = option[0...open]
            inner = option[open+1...close]

            {outer.to_sym => parse_option(inner, true)}
          end
        end
      end

      def split_by_commas(str)
        start = 0; depth = 0
        length = str.length

        [].tap do |splits|
          str.chars.each_with_index do |char, index|
            if char == '['
              depth += 1
            elsif char == ']'
              depth -= 1
            elsif char == ',' && depth == 0
              splits << str[start...index]
              start = index+1
            end
          end
          splits << str[start..length] # Last split
        end
      end

    end
  end
end

# class_name
# class_path
# file_path



# require "rails/generators/rails/resource/resource_generator"

# module Effective
#   module Generators
#     class ScaffoldGenerator < ResourceGenerator # :nodoc:
#       remove_hook_for :resource_controller
#       remove_class_option :actions

#       class_option :stylesheets, type: :boolean, desc: "Generate Stylesheets"
#       class_option :stylesheet_engine, desc: "Engine for Stylesheets"
#       class_option :assets, type: :boolean
#       class_option :resource_route, type: :boolean
#       class_option :scaffold_stylesheet, type: :boolean

#       def handle_skip
#         @options = @options.merge(stylesheets: false) unless options[:assets]
#         @options = @options.merge(stylesheet_engine: false) unless options[:stylesheets] && options[:scaffold_stylesheet]
#       end

#       hook_for :scaffold_controller, required: true

#       hook_for :assets do |assets|
#         invoke assets, [controller_name]
#       end

#       hook_for :stylesheet_engine do |stylesheet_engine|
#         if behavior == :invoke
#           invoke stylesheet_engine, [controller_name]
#         end
#       end
#     end
#   end
# end
