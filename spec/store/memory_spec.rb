# frozen_string_literal: true

RSpec.describe Chikuden::Store::Memory do
  let(:store) { described_class.new(ttl: 300, max_ids: 1000) }
  let(:cursor_id) { "test_cursor_123" }
  let(:ids) { [1, 2, 3, 4, 5, 6, 7, 8, 9, 10] }

  describe "#store" do
    it "stores IDs and returns true" do
      expect(store.store(cursor_id, ids, total_count: 100)).to be true
    end

    it "truncates IDs if exceeding max_ids" do
      small_store = described_class.new(ttl: 300, max_ids: 5)
      small_store.store(cursor_id, ids, total_count: 100)

      expect(small_store.stored_count(cursor_id)).to eq(5)
    end
  end

  describe "#fetch_page" do
    before { store.store(cursor_id, ids, total_count: 100) }

    it "returns IDs for the requested page" do
      result = store.fetch_page(cursor_id, offset: 0, limit: 3)
      expect(result).to eq([1, 2, 3])
    end

    it "returns IDs with offset" do
      result = store.fetch_page(cursor_id, offset: 5, limit: 3)
      expect(result).to eq([6, 7, 8])
    end

    it "returns empty array for out of range offset" do
      result = store.fetch_page(cursor_id, offset: 100, limit: 3)
      expect(result).to eq([])
    end

    it "raises CursorExpired for non-existent cursor" do
      expect {
        store.fetch_page("nonexistent", offset: 0, limit: 3)
      }.to raise_error(Chikuden::CursorExpired)
    end
  end

  describe "#total_count" do
    before { store.store(cursor_id, ids, total_count: 100) }

    it "returns the total count" do
      expect(store.total_count(cursor_id)).to eq(100)
    end

    it "raises CursorExpired for non-existent cursor" do
      expect {
        store.total_count("nonexistent")
      }.to raise_error(Chikuden::CursorExpired)
    end
  end

  describe "#exists?" do
    it "returns true for existing cursor" do
      store.store(cursor_id, ids, total_count: 100)
      expect(store.exists?(cursor_id)).to be true
    end

    it "returns false for non-existent cursor" do
      expect(store.exists?("nonexistent")).to be false
    end
  end

  describe "#delete" do
    before { store.store(cursor_id, ids, total_count: 100) }

    it "deletes the cursor and returns true" do
      expect(store.delete(cursor_id)).to be true
      expect(store.exists?(cursor_id)).to be false
    end

    it "returns false for non-existent cursor" do
      expect(store.delete("nonexistent")).to be false
    end
  end

  describe "#touch" do
    before { store.store(cursor_id, ids, total_count: 100) }

    it "refreshes TTL and returns true" do
      expect(store.touch(cursor_id)).to be true
    end

    it "returns false for non-existent cursor" do
      expect(store.touch("nonexistent")).to be false
    end
  end

  describe "expiration" do
    it "expires data after TTL" do
      expired_store = described_class.new(ttl: 0, max_ids: 1000)
      expired_store.store(cursor_id, ids, total_count: 100)

      sleep(0.01)

      expect(expired_store.exists?(cursor_id)).to be false
    end
  end
end
