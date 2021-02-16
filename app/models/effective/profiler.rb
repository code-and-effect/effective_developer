# frozen_string_literal: true

# Effective::Profiler.allocations { my_method() }

module Effective
  class Profiler

    def self.allocations(sourcefiles: ['effective_'], &block)
      raise('please install the allocation_stats gem') unless defined?(AllocationStats)

      # Run block
      retval = nil
      stats = AllocationStats.trace { retval = yield(block) }

      # Compute Allocations
      allocations = stats.allocations.to_a

      # Filter
      if sourcefiles.present?
        sourcefiles = Array(sourcefiles)
        allocations = allocations.select! { |allocation| sourcefiles.any? { |str| allocation.sourcefile.include?(str) } }
      end

      # Sort
      allocations = allocations.sort_by { |allocation| allocation.memsize }

      # Print
      puts AllocationStats::AllocationsProxy.new(allocations).to_text

      puts "Total allocations: #{allocations.length}. Total size: #{allocations.sum(&:memsize)}"

      retval
    end


  end

end
