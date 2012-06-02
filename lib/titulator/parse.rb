module Titulator

  class Caption
    attr_reader :start, :stop, :text

    def initialize(start, stop, text)
      @start = start
      @stop  = stop
      @text  = text
    end
  end

  class Parser
    attr_reader :data

    def initialize(raw)
      @data = parse_raw raw
    end

    def to_a ; data end

    def self.parse(format, raw)
      clazz = case format
              when :srt then SrtParser
              else
                raise ArgumentError, "Unsupported format: #{format}"
              end
      clazz.new(raw).to_a
    end
  end

  class SrtParser < Parser

    def parse_raw(raw)
      result = []
      start  = nil
      stop   = nil
      text   = []
      expect = :counter
      StringIO.new(raw).each_line do |line|
        line.strip!
        case expect
        when :counter
          begin
            line.to_i
            expect = :times
          rescue
          end
        when :times
          start, stop = line.split('-->').map { |t| t.strip }
          expect = :text
        when :text
          if line.size == 0
            result << Caption.new(start, stop, text.join('|'))
            text   = []
            start  = nil
            stop   = nil
            expect = :counter
          else
            text << line
          end
        end
      end
      result
    end
  end
end