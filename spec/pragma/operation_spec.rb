require "spec_helper"

describe Pragma::Operation do
  it "has a version number" do
    expect(Pragma::Operation::VERSION).not_to be nil
  end

  it "does something useful" do
    expect(false).to eq(true)
  end
end
