#!/usr/bin/env ruby

$:.unshift "#{__dir__}/lib"

require "ansi/string_view"

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
