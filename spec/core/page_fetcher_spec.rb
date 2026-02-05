# frozen_string_literal: true

require "ostruct"

RSpec.describe Chikuden::Core::PageFetcher do
  let(:store) { Chikuden::Store::Memory.new(ttl: 300, max_ids: 1000) }
  let(:ids) { [3, 1, 4, 1, 5, 9, 2, 6, 5, 3] }
  let(:cursor) { Chikuden::Core::Cursor.create(ids, total_count: 10, store: store) }
  let(:snapshot) { Chikuden::Core::Snapshot.new(cursor, store: store) }

  # Mock model class
  let(:model_class) do
    Class.new do
      attr_accessor :id

      def initialize(id)
        @id = id
      end

      def self.where(conditions)
        MockRelation.new(conditions[:id])
      end
    end
  end

  let(:fetcher) { described_class.new(snapshot: snapshot, model_class: model_class, store: store) }

  # Mock relation for where().to_a
  class MockRelation
    def initialize(ids)
      @ids = ids
    end

    def to_a
      # Simulate database returning records in arbitrary order
      @ids.uniq.sort.reverse.map { |id| OpenStruct.new(id: id) }
    end
  end

  describe "#fetch" do
    it "returns a Result struct" do
      result = fetcher.fetch(page: 1, per_page: 3)

      expect(result).to be_a(Chikuden::Core::PageFetcher::Result)
      expect(result.total_count).to eq(10)
      expect(result.cursor_id).to eq(cursor.id)
      expect(result.page).to eq(1)
      expect(result.per_page).to eq(3)
    end

    it "fetches records in correct order" do
      result = fetcher.fetch(page: 1, per_page: 3)

      # IDs should be [3, 1, 4] from the first page
      expect(result.records.map(&:id)).to eq([3, 1, 4])
    end

    it "handles page 0 as page 1" do
      result = fetcher.fetch(page: 0, per_page: 3)
      expect(result.page).to eq(1)
    end

    it "handles negative page as page 1" do
      result = fetcher.fetch(page: -1, per_page: 3)
      expect(result.page).to eq(1)
    end
  end

  describe "Result" do
    let(:result) { fetcher.fetch(page: 2, per_page: 3) }

    it "#total_pages calculates correctly" do
      expect(result.total_pages).to eq(4) # ceil(10/3)
    end

    it "#next_page? returns correctly" do
      expect(result.next_page?).to be true
    end

    it "#prev_page? returns correctly" do
      expect(result.prev_page?).to be true
    end

    it "#first_page? returns correctly" do
      expect(result.first_page?).to be false
      expect(fetcher.fetch(page: 1, per_page: 3).first_page?).to be true
    end

    it "#last_page? returns correctly" do
      expect(result.last_page?).to be false
      expect(fetcher.fetch(page: 4, per_page: 3).last_page?).to be true
    end

    it "#offset calculates correctly" do
      expect(result.offset).to eq(3) # (2-1) * 3
    end
  end

  describe "deleted record backfill" do
    # Model class that simulates deleted records
    let(:model_with_deleted) do
      deleted_ids = [1, 4] # These IDs are "deleted"
      Class.new do
        @deleted_ids = deleted_ids

        class << self
          attr_accessor :deleted_ids
        end

        def self.where(conditions)
          MockRelationWithDeleted.new(conditions[:id], @deleted_ids)
        end
      end
    end

    let(:fetcher_with_deleted) do
      described_class.new(snapshot: snapshot, model_class: model_with_deleted, store: store)
    end

    it "backfills when records are deleted" do
      # IDs are [3, 1, 4, 1, 5, 9, 2, 6, 5, 3]
      # Deleted: 1, 4
      # First batch (offset=0, limit=3): [3, 1, 4]
      # After DB query: [3] (1 and 4 deleted)
      # remove_ids removes 1 and 4 from cache: [3, 5, 9, 2, 6, 5, 3]
      # Need 2 more, next batch (offset=3, limit=2): [2, 6] (from new array index 3)
      # After DB query: [2, 6] (not deleted)
      # Total: [3, 2, 6]
      result = fetcher_with_deleted.fetch(page: 1, per_page: 3)

      expect(result.records.map(&:id)).to eq([3, 2, 6])
      expect(result.records.size).to eq(3)
    end

    it "updates total_count when records are deleted" do
      fetcher_with_deleted.fetch(page: 1, per_page: 3)

      # Deleted IDs detected during fetch: 1, 4
      # Original total: 10, decremented by 2 = 8
      new_total = store.total_count(cursor.id)
      expect(new_total).to eq(8)
    end

    it "removes deleted IDs from cache" do
      fetcher_with_deleted.fetch(page: 1, per_page: 3)

      # IDs 1 and 4 should be removed from cache
      remaining_ids = store.fetch_page(cursor.id, offset: 0, limit: 20)
      expect(remaining_ids).not_to include(1)
      expect(remaining_ids).not_to include(4)
    end
  end
end

# Mock relation that simulates deleted records
class MockRelationWithDeleted
  def initialize(ids, deleted_ids)
    @ids = ids
    @deleted_ids = deleted_ids
  end

  def to_a
    @ids.reject { |id| @deleted_ids.include?(id) }
        .uniq
        .map { |id| OpenStruct.new(id: id) }
  end
end
