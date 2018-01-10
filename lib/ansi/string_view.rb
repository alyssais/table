module ANSI
  CSI_SEQUENCE = /
    \c[\[         # command sequence initiator
    [\x30-\x3F]*  # any number of parameter bytes
    [\x20-\x2F]*  # any number of intermediate bytes
    [\x40-\x7E]   # final byte
  /x

  class StringView
    attr_reader :raw

    def initialize(raw)
      @raw = raw.dup.freeze
      freeze
    end

    def plain
      raw.gsub(CSI_SEQUENCE, "")
    end

    def length
      plain.length
    end

    def ljust(length, padding = " ")
      result = raw.dup
      result << padding until StringView.new(result).length >= length
      StringView.new(result).slice(0, [length, self.length].max - 1)
    end

    def strip
      StringView.new(lstrip).rstrip
    end

    def lstrip
      non_whitespace = /[^\t\n\v\f\r ]/
      start = plain.index(non_whitespace)
      slice(start, length - 1)
    end

    def rstrip
      non_whitespace = /[^\0\t\n\v\f\r ]/
      last = plain.rindex(non_whitespace)
      slice(0, last)
    end

    def slice(start, length)
      tokenizer = each_token
      result = String.new

      token = tokenizer.next

      until token.type == :printable && token.index >= start
        result << token.value if token.type == :csi
        token = tokenizer.next
      end

      until token.type != :csi && token.index > start + length
        result << token.value
        token = tokenizer.next
      end

      token = tokenizer.next until token.type == :csi

      result << token.value
    rescue StopIteration
    ensure
      return result
    end

    private

    class Token < Struct.new(:type, :value, :index)
    end
    private_constant :Token

    def each_token(&block)
      escapes = raw.scan(CSI_SEQUENCE)
      tokens  = raw.scan(/#{CSI_SEQUENCE}|(.)/m).map(&:first)

      last_printable_token_index = -1
      last_csi_token_index = -1
      tokenizer = tokens.lazy.map do |token|
        token_type = token.nil? ? :csi : :printable
        token_index = token_type == :csi ? last_csi_token_index += 1 : last_printable_token_index += 1
        token_value = token_type == :csi ? escapes.fetch(token_index) : token
        Token.new(token_type, token_value, token_index)
      end
      tokenizer.each(&block)
    end
  end
end
