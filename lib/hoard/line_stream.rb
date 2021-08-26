module Hoard
  # Represents a multiline string as a stream of lines for processing
  class LineStream
    def initialize(value)
      @lines = value.split("\n")
      @index = 0
    end

    def peek_line
      @lines[@index]
    end

    def read_line
      peek_line.tap { next_line }
    end

    def next_line
      @index += 1
    end
  end
end
