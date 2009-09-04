フィーチャ: OAuthのコンシューマーの追加
  システム管理者として
  OAuthで連携するConsumerを追加したい

  シナリオ: OAuthコンシューマを登録する
    前提 言語は"ja-JP"
    かつ ユーザ"alice"を管理者として登録し、ログインする
    かつ OAuthコンシューマー登録画面を表示している

    もし "識別子"に"user-app"と入力する
    かつ "メインURL"に"http://skip.example.com"と入力する
    かつ "コールバックURL"に"http://skip.example.com/oauth/callback"と入力する
    かつ "作成"ボタンをクリックする

    ならば "user-app"と表示されていること
    かつ   "トークン"と表示されていること
    かつ   "シークレット"と表示されていること

  シナリオ: SKIPファミリのアプリケーションは非対話で認証する
    前提   言語は"ja-JP"
    かつ   ユーザ"alice"を登録し、ログインする
    かつ   SKIPファミリのコンシューマ"sample"を登録する
    かつ   Wiki"a_note"が作成済みである
    かつ   Wiki"b_note"が作成済みである

    もし   "sample"のアクセストークン取得ページを表示する
    かつ   "Authorize Access"をチェックし、アクセストークンを発行する
    かつ   OAuth経由でWikiのRSSを取得する

    ならば RSSには2件のアイテムがあること

