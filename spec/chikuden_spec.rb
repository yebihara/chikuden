# frozen_string_literal: true

RSpec.describe Chikuden do
  it "has a version number" do
    expect(Chikuden::VERSION).not_to be_nil
  end

  describe ".config" do
    it "returns a Configuration instance" do
      expect(Chikuden.config).to be_a(Chikuden::Configuration)
    end

    it "has default values" do
      expect(Chikuden.config.ttl).to eq(30 * 60)
      expect(Chikuden.config.max_ids).to eq(100_000)
      expect(Chikuden.config.cursor_param).to eq(:cursor_id)
    end
  end

  describe ".configure" do
    it "yields the configuration" do
      Chikuden.configure do |config|
        config.ttl = 60 * 60
      end

      expect(Chikuden.config.ttl).to eq(60 * 60)
    end
  end

  describe ".store" do
    it "returns a store instance" do
      expect(Chikuden.store).to be_a(Chikuden::Store::Base)
    end
  end
end
