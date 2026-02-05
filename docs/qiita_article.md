---
title: kaminariのページネーションを高速化するgem「chikuden」を作った
tags: Ruby Rails kaminari pagination gem
---

## はじめに

Railsでページネーションといえば[kaminari](https://github.com/kaminari/kaminari)が定番ですが、大量のデータを扱う際にパフォーマンスの問題に直面することがあります。

今回、kaminariのアドオンとして動作する **chikuden**（蓄電）というgemを作成しました。最初のページアクセス時にレコードIDをキャッシュし、2ページ目以降のナビゲーションを高速化します。

https://github.com/xxx/chikuden

## 背景：kaminariの課題

kaminariは `LIMIT / OFFSET` 方式でページネーションを実現しています。

```ruby
# 1ページ目
SELECT * FROM users ORDER BY name LIMIT 10 OFFSET 0;
SELECT COUNT(*) FROM users;

# 2ページ目
SELECT * FROM users ORDER BY name LIMIT 10 OFFSET 10;
SELECT COUNT(*) FROM users;

# 3ページ目
SELECT * FROM users ORDER BY name LIMIT 10 OFFSET 20;
SELECT COUNT(*) FROM users;
```

この方式には以下の課題があります：

### 1. OFFSET が大きくなるほど遅くなる

`OFFSET 10000` のようなクエリは、データベースが最初の10,000行をスキャンしてから捨てる必要があります。100ページ目を表示するのに、1ページ目の100倍の時間がかかることも珍しくありません。

```sql
-- 1ページ目: 高速
SELECT * FROM users ORDER BY name LIMIT 20 OFFSET 0;

-- 500ページ目: 非常に遅い（9980行をスキャンして捨てる）
SELECT * FROM users ORDER BY name LIMIT 20 OFFSET 9980;
```

### 2. ページ移動のたびにクエリが実行される

ユーザーがページを移動するたびに、同じ `ORDER BY` 句を含むクエリが繰り返し実行されます。

### 4. COUNT クエリのコスト

ページネーションリンクを表示するには総ページ数が必要なため、毎回 `COUNT(*)` クエリが実行されます。テーブルサイズや WHERE 句の条件、インデックス設計によっては、これが無視できないコストになります。

### 5. ページ間でのデータ不整合

ユーザーが1ページ目を見ている間に新しいレコードが追加されると、2ページ目に移動した際に同じレコードが重複表示されたり、逆にレコードが飛ばされたりする可能性があります。

## chikuden の仕組み

chikuden は「蓄電」の名の通り、最初のアクセス時にデータを蓄えて再利用します。

```
【1ページ目のアクセス】
1. SELECT id FROM users ORDER BY name;  -- 全IDを取得
2. IDリスト + ORDER BY情報をキャッシュに保存
3. SELECT * FROM users WHERE id IN (1,2,3...) ORDER BY name;  -- 該当ページのレコード取得

【2ページ目以降のアクセス】（cursor_id パラメータ付き）
1. キャッシュからIDリストを取得
2. SELECT * FROM users WHERE id IN (11,12,13...) ORDER BY name;  -- 該当ページのレコード取得のみ
```

### メリット

- **クエリ数の削減**: 2ページ目以降は1クエリのみ
- **クエリ性能の劇的な改善**: `WHERE id IN (...)` は主キー検索なので、ページ位置に関係なく常に高速。従来の `LIMIT/OFFSET` 方式では後半のページほど遅くなる問題がありましたが、chikuden ではどのページも同じ速度で取得できます
- **COUNT クエリの排除**: キャッシュされた件数を使用
- **データの一貫性**: ページ間で同じスナップショットを参照

## インストール

```ruby
# Gemfile
gem 'kaminari'
gem 'chikuden'
```

```bash
bundle install
```

## 使い方

### 基本的な使い方

コントローラーに `chikuden` を追加するだけです：

```ruby
class UsersController < ApplicationController
  chikuden only: [:index]

  def index
    @users = User.order(:name).page(params[:page]).per(20)
  end
end
```

ビューは通常のkaminariと同じです：

```erb
<% @users.each do |user| %>
  <%= user.name %>
<% end %>

<%= paginate @users %>
```

### cursor_id の表示（オプション）

デバッグや確認のために cursor_id を表示することもできます：

```erb
<% if @users.respond_to?(:chikuden_cursor_id) && @users.chikuden_cursor_id %>
  <p>Cursor: <%= @users.chikuden_cursor_id %></p>
<% end %>
```

### 設定のカスタマイズ

```ruby
# config/initializers/chikuden.rb
Chikuden.configure do |config|
  config.ttl = 30.minutes          # キャッシュの有効期限（デフォルト: 30分）
  config.max_cached_ids = 10_000   # キャッシュするIDの最大数（デフォルト: 10,000）
end
```

## 発行されるクエリの比較

### kaminari のみ

```
# 1ページ目
User Load (2.1ms)  SELECT "users".* FROM "users" ORDER BY "users"."name" LIMIT 10 OFFSET 0
User Count (1.5ms)  SELECT COUNT(*) FROM "users"

# 2ページ目
User Load (2.3ms)  SELECT "users".* FROM "users" ORDER BY "users"."name" LIMIT 10 OFFSET 10
User Count (1.4ms)  SELECT COUNT(*) FROM "users"
```

### kaminari + chikuden

```
# 1ページ目
User Pluck (0.5ms)  SELECT "users"."id" FROM "users" ORDER BY "users"."name"
User Load (0.1ms)  SELECT "users".* FROM "users" WHERE "users"."id" IN (31, 133, ...) ORDER BY "users"."name"

# 2ページ目（cursor_id付き）
User Load (0.1ms)  SELECT "users".* FROM "users" WHERE "users"."id" IN (160, 186, ...) ORDER BY "users"."name"
```

2ページ目以降では **1クエリのみ** で、COUNT クエリも発行されません。

## 内部実装のポイント

### 1. ORDER BY 情報のキャッシュ

IDだけでなく、ORDER BY 句の情報もキャッシュに保存します。これにより、2ページ目以降でも正しいソート順を維持できます。

```ruby
# キャッシュされるデータ
{
  ids: [31, 133, 174, 71, ...],
  total_count: 200,
  order: [["name", :asc]],
  created_at: "2024-01-01T00:00:00Z"
}
```

### 2. kaminari との統合

kaminari の `page` メソッドをラップし、chikuden が有効な場合は独自のロジックを挿入します。既存のkaminariコードを変更する必要はありません。

### 3. Rails.cache の活用

キャッシュバックエンドには `Rails.cache` を使用します。Redis、Memcached、ファイルキャッシュなど、Railsがサポートする任意のキャッシュストアを使用できます。

```ruby
# config/environments/production.rb
config.cache_store = :redis_cache_store, { url: ENV['REDIS_URL'] }
```

## 注意点・制限事項

### 1. スナップショットの特性

chikuden はキャッシュ作成時点のスナップショットを使用します。キャッシュ有効期間中に追加・削除されたレコードは反映されません。これはSalesforceのリストビューと同様の動作で、意図的な設計です。

### 2. メモリ使用量

大量のレコードがある場合、IDリストのキャッシュサイズに注意してください。`max_cached_ids` 設定で上限を設定できます。

### 3. 複雑な ORDER BY

現在、シンプルなカラム指定（`order(:name)` や `order(name: :desc)`）に対応しています。関数やサブクエリを含む複雑な ORDER BY 句は正しく処理できない場合があります。

## ユースケース

chikuden が特に効果的なケース：

- 管理画面のリスト表示
- 検索結果のページネーション
- データの一貫性が重要なレポート画面
- COUNT クエリがボトルネックになっている画面

## まとめ

chikuden は kaminari に「蓄電」機能を追加し、ページネーションのパフォーマンスを向上させるgemです。

- 既存のkaminariコードを最小限の変更で高速化
- 2ページ目以降のクエリを1つに削減
- COUNT クエリを排除
- ページ間でのデータ一貫性を保証

ぜひ試してみてください。フィードバックやPRをお待ちしています。

## 参考

- [kaminari](https://github.com/kaminari/kaminari) - Railsのページネーションgem
- [Keyset Pagination](https://use-the-index-luke.com/no-offset) - OFFSET の問題と代替手法
