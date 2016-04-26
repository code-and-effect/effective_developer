module EffectiveDeveloper
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      desc 'Creates an EffectiveDeveloper initializer in your application.'

      source_root File.expand_path(('../' * 4), __FILE__)

      def copy_initializer
        template 'config/effective_developer.rb', 'config/initializers/effective_developer.rb'
      end

    end
  end
end
