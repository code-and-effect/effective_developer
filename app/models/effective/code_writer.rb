# frozen_string_literal: true

#   Effective::CodeWriter.new('Gemfile') do |w|
#     @use_effective_resources = w.find { |line| line.include?('effective_resources') }.present?
#   end
# end

module Effective
  class CodeWriter

    attr_reader :lines
    attr_reader :filename, :indent, :newline

    def initialize(filename, indent: '  ', newline: "\n", &block)
      @filename = filename
      @indent = indent
      @newline = newline

      @from = []
      @to = []

      @changed = false

      @lines = File.open(filename).readlines

      if block_given?
        block.call(self)
        write!
      end
    end

    # Returns true if the insert happened, nil if no insert
    def insert_into_first(content, &block)
      index = first(&block)
      return nil unless index

      insert_raw(content, index, depth_at(index) + 1)
    end

    # Returns true if the insert happened, nil if no insert
    def insert_after_first(content, depth: nil, content_depth: nil, &block)
      index = first(&block)
      return nil unless index

      insert(content, index, depth: depth, content_depth: content_depth)
    end

    # Returns true if the insert happened, nil if no insert
    def insert_after_last(content, depth: nil, content_depth: nil, &block)
      index = last(&block)
      return nil unless index

      insert(content, index, depth: depth, content_depth: content_depth)
    end

    # Returns true if the insert happened, nil if no insert
    def insert_before_last(content, depth: nil, content_depth: nil, &block)
      index = last(&block)
      return nil unless index

      insert(content, index-1, depth: depth, content_depth: content_depth)
    end

    def within(content, &block)
      content ||= 0

      from = content.kind_of?(Integer) ? content : first { |line| line.start_with?(content) && open?(line) }
      return nil unless from

      from_depth = depth_at(from)

      to = first(from: from) { |line, depth| depth == from_depth && close?(line) }
      return nil unless to

      @from.push(from); @to.push(to)
      yield
      @from.pop; @to.pop
    end

    def insert(content, index, depth: nil, content_depth: nil)
      contents = (content.kind_of?(Array) ? content : content.split(newline)).map { |str| str.strip }

      depth ||= depth_at(index)

      # If the line we're inserting at is a block, fast-forward the end of the block. And add a newline.
      if open?(index)
        index = first(from: index) { |line| close?(line) } + 1
        lines.insert(index, newline)
      elsif !whitespace?(index) && (open?(contents) || !same?(contents, index))
        index += 1
        lines.insert(index, newline)
      end

      content_depth ||= 0

      index = index + 1 # Insert after the given line

      contents.each do |content|
        content_depth -= 1 if close?(content)

        if content == ''
          lines.insert(index, newline)
        else
          lines.insert(index, (indent * (depth + content_depth)) + content + newline)
        end

        index += 1
        content_depth += 1 if open?(content)
      end

      unless whitespace?(index) || close?(index)
        if block?(contents) || !same?(contents, index)
          lines.insert(index, newline)
        end
      end

      @changed = true
    end

    def insert_raw(content, index, depth = 0)
      contents = (content.kind_of?(Array) ? content : content.split(newline))

      index = index + 1 # Insert after the given line

      contents.each do |content|
        if content.strip == ''
          lines.insert(index, newline)
        else
          lines.insert(index, (indent * depth) + content + newline)
        end

        index += 1
      end

      @changed = true
    end

    # Iterate over the lines with a depth, and passed the stripped line to the passed block
    def each_with_depth(&block)
      depth = 0
      from_depth = (@from.last ? depth_at(@from.last) : 0)

      Array(lines).each_with_index do |line, index|
        stripped = line.to_s.strip

        depth -= 1 if close?(stripped)

        block.call(stripped, depth - from_depth, index)
        depth += 1 if open?(stripped)
      end

      nil
    end

    # Returns the index of the first line where the passed block returns true
    def first(from: @from.last, to: @to.last, &block)
      each_with_depth do |line, depth, index|
        next if index < (from || 0)
        return index if block.call(line, depth, index)
        break if to == index
      end
    end
    alias_method :find, :first

    # Returns the index of the last line where the passed block returns true
    def last(from: @from.last, to: @to.last, &block)
      retval = nil

      each_with_depth do |line, depth, index|
        next if index < (from || 0)
        retval = index if block.call(line, depth, index)
        break if to == index
      end

      retval
    end

    # Returns an array of indexes for each line where the passed block returns true
    def all(from: @from.last, to: @to.last, &block)
      retval = []

      each_with_depth do |line, depth, index|
        next if index < (from || 0)
        retval << index if block.call(line, depth, index)
        break if to == index
      end

      retval
    end
    alias_method :select, :all

    # Yields each line to a block and returns an array of the results
    def map(from: @from.last, to: @to.last, indexes: [], &block)
      retval = []

      each_with_depth do |line, depth, index|
        next if index < (from || 0)
        next unless indexes.blank? || indexes.include?(index)

        retval << block.call(line, depth, index)
        break if to == index
      end

      retval
    end

    def depth_at(line_index)
      if filename.end_with?('.haml')
        return (lines[line_index].length - lines[line_index].lstrip.length) / indent.length
      end

      depth = 0

      Array(lines).each_with_index do |line, index|
        depth -= 1 if close?(line)
        break if line_index == index
        depth += 1 if open?(line)
      end

      depth
    end

    def changed?
      @changed == true
    end

    def gsub!(source, target)
      lines.each { |line| @changed = true if line.gsub!(source, target) }
    end

    def remove(from:, to:)
      raise('expected from to be less than to') unless from.present? && to.present? && (from < to)
      @changed = true
      (to - from).times { lines.delete_at(from) }
    end

    def replace(index, content)
      @changed = true
      lines[index].replace(content.to_s)
    end

    def write!
      return false unless changed?

      File.open(filename, 'w') do |file|
        lines.each { |line| file.write(line) }
      end

      true
    end

    private

    def open?(content)
      stripped = ss(content)

      ['class ', 'module ', 'def ', 'if '].any? { |start_with| stripped.start_with?(start_with) } ||
      (stripped.include?(' do') && !stripped.end_with?('end'))
    end

    def close?(content)
      stripped = ss(content, array_method: :last)
      stripped.end_with?('end') && !stripped.include?('do ')
    end

    def whitespace?(content)
      ss(content).length == 0
    end

    def block?(content)
      close?(content) || open?(content)
    end

    # Is the first word in each line the same?
    def same?(a, b)
      ss(a).split(' ').first == ss(b).split(' ').first
    end

    # Stripped string
    def ss(value, array_method: :first)
      value = case value
      when Integer then lines[value]
      when Array then value.send(array_method)
      else value
      end.to_s.split('#').first.to_s.strip
    end
  end
end
