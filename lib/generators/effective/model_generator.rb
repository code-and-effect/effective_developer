# rails generate effective:controller Thing [action action] [options]
# rails generate controller NAME [action action] [options]

module Effective
  module Generators
    class ModelGenerator < Rails::Generators::NamedBase
      desc "Creates an Effective model in your app/models folder."

      source_root File.expand_path(('../' * 4) + 'app/scaffolds', __FILE__)

      argument :attributes, type: :array, default: [], banner: 'field[:type][:index] field[:type][:index]'

      hook_for :orm, required: true, desc: 'ORM to be invoked'

    end
  end
end
