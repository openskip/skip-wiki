フィーチャ: SKIP連携
  SKIPのSaas提供者として
  SKIPとSKIP Wikiを連携させたい

  背景:
    前提    SKIPをOAuth Consumerとして登録する
    かつ    SKIPユーザとして"alice-api"を登録する
    かつ    SKIPユーザとして"bob-api"を登録する
    かつ    SKIPユーザとして"charls-api"を登録する
    かつ    SKIPグループとして"alice-api,bob-api"を含む"sample"グループを登録する

  シナリオ: SKIPのOAuth Consumer登録
    ならば  SKIPが"wiki"にアクセスするためのキーとシークレットが払い出されること

  シナリオ: SKIPグループ単位で作ったノートを閲覧できる
    前提    言語は"ja-JP"
    もし    OpenId "http://localhost:3200/user/alice-api"でログインする
    ならば "alice-api"と表示されていること

    もし    "ノートを作る"リンクをクリックする
    かつ    "SKIPグループ"を選択する
    かつ    "note_group_backend_id"から"Sample(SKIP)"を選択する
    かつ    "ビジネス"を選択する
    かつ    "メンバーのみが読み書きできる"を選択する
    かつ    "常に表示する"を選択する
    かつ    "ノート名"に"テスト用ノート"と入力する
    かつ    "ノート識別子"に"a_note"と入力する
    かつ    "ノートの説明"に"ノートですテストです"と入力する
    かつ    "一覧からダウンロードできる"を選択する
    かつ    "作成"ボタンをクリックする
    ならば  "テスト用ノート"と表示されていること

    もし    "ログアウト"リンクをクリックする
    かつ    OpenId "http://localhost:3200/user/bob-api"でログインする
    ならば  "テスト用ノート"と表示されていること

    もし    "ログアウト"リンクをクリックする
    かつ    OpenId "http://localhost:3200/user/charls-api"でログインする
    ならば  "テスト用ノート"と表示されていないこと

  シナリオ: ノートのRSSをOAuth経由で取得できる
    前提    ユーザ"alice-api"の権限で前提処理をする
    かつ    ノート"abc"が作成済みである
    かつ    ノート"def"が作成済みである

    もし    ユーザ"alice-api"のOAuth AccessTokenで"ノートのRSS"を取得する
    ならば  2件のアイテムがあること
