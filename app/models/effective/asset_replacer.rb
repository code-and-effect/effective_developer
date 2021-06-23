# Looks at the Effective::Asset and Effective::Attachments and converts to ActiveStorage
#
# 1. Put in the has_attached_files to each model to be upgraded
# 2. Remove the acts_as_asset_box

module Effective
  class AssetReplacer
    include ActiveStorage::Blob::Analyzable

    def replace!
      raise('expected effective assets') unless defined?(Effective::Asset)
      raise('expected active storage') unless defined?(ActiveStorage)

      verify!
      puts 'All attachment classes verified. Continuing...'

      Effective::Attachment.all.find_each do |attachment|
        print('.')

        asset = attachment.asset
        attachable = attachment.attachable
        next if asset.blank? || attachable.blank?

        box = attachment.box.singularize
        boxes = attachment.box

        one = attachable.respond_to?(box) && attachable.send(box).kind_of?(ActiveStorage::Attached::One)
        many = attachable.respond_to?(boxes) && attachable.send(boxes).kind_of?(ActiveStorage::Attached::Many)

        begin
          replace_effective_asset(asset, attachable, (one ? box : boxes))
        rescue => e
          puts "\nError with attachment id=#{attachment.id}: #{e}\n"
        end
      end

      puts 'All Done. Have a great day.'
      true
    end

    private

    def verify!
      (Effective::Attachment.all.pluck(:attachable_type, :box).uniq).each do |name, boxes|
        next if name.blank? || boxes.blank?

        box = boxes.singularize

        klass = name.safe_constantize
        raise("invalid class #{klass}") unless klass.present?

        instance = klass.new

        if instance.respond_to?(:effective_assets)
          raise("please remove acts_as_asset_box() from #{klass.name}")
        end

        unless instance.respond_to?(box) || instance.respond_to?(boxes)
          raise("expected #{klass.name} to has_one_attached :#{box} or has_many_attached :#{boxes}")
        end

        one = instance.respond_to?(box) && instance.send(box).kind_of?(ActiveStorage::Attached::One)
        many = instance.respond_to?(boxes) && instance.send(boxes).kind_of?(ActiveStorage::Attached::Many)

        unless one.present? || many.present?
          raise("expected #{klass.name} to has_one_attached :#{box} or has_many_attached :#{boxes}")
        end
      end

      true
    end

    def replace_effective_asset(asset, attachable, box, force: false)
      raise("attachable #{attachable.class.name} does not respond to #{box}") unless attachable.respond_to?(box)

      existing = Array(attachable.send(box))

      if !force && existing.any? { |obj| obj.respond_to?(:filename) && obj.filename.to_s == asset.file_name }
        puts("Skipping: #{attachable.class.name} #{attachable.id} #{box} #{asset.file_name}. Already exists.")
        return true
      end

      attachable.upgrading = true if attachable.respond_to?(:upgrading=)

      attachable.send(box).attach(
        io: URI.open(asset.url),
        filename: asset.file_name,
        content_type: asset.content_type.presence,
        identify: (asset.content_type.blank?)
      )
    end

  end
end
