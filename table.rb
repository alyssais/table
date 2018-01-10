#!/usr/bin/env ruby

require "rspec"

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

describe ANSI::StringView do
  let(:raw)   { "foo \c[[33mhel\c[[32ml\c[[33mlo\c[[0m bar" }
  let(:plain) { "foo helllo bar" }
  subject { described_class.new(raw) }

  describe "#length" do
    it "returns the length ignoring escape sequences" do
      expect(subject.length).to eq plain.length
    end
  end

  describe "#plain" do
    it "returns the string with escape sequences removed" do
      expect(subject.plain).to eq plain
    end
  end

  describe "#raw" do
    it "returns the string with escape sequences included" do
      expect(subject.raw).to eq raw
    end
  end

  describe "#ljust" do
    it "ignores ANSI escape sequences" do
      expect(subject.ljust(20)).to eq plain.ljust(20).gsub(plain, raw)
    end

    example { expect(described_class.new(plain).ljust(4)).to eq plain.ljust(4) }
    example { expect(described_class.new(plain).ljust(20)).to eq plain.ljust(20) }
    example { expect(described_class.new(plain).ljust(20, '1234')).to eq plain.ljust(20, '1234') }
  end

  describe "#strip" do
    it "strips start of string ignoring ANSI escape sequences" do
      expect(described_class.new(" \c[[33m test \c[[0m ").strip).to eq "\c[[33mtest\c[[0m"
    end

    example { expect(described_class.new("   hello   ").strip).to eq "hello" }
    example { expect(described_class.new("hello").strip).to eq "hello" }
    example { expect(described_class.new("\tgoodbye\r\n").strip).to eq "goodbye" }
    example { expect(described_class.new("\t\n\v\f\r \x00").strip).to eq "" }
  end

  describe "#lstrip" do
    it "strips start of string ignoring ANSI escape sequences" do
      expect(described_class.new(" \c[[33m test\c[[0m").lstrip).to eq "\c[[33mtest\c[[0m"
    end

    example { expect(described_class.new("   hello   ").lstrip).to eq "hello   " }
    example { expect(described_class.new("hello").lstrip).to eq "hello" }
    example { expect(described_class.new("\tgoodbye\r\n").lstrip).to eq "goodbye\r\n" }
    example { expect(described_class.new("\t\n\v\f\r \x00").lstrip).to eq "\x00" }
  end

  describe "#rstrip" do
    it "strips start of string ignoring ANSI escape sequences" do
      expect(described_class.new("\c[[33mtest \c[[0m ").rstrip).to eq "\c[[33mtest\c[[0m"
    end

    example { expect(described_class.new("   hello   ").rstrip).to eq "   hello" }
    example { expect(described_class.new("hello").rstrip).to eq "hello" }
    example { expect(described_class.new("\tgoodbye\r\n").rstrip).to eq "\tgoodbye" }
    example { expect(described_class.new("\t\n\v\f\r \x00").rstrip).to eq "" }
  end

  describe "#slice" do
    it "indexes into string, including leading and trailing escape sequences" do
      expect(subject.slice(5, 3)).to eq "\c[[33mel\c[[32ml\c[[33ml\c[[0m"
    end
  end
end

def main
  table = ARGF.each_line.map { |l| l.chomp.split("\t").map { |cell| ANSI::StringView.new(cell).rstrip } }

  width = table.map(&:size).max
  column_widths = Array.new(width) { |i|
    table
      .map { |row| row[i] }
      .compact
      .map { |cell| ANSI::StringView.new(cell).length }
      .max
  }

  table.each do |row|
    puts row.zip(column_widths).map { |cell, width| ANSI::StringView.new(cell).ljust(width) }.join("  ")
  end
end


main unless File.basename($0) == "rspec"
