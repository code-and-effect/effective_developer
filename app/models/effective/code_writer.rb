module Effective
  class CodeWriter

    attr_reader :lines
    attr_reader :indent
    attr_reader :newline

    def initialize(filename, indent: "\t".freeze, newline: "\n".freeze, &block)
      @lines = File.open(filename).readlines

      @indent = indent
      @newline = newline

      block.call(self)

      File.open(filename, 'w') do |file|
        lines.each { |line| file.write(line) }
      end
    end

    # Returns true if the insert happened
    # Returns nil if no insert
    def insert_after_last(content, &block)
      index = last(&block)
      return nil unless index

      insert(content, index+1, depth_at(index))
    end

    def insert(content, index, depth = nil)
      contents = (content.kind_of?(Array) ? content : content.split(newline)).map { |str| str.strip }

      depth ||= depth_at(index)
      content_depth = 0

      contents.each do |content|
        content_depth -= 1 if content == 'end'.freeze

        if content == ''
          lines.insert(index, newline)
        else
          lines.insert(index, (indent * (depth + content_depth)) + content + newline)
        end

        index = index + 1

        content_depth += 1 if content.end_with?(' do'.freeze)
      end

      true
    end

    protected

    # Iterate over the lines with a depth, and passed the stripped line to the passed block
    def each_with_depth(&block)
      depth = 0

      Array(lines).each_with_index do |line, index|
        stripped = line.to_s.strip

        block.call(stripped, depth, index)

        depth += 1 if stripped.end_with?(' do'.freeze)
        depth -= 1 if stripped == 'end'.freeze
      end

      nil
    end

    def depth_at(line_index)
      each_with_depth { |_, depth, index| return depth if line_index == index }
    end

    # Returns the index of the first line where the passed block returns true
    def first(start = 0, &block)
      each_with_depth do |line, depth, index|
        next if index < start
        return index if block.call(line, depth, index)
      end
    end

    # Returns the index of the last line where the passed block returns true
    def last(start = 0, &block)
      retval = nil

      each_with_depth do |line, depth, index|
        next if index < start
        retval = index if block.call(line, depth, index)
      end

      retval
    end

    # Returns an array of indexes for each line where the passed block returnst rue
    def all(start = 0, &block)
      retval = []

      each_with_depth do |line, depth, index|
        next if index < start
        retval << index if block.call(line, depth, index)
      end

      retval
    end

  end
end
