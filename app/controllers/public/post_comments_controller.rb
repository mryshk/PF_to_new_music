class Public::PostCommentsController < ApplicationController
  def new
    @post = Post.find(params[:post_id])
    @post_comment = PostComment.new
  end

  # コメント作成
  def create
    @post = Post.find(params[:post_id])
    @comment = PostComment.new(post_comment_params)
    @comment.listener_id = current_listener.id
    @comment.post_id = @post.id
    @comment_post = @comment.post
    if @comment.save
      @comment_post.create_notification_comment!(current_listener, @comment.id)
    end
    # create.js用
    @comments = PostComment.where(post_id: @post.id, reply_comment: nil)
    @post_comment_n = PostComment.new
  end

  def show
    @post = Post.find(params[:post_id])
    @post_comment = PostComment.find(params[:id])
    @post_comment_n = PostComment.new
    @comments = PostComment.includes(:listener).where(reply_comment: @post_comment.id)
  end

  # 返信コメント作成
  def reply_create
    @post = Post.find(params[:post_id])
    @comment = PostComment.new(post_comment_params)
    @comment.listener_id = current_listener.id
    @comment.post_id = @post.id
    @comment.save!

    # reply_create.jsへ送る用 非同期通信
    @comments = PostComment.where(reply_comment: @comment.reply_comment)
    @post_comment_n = PostComment.new
    @post_comment = PostComment.find_by(id: @comment.reply_comment)
  end
  # 返信コメント削除
  def reply_destroy
    @post = Post.find(params[:post_id])
    @post_comment = PostComment.find(params[:id])
    @reply_comment = @post_comment.reply_comment
    @comment = PostComment.find_by(id: @post_comment.id, post_id: @post.id)
    @comment.destroy

    # reply_create.jsへ送る用 非同期通信
    @comments = PostComment.where(reply_comment: @reply_comment)
    @post_comment_n = PostComment.new
    @post_comment = PostComment.find_by(id: @reply_comment)
  end

  def edit
    @post = Post.find(params[:post_id])
    @post_comment = PostComment.find(params[:id])
    @comment = PostComment.find_by(id: params[:id])
  end

  def update
    @comment = PostComment.find_by(id: params[:id])
    @comment.listener_id = current_listener.id
    @comment.update(post_comment_params)
    redirect_to post_path(@comment.post)
  end

  def destroy
    @post = Post.find(params[:post_id])
    @comment = PostComment.find_by(id: params[:id], post_id: @post.id)
    @reply_comment = PostComment.where(reply_comment: @comment.id)
    @comment.destroy
    @reply_comment.destroy_all

    @comments = PostComment.where(post_id: @post.id, reply_comment: nil)
    @post_comment_n = PostComment.new
  end

  private

  def post_comment_params
    params.require(:post_comment).permit(:comment,:reply_comment)
  end
end
