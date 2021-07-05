# Looks at the Effective::Asset and Effective::Attachments and converts to ActiveStorage
#
# 1. Put in the has_attached_files to each model to be upgraded
# 2. Remove the acts_as_asset_box

require 'timeout'

module Effective
  class AssetReplacer
    include ActiveStorage::Blob::Analyzable

    BATCH_SIZE = 500
    TIMEOUT = 120

    def replace!(force: false)
      verify!

      attachments_to_process().find_in_batches(batch_size: BATCH_SIZE).each do |attachments|
        wait_for_active_job!

        puts "\nEnqueuing #{attachments.length} attachments with ids #{attachments.first.id} to #{attachments.last.id}"

        attachments.each do |attachment|
          asset = attachment.asset
          attachable = attachment.attachable
          next if asset.blank? || attachable.blank?

          box = attachment.box.singularize
          boxes = attachment.box

          one = attachable.respond_to?(box) && attachable.send(box).kind_of?(ActiveStorage::Attached::One)
          many = attachable.respond_to?(boxes) && attachable.send(boxes).kind_of?(ActiveStorage::Attached::Many)
          box = (one ? box : boxes)

          unless force
            existing = Array(attachable.send(box))

            if existing.any? { |obj| obj.respond_to?(:filename) && obj.filename.to_s == asset.file_name }
              puts("Skipping: #{attachable.class.name} #{attachable.id} #{box} #{asset.file_name}. Already exists."); next
            end
          end

          Effective::AssetReplacerJob.perform_later(attachment, box)
        end
      end

      puts "\nAll Done. Have a great day."
      true
    end

    # This is called on the background by the AssetReplacerJob
    def replace_attachment!(attachment, box)
      raise('expected an Effective::Attachment') unless attachment.kind_of?(Effective::Attachment)
      puts("Processing attachment ##{attachment.id}")

      asset = attachment.asset
      attachable = attachment.attachable

      attachable.upgrading = true if attachable.respond_to?(:upgrading=)

      Timeout.timeout(TIMEOUT) do
        attachable.send(box).attach(
          io: URI.open(asset.url),
          filename: asset.file_name,
          content_type: asset.content_type.presence,
          identify: (asset.content_type.blank?)
        )

        attachment.update_column(:replaced, true)
      end

      true
    end

    def verify!
      raise('expected effective assets') unless defined?(Effective::Asset)
      raise('expected active storage') unless defined?(ActiveStorage)

      unless Effective::Attachment.new.respond_to?(:replaced?)
        raise('please add a replaced boolean to Effective::Attachment. add_column :attachments, :replaced, :boolean')
      end

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

      puts 'All attachment classes verified.'

      true
    end

    def reset!
      Effective::Attachment.update_all(replaced: false)
    end

    private

    def wait_for_active_job!
      while(true)
        if(jobs = enqueued_jobs_count) > (BATCH_SIZE / 10)
          print '.'; sleep(2)
        else
          break
        end
      end
    end

    def attachments_to_process
      Effective::Attachment.all.where(replaced: [nil, false]).order(:id).where('id < ?', 10000)
    end

    def enqueued_jobs_count
      if Rails.application.config.active_job.queue_adapter == :sidekiq
        Sidekiq::Stats.new.enqueued.to_i
      else
        ActiveJob::Base.queue_adapter.enqueued_jobs.count
      end
    end

  end
end
