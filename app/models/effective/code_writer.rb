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

    def insert(content, index, depth = nil)
      contents = (content.kind_of?(Array) ? content : content.split(newline)).map { |str| str.strip }

      depth ||= depth_at(index)

      # If the line we're inserting at is a block, fast-forward the end of the block. And add a newline.
      if do?(index)
        index = first(start: index) { |line| end?(line) } + 1
        lines.insert(index, newline)
      elsif !same?(contents, index) && !whitespace?(index)  # If the line above us isn't the same command or whitespace add a new line.
        lines.insert(index+1, newline)
        index += 1
      end

      content_depth = 0

      index = index + 1 # Insert after the given line

      contents.each do |content|
        content_depth -= 1 if end?(content)

        if content == ''
          lines.insert(index, newline)
        else
          lines.insert(index, (indent * (depth + content_depth)) + content + newline)
        end

        index += 1
        content_depth += 1 if do?(content)
      end

      if block?(contents) && !whitespace?(index)
        lines.insert(index, newline)
      elsif !whitespace?(index) && !(same?(contents.first, index) || end?(index))
        lines.insert(index, newline)
      end

      true
    end

    protected

    # Iterate over the lines with a depth, and passed the stripped line to the passed block
    def each_with_depth(&block)
      depth = 0

      Array(lines).each_with_index do |line, index|
        stripped = line.to_s.strip

        depth -= 1 if end?(stripped)
        block.call(stripped, depth, index)
        depth += 1 if do?(stripped)
      end

      nil
    end

    # Returns the index of the first line where the passed block returns true
    def first(start: 0, &block)
      each_with_depth do |line, depth, index|
        next if index < start
        return index if block.call(line, depth, index)
      end
    end
    alias_method :find, :first

    # Returns the index of the last line where the passed block returns true
    def last(start: 0, &block)
      retval = nil

      each_with_depth do |line, depth, index|
        next if index < start
        retval = index if block.call(line, depth, index)
      end

      retval
    end

    # Returns an array of indexes for each line where the passed block returnst rue
    def all(start: 0, &block)
      retval = []

      each_with_depth do |line, depth, index|
        next if index < start
        retval << index if block.call(line, depth, index)
      end

      retval
    end
    alias_method :select, :all

    private

    def depth_at(line_index)
      each_with_depth { |_, depth, index| return depth if line_index == index }
    end

    def do?(content)
      content = content.kind_of?(Integer) ? lines[content] : content
      content.strip.end_with?(' do'.freeze)
    end

    def end?(content)
      content = content.kind_of?(Integer) ? lines[content] : content
      content.strip == 'end'.freeze
    end

    def whitespace?(content)
      content = content.kind_of?(Integer) ? lines[content] : content
      content.strip.length == 0
    end

    def block?(content)
      content.kind_of?(Array) && content.last.strip == 'end'.freeze
    end

    # Is the first word in each line the same?
    def same?(a, b)
      a = (a.kind_of?(Integer) ? lines[a] : a).split(' ').first
      b = (b.kind_of?(Integer) ? lines[b] : b).split(' ').first
      a == b
    end
  end
end
