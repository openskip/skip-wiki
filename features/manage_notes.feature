フィーチャ: ノート管理
  ログインしたユーザは自分たちが使うノートを作成できるようにしたい

  シナリオ: ノート一覧
    前提   言語は"ja-JP"
    かつ   ユーザ"alice"を登録し、ログインする

    前提   ノート"a_note"が作成済みである
    かつ   トップページを表示している
    もし   "すべて表示"リンクをクリックする

    ならば "更新されたノート"と表示されていること
    かつ   "A note"と表示されていること
    かつ   "value for note description"と表示されていること

    もし   "A note"リンクをクリックする
    ならば "表紙"と表示されていること

  シナリオ: ノート作成
    前提   言語は"ja-JP"
    かつ   ユーザ"alice"を登録し、ログインする

    前提  "ノートを作る"リンクをクリックする

    もし  "個人用ノート"を選択する
    かつ  "ビジネス"を選択する
    かつ  "メンバーのみが読み書きできる"を選択する
    かつ  "常に表示する"を選択する
    かつ  "ノート名"に"テスト用ノート"と入力する
    かつ  "ノート識別子"に"a_note"と入力する
    かつ  "ノートの説明"に"ノートですテストです"と入力する
    かつ  "一覧からダウンロードできる"を選択する
    かつ  "作成"ボタンをクリックする

    ならば "SKIP Wikiへようこそ"と表示されていること

    もし "SKIP Wiki"リンクをクリックする
    ならば "更新されたページ"と表示されていること

    もし "テスト用ノート"リンクをクリックする
    ならば "SKIP Wikiへようこそ"と表示されていること

  シナリオ: ノート編集
    前提   言語は"ja-JP"
    かつ   ユーザ"alice"を登録し、ログインする

    前提   ノート"a_note"が作成済みである
    かつ   そのノートにはページ"FrontPage"が作成済みである
    かつ   ノート"a_note"の情報を表示している
    かつ   "ノートのプロパティを編集"リンクをクリックする

    もし   "ノート識別子"に""と入力する
    かつ   "更新"ボタンをクリックする
    ならば "エラーが発生しました"と表示されていること

    もし    "ノート識別子"に"another"と入力する
    かつ    "ノート名"に"変更後のノート"と入力する
    かつ    "表示を切り替え可能にする"を選択する
    かつ    "一覧からダウンロードできる"を選択する
    かつ    "更新"ボタンをクリックする
    ならば  "変更後のノート"と表示されていること
    かつ    "表示を切り替え可能にする"と表示されていること
    かつ    "一覧からダウンロードできる"と表示されていること
