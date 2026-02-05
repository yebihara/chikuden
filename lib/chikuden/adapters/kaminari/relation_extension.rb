# frozen_string_literal: true

module Chikuden
  module Adapters
    module Kaminari
      # Extension for ActiveRecord::Relation when used with Kaminari
      module RelationExtension
        attr_accessor :chikuden_cursor_id, :chikuden_enabled, :chikuden_total_count

        def records
          if @chikuden_enabled
            load_with_chikuden
          else
            super
          end
        end

        def total_count(column_name = :all, _options = nil)
          if @chikuden_enabled
            load_with_chikuden unless @chikuden_loaded
            @chikuden_total_count || super
          else
            super
          end
        end

        private

        def load_with_chikuden
          return @records if @chikuden_loaded

          cursor_id = Chikuden::Current.cursor_id
          page_num = current_page || 1
          per_page = limit_value || ::Kaminari.config.default_per_page
          store = Chikuden.store

          cursor = Chikuden::Core::Cursor.find(cursor_id, store: store) if cursor_id.present?

          if cursor
            @records = load_from_cursor(cursor, page_num, per_page, store)
            @chikuden_cursor_id = cursor.id
          else
            @records = load_with_new_cursor(page_num, per_page, store)
          end

          @chikuden_loaded = true
          @records
        end

        def load_from_cursor(cursor, page_num, per_page, store)
          snapshot = Chikuden::Core::Snapshot.new(cursor, store: store)
          fetcher = Chikuden::Core::PageFetcher.new(snapshot: snapshot, model_class: klass, store: store)
          result = fetcher.fetch(page: page_num, per_page: per_page)

          @chikuden_total_count = result.total_count
          @total_count = result.total_count  # Kaminari用
          result.records
        end

        def load_with_new_cursor(page_num, per_page, store)
          base_scope = except(:limit, :offset)
          all_ids = base_scope.pluck(:id)
          total = all_ids.size

          cursor = Chikuden::Core::Cursor.create(all_ids, total_count: total, store: store)
          @chikuden_cursor_id = cursor.id
          @chikuden_total_count = total
          @total_count = total  # Kaminari用

          snapshot = Chikuden::Core::Snapshot.new(cursor, store: store)
          fetcher = Chikuden::Core::PageFetcher.new(snapshot: snapshot, model_class: klass, store: store)
          result = fetcher.fetch(page: page_num, per_page: per_page)

          result.records
        end
      end
    end
  end
end
