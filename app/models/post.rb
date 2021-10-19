class Post < ApplicationRecord
  attachment :picture
  belongs_to :listener
  has_many :post_comments, dependent: :destroy
  has_many :post_favorites, dependent: :destroy
  has_many :favo_users, through: :post_favorites, source: :listener
  has_many :notifications, dependent: :destroy
  has_many :tagmaps, dependent: :destroy
  has_many :tags, through: :tagmaps

  enum post_genre: { ロック: 0, JPOP: 1, アイドル: 2, EDM: 3, KPOP: 4, パンク: 5, レゲエ: 6, HIPHOP: 7 }

  # ファボモデルに自分が存在するかどうか。していたら削除。なかったら作成。
  def favorited_by?(listener)
    post_favorites.where(listener_id: listener.id).exists?
  end
  # 検索機能。投稿内容のキーワードで検索。前後関係なしにどれか一致すればヒットする。
  def self.search(keyword)
    where(post_genre: "keyword")
  end
  # 並び替え機能。プルダウンで取得した用語で並び替え内容を場合分けしている。
  def self.sort(order)
    case order
    # 新しい順
    when 'new'
      return all.order(created_at: :DESC)
    # 古い順
    when 'old'
      return all.order(creater_at: :ASC)
    # いいねが多い順
    when 'likes'
      return find(PostFavorite.group(:post_id).order('count(post_id) desc').pluck(:post_id))
    end
  end

  # 閲覧数機能の許可
  is_impressionable counter_cache: true

  def save_tag(sent_tags)
    current_tags = self.tags.pluck(:tag_name) unless self.tags.nil?
    old_tags = current_tags - sent_tags
    new_tags = sent_tags - current_tags

    old_tags.each do |old|
      self.tags.delete Tag.find_by(tag_name: old)
    end

    new_tags.each do |new|
      new_post_tag = Tag.find_or_create_by(tag_name: new)
      self.tags << new_post_tag
    end
  end

  def create_notification_by(current_listener)
    notification = current_listener.active_notifications.new(
      post_id: id,
      passive_id: listener_id,
      action: "like"
      )
      notification.save if notification.valid?
  end

  def create_notification_comment!(current_listener, post_comment_id)
    temp_ids = PostComment.select(:listener_id).where(post_id: id).where.not(listener_id: current_listener.id).distinct
    temp_ids.each do |temp_id|
      save_notification_comment!(current_listener, post_comment_id, temp_id['listener_id'] )
    end
    save_notification_comment!(current_listener, post_comment_id, listener_id) if temp_ids.blank?
  end

  def save_notification_comment!(current_listener, post_comment_id, passive_id)
    notification = current_listener.active_notifications.new(
      post_id: id,
      post_comment_id: post_comment_id,
      passive_id: passive_id,
      action: 'comment'
      )

    if notification.active_id == notification.passive_id
      notification.checked = true
    end

    notification.save if notification.valid?
  end


end
