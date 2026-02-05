# frozen_string_literal: true

RSpec.describe Chikuden::Core::Cursor do
  let(:store) { Chikuden::Store::Memory.new(ttl: 300, max_ids: 1000) }
  let(:ids) { [1, 2, 3, 4, 5] }

  before do
    Chikuden.store = store
  end

  describe ".create" do
    it "creates a new cursor with IDs" do
      cursor = described_class.create(ids, total_count: 100, store: store)

      expect(cursor.id).to be_a(String)
      expect(cursor.id.length).to be > 10
    end

    it "stores IDs in the store" do
      cursor = described_class.create(ids, total_count: 100, store: store)

      expect(store.exists?(cursor.id)).to be true
      expect(store.total_count(cursor.id)).to eq(100)
    end

    it "uses ids.size as default total_count" do
      cursor = described_class.create(ids, store: store)

      expect(store.total_count(cursor.id)).to eq(5)
    end
  end

  describe ".find" do
    it "returns cursor for existing ID" do
      created = described_class.create(ids, store: store)
      found = described_class.find(created.id, store: store)

      expect(found).to be_a(described_class)
      expect(found.id).to eq(created.id)
    end

    it "returns nil for non-existent ID" do
      result = described_class.find("nonexistent", store: store)
      expect(result).to be_nil
    end

    it "returns nil for nil ID" do
      result = described_class.find(nil, store: store)
      expect(result).to be_nil
    end

    it "returns nil for empty ID" do
      result = described_class.find("", store: store)
      expect(result).to be_nil
    end
  end

  describe ".find!" do
    it "returns cursor for existing ID" do
      created = described_class.create(ids, store: store)
      found = described_class.find!(created.id, store: store)

      expect(found.id).to eq(created.id)
    end

    it "raises CursorExpired for non-existent ID" do
      expect {
        described_class.find!("nonexistent", store: store)
      }.to raise_error(Chikuden::CursorExpired)
    end
  end

  describe "#exists?" do
    it "returns true for existing cursor" do
      cursor = described_class.create(ids, store: store)
      expect(cursor.exists?(store: store)).to be true
    end
  end

  describe "#total_count" do
    it "returns the total count" do
      cursor = described_class.create(ids, total_count: 100, store: store)
      expect(cursor.total_count(store: store)).to eq(100)
    end
  end

  describe "#delete" do
    it "deletes the cursor" do
      cursor = described_class.create(ids, store: store)
      cursor.delete(store: store)

      expect(store.exists?(cursor.id)).to be false
    end
  end

  describe "#touch" do
    it "refreshes TTL" do
      cursor = described_class.create(ids, store: store)
      expect(cursor.touch(store: store)).to be true
    end
  end
end
