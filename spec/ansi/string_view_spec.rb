require "ansi/string_view"

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
