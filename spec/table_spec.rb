require "open3"

describe "table" do
  it "can handle no input" do
    result, status = Open3.capture2("#{__dir__}/../exe/table", stdin_data: "")
    expect(status).to be_success
    expect(result).to be_empty
  end

  it "puts things into columns" do
    result, status = Open3.capture2("#{__dir__}/../exe/table", stdin_data: "foo\tbar\n1\t2")
    expect(status).to be_success
    expect(result).to eq <<~TABLE
      foo  bar
      1    2  
    TABLE
  end
end
