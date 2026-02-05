# frozen_string_literal: true

RSpec.describe Chikuden::Core::Snapshot do
  let(:store) { Chikuden::Store::Memory.new(ttl: 300, max_ids: 1000) }
  let(:ids) { (1..100).to_a }
  let(:cursor) { Chikuden::Core::Cursor.create(ids, total_count: 100, store: store) }
  let(:snapshot) { described_class.new(cursor, store: store) }

  describe "#page_ids" do
    it "returns IDs for first page" do
      result = snapshot.page_ids(page: 1, per_page: 10)
      expect(result).to eq((1..10).to_a)
    end

    it "returns IDs for middle page" do
      result = snapshot.page_ids(page: 5, per_page: 10)
      expect(result).to eq((41..50).to_a)
    end

    it "returns IDs for last page" do
      result = snapshot.page_ids(page: 10, per_page: 10)
      expect(result).to eq((91..100).to_a)
    end

    it "returns empty array for out of range page" do
      result = snapshot.page_ids(page: 11, per_page: 10)
      expect(result).to eq([])
    end
  end

  describe "#total_count" do
    it "returns the total count" do
      expect(snapshot.total_count).to eq(100)
    end
  end

  describe "#total_pages" do
    it "calculates total pages" do
      expect(snapshot.total_pages(per_page: 10)).to eq(10)
      expect(snapshot.total_pages(per_page: 25)).to eq(4)
      expect(snapshot.total_pages(per_page: 30)).to eq(4)
    end
  end

  describe "#next_page?" do
    it "returns true when there are more pages" do
      expect(snapshot.next_page?(page: 1, per_page: 10)).to be true
      expect(snapshot.next_page?(page: 9, per_page: 10)).to be true
    end

    it "returns false on last page" do
      expect(snapshot.next_page?(page: 10, per_page: 10)).to be false
    end
  end

  describe "#prev_page?" do
    it "returns false on first page" do
      expect(snapshot.prev_page?(page: 1)).to be false
    end

    it "returns true after first page" do
      expect(snapshot.prev_page?(page: 2)).to be true
      expect(snapshot.prev_page?(page: 10)).to be true
    end
  end

  describe "#cursor_id" do
    it "returns the cursor ID" do
      expect(snapshot.cursor_id).to eq(cursor.id)
    end
  end
end
