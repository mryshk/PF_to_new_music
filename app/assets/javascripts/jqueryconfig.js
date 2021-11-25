/* global $ */

$(function(){
  $('#form').validate({
    rules:{
      "post[post_tweet]": {
        required: true,
        maxlength: 140
      },
      "post[post_url]": {
        required: true,
      },
      "album[name]": {
        required: true,
      },
      "album[album_url]": {
        required: true,
      }
    },
    messages: {
      "post[post_tweet]": {
        required: "投稿文を入力してください。"
      },
      "post[post_url]": {
        required: "音楽のURL（Youtubeや音楽サブスク等）を入力してください。"
      },
      "album[name]": {
        required: "アルバム名を入力してください。"
      },
      "album[album_url]":{
        required: "アルバムのURL（Youtubeや音楽サブスク等）を入力してください。"
      },
    },
    errorClass: "invalid",
    errorElement: "p",
    validClass: "valid",
  });
});