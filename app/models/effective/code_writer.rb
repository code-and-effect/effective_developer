module Effective
  class CodeWriter

    attr_reader :lines
    attr_reader :indent, :newline

    def initialize(filename, indent: "\t".freeze, newline: "\n".freeze, &block)
      @lines = File.open(filename).readlines

      @indent = indent
      @newline = newline

      # Two stacks of indexes, used by within()
      @from = []
      @to = []

      block.call(self)

      File.open(filename, 'w') do |file|
        lines.each { |line| file.write(line) }
      end
    end

    # Returns true if the insert happened, nil if no insert
    def insert_after_last(content, &block)
      index = last(&block)
      return nil unless index

      insert(content, index)
    end

    # Returns true if the insert happened, nil if no insert
    def insert_before_last(content, &block)
      index = last(&block)
      return nil unless index

      insert(content, index-1)
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

    def insert(content, index, depth = nil)
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

      content_depth = 0

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

      true
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
        puts "[#{depth}]: #{line}"

        next if index < (from || 0)
        retval = index if block.call(line, depth, index)
        break if to == index
      end

      retval
    end

    # Returns an array of indexes for each line where the passed block returnst rue
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

    private

    def depth_at(line_index)
      depth = 0

      Array(lines).each_with_index do |line, index|
        depth -= 1 if close?(line)
        break if line_index == index
        depth += 1 if open?(line)
      end

      depth
    end

    def open?(content)
      stripped = ss(content)

      [' do'].any? { |end_with| stripped.end_with?(end_with) } ||
      ['class ', 'module ', 'def ', 'if '].any? { |start_with| stripped.start_with?(start_with) }
    end

    def close?(content)
      stripped = ss(content, array_method: :last)
      stripped.end_with?('end'.freeze) && !stripped.include?('do ')
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
      end.strip
    end
  end
end
