EffectiveDeveloper.setup do |config|
  # Tracks changes to the effective_resource do .. end block
  # And automatically writes database migration changes
  config.live = false
end
