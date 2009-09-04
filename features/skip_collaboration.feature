フィーチャ: SKIP連携
  SKIPのSaas提供者として
  SKIPとSKIP Wikiを連携させたい

  背景:
    前提    SKIPをOAuth Consumerとして登録する
    かつ    SKIPの"alice-api,bob-api,charls-api"のユーザ情報を同期する
    かつ    SKIPの"alice-api,bob-api"を含む"sample"グループ情報を同期する
    ならば  キーとシークレットが払い出されること

  シナリオ: 個別での登録
    もし    SKIPユーザとして"david-api"を登録する
    かつ    SKIPユーザとして"elly-api"を登録する
    かつ    SKIPユーザとして"george-api"を登録する
    かつ    "alice-api"の権限で"alice-api,david-api,elly-api"を含む"sample2"グループを登録する

  シナリオ: SKIPグループ単位で作ったWikiを閲覧できる
    前提    言語は"ja-JP"
    もし    OpenId "http://localhost:3200/user/alice-api"でログインする
    ならば "alice-api"と表示されていること

    もし    "Wikiを作る"リンクをクリックする
    かつ    "SKIPグループ"を選択する
    かつ    "note_group_backend_id"から"Sample(SKIP)"を選択する
    かつ    "ビジネス"を選択する
    かつ    "メンバーのみが読み書きできる"を選択する
    かつ    "常に表示する"を選択する
    かつ    "Wiki名"に"テスト用Wiki"と入力する
    かつ    "Wiki識別子"に"a_note"と入力する
    かつ    "Wikiの説明"に"Wikiですテストです"と入力する
    かつ    "一覧からダウンロードできる"を選択する
    かつ    "作成"ボタンをクリックする
    ならば  "テスト用Wiki"と表示されていること

    もし    "ログアウト"リンクをクリックする
    かつ    OpenId "http://localhost:3200/user/bob-api"でログインする
    ならば  "テスト用Wiki"と表示されていること

    もし    "ログアウト"リンクをクリックする
    かつ    OpenId "http://localhost:3200/user/charls-api"でログインする
    ならば  "テスト用Wiki"と表示されていないこと

  シナリオ: WikiのRSSをOAuth経由で取得できる
    前提    ユーザ"alice-api"の権限で前提処理をする
    かつ    Wiki"abc"が作成済みである
    かつ    Wiki"def"が作成済みである

    もし    ユーザ"alice-api"のOAuth AccessTokenで"WikiのRSS"を取得する
    ならば  RSSには2件のアイテムがあること
    かつ    RSSのタイトルは"Alice-apiのWiki"であること

    もし    API経由でユーザ"alice-api"の表示名を"アリスさん"に変更する
    かつ    ユーザ"alice-api"のOAuth AccessTokenで"WikiのRSS"を取得する
    ならば  RSSのタイトルは"アリスさんのWiki"であること

