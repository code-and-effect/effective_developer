# Writes the effective_resource do .. end block into the model file
module Effective
  class Annotator

    def initialize(resource: 'All', folders: 'app/models/')
      @resources = Array(resource).map { |resource| resource.to_s.classify }
      @folders = Array(folders)
    end

    def annotate!
      @folders.each do |folder|
        Dir.glob(folder + '**/*').each do |path|
          next if File.directory?(path)

          name = path.sub(folder, '').split('.')[0...-1].join('.')
          resource = Effective::Resource.new(name)
          klass = resource.klass

          next if klass.blank?
          next unless klass.ancestors.include?(ActiveRecord::Base)
          next if klass.abstract_class?
          next unless @resources.include?('All') || @resources.include?(klass.name)

          annotate(resource, path)
        end
      end

      puts 'All Done. Have a great day.'
      true
    end

    private

    def annotate(resource, path)
      puts "Annotate: #{path}"

      Effective::CodeWriter.new(path) do |writer|
        index = find_insert_at(writer)
        content = build_content(resource)

        remove_existing(writer)
        writer.insert(content, index)
      end
    end

    def find_insert_at(writer)
      index = writer.first { |line| line.include?('effective_resource do') || line.include?('structure do') }

      index ||= begin
        index = writer.first { |line| line.include?('validates :') || line.include?('scope :') || line.include?('def ') }
        index - 1 if index
      end

      [1, index.to_i-1].max
    end

    def remove_existing(writer)
      from = writer.first { |line| line.include?('effective_resource do') || line.include?('structure do') }
      return unless from.present?

      to = writer.first(from: from) { |line| line == 'end' || line == '# end' }
      return unless to.present?

      writer.remove(from: from, to: to+1)
    end

    def build_content(resource)
      attributes = resource.klass_attributes(all: true)
      atts = attributes.except(resource.klass.primary_key.to_sym, :created_at, :updated_at)

      max = atts.map { |k, v| k.to_s.length }.max.to_i + 4
      max = max + 1 unless (max % 2 == 0)

      lines = atts.map { |k, v| k.to_s + (' ' * (max - k.to_s.length)) + ":#{v.first}" }
      lines += ['', 'timestamps'] if attributes.key?(:created_at) && attributes.key?(:updated_at)

      ['effective_resource do'] + lines + ['end']
    end

  end
end
