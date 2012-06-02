module Titulator

  class Caption
    attr_reader :start, :stop, :text

    def initialize(start, stop, text)
      raise ArgumentError if (start <=> stop) == +1

      @start = start
      @stop  = stop
      @text  = text
    end

    def ==(other)
      start == other.start && stop == other.stop && text == other.text
    end

    def duration
      stop - start
    end

    def <=>(other)
      start <=> other.start
    end

    def +(milliTime)
      Caption.new(start+milliTime, stop+milliTime, text)
    end

    def -(milliTime)
      Caption.new(start-milliTime, stop-milliTime, text)
    end

    def to_json(*a)
      result = {}
      result[:start] = start
      result[:stop]  = stop
      result[:text]  = Iconv.conv('utf-8//ignore', 'utf-8', text)
      result.to_json(*a)
    end

    def grep(expr)
      text.downcase.include? expr.downcase
    end

    def match(expr)
      text.match expr
    end
  end

  class MilliTime
    attr_reader :millis

    def initialize(millis)
      raise ArgumentError if millis < 0
      @millis = millis
    end

    def to_i ; millis end

    def to_s
      remaining  = millis
      remaining -= (msec = remaining % 1000)
      remaining /= 1000
      remaining -= (sec = remaining % 60)
      remaining /= 60
      remaining -= (min = remaining % 60)
      remaining /= 60
      hrs        = remaining
      hrs_s      = fixed_size_num_str 2, hrs
      min_s      = fixed_size_num_str 2, min
      sec_s      = fixed_size_num_str 2, sec
      msec_s     = fixed_size_num_str 3, msec
      "#{hrs_s}:#{min_s}:#{sec_s},#{msec_s}"
    end

    def to_json(*a)
      to_s.to_json(*a)
    end

    def ==(other)
      (self <=> other) == 0
    end

    def <=>(other)
      millis <=> other.millis
    end

    def -(other)
      MilliTime.new(millis-other.millis)
    end

    def +(other)
      MilliTime.new(millis+other.millis)
    end

    def fixed_size_num_str(size, num)
      num_s   = num.to_s
      missing = size - num_s.size
      missing = 0 if missing < 1
      "#{'0'*missing}#{num_s}"
    end

    def self.from_parts(hrs, min, sec, msec)
      MilliTime.new ((((((hrs*60)+min)*60)+sec)*1000)+msec)
    end

    def self.parse(time_str)
      front, msec   = time_str.split ','
      hrs, min, sec = front.split ':'
      from_parts hrs.to_i, min.to_i, sec.to_i, msec.to_i
    end

    ZERO = MilliTime.new 0
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

    def parse_time(time_str)
      MilliTime.parse time_str
    end

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
            result << Caption.new(parse_time(start), parse_time(stop), text.join('|'))
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