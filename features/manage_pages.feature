フィーチャ: ページ管理
  ログインしたユーザは自分たちが使うページを作成できるようにしたい

  背景:
    前提   言語は"ja-JP"
    かつ   ユーザ"alice"を登録し、ログインする
    かつ   ノート"a_note"が作成済みである
    かつ   そのノートにはラベル"Labelindice"が作成済みである
    かつ   ノート"a_note"のページ"FrontPage"を表示している

    もし   ノートメニューの"新しいページを作る"リンクをクリックする
    ならば "新しいページを作る"と表示されていること

    もし   "ページ名"に"ページ「い」"と入力する
    かつ   "ページ識別子"に"page_1"と入力する
    かつ   "内容"に"これはテストページです"と入力する
    かつ   "Labelindice"を選択する
    かつ   "ページを作成"ボタンをクリックする

  シナリオ: ページ作成
    もし   ノート"a_note"のページ"page_1"を表示している

    ならば "ページ「い」"と表示されていること
    かつ   "これはテストページです"と表示されていること
    かつ   "Labelindice"と表示されていること
    かつ   "編集"と表示されていること

    もし "ページ一覧"リンクをクリックする
    ならば "ページ「い」"と表示されていること

  シナリオ: ページの論理削除
    前提    ノート"a_note"のページ"page_1"を表示している
    もし    "削除"ボタンをクリックする
    ならば  flashメッセージに"ページを削除しました。"と表示されていること
    かつ    "ページ一覧"と表示されていること
    かつ    "ページ「い」"と表示されていること
    かつ    "削除済み"と表示されていること

    もし    ノート"a_note"のページ"page_1"を表示している
    ならば "ページが存在しない、またはアクセスする権限がありません。"と表示されていること

    もし    ノート"a_note"のページ"FrontPage"を表示している
    かつ    "ページ一覧"リンクをクリックする
    ならば  "ページ「い」"と表示されていること
    かつ    "削除済み"と表示されていること

    もし    "ページを復旧する"リンクをクリックする
    かつ    "ページを復旧する"ボタンをクリックする
    ならば  flashメッセージに"ページを復旧しました。"と表示されていること
    かつ    "ページ「い」"と表示されていること
    かつ    "削除済み"と表示されていないこと

  シナリオ: ページの一覧
    前提   ノート"a_note"のページ"FrontPage"を表示している
    かつ   "ログアウト"リンクをクリックする

    かつ   ユーザ"bob"を登録し、ログインする
    かつ   そのノートにはページ"SecondPage"が作成済みである
    かつ   そのページはラベル"Labelindice"と関連付けられている
    かつ   OpenId "http://localhost:3200/user/alice"でログインする
    かつ   ノート"a_note"のページ"FrontPage"を表示している

    もし   "ページ一覧"リンクをクリックする
    ならば "表紙"と表示されていること
    かつ   "Secondpage"と表示されていること

    もし   "ページ内のキーワード"に"SKIP Wikiへようこそ"と入力する
    かつ   "絞り込み"ボタンをクリックする
    ならば "表紙"と表示されていること
    かつ   "Secondpage"と表示されていないこと

    もし   "ページ内のキーワード"に""と入力する
    かつ   "最終更新者"に"alice"と入力する
    かつ   "絞り込み"ボタンをクリックする
    ならば "表紙"と表示されていること
    かつ   "Secondpage"と表示されていないこと

    もし   "ページ内のキーワード"に"SKIP Wikiへようこそ"と入力する
    かつ   "最終更新者"に"bob"と入力する
    かつ   "絞り込み"ボタンをクリックする
    ならば "表紙"と表示されていないこと
    かつ   "Secondpage"と表示されていないこと

    もし   "ページ内のキーワード"に""と入力する
    かつ   "最終更新者"に""と入力する
    かつ   "ラベル識別子"から"ラベルなし"を選択する
    かつ   "絞り込み"ボタンをクリックする
    ならば "表紙"と表示されていること
    かつ   "Secondpage"と表示されていないこと

  シナリオ: ページの編集
    前提 ノート"a_note"のページ"FrontPage"を表示している

    もし ページメニューの"編集"リンクをクリックする
    かつ "内容"に"これはテストページです"と入力する
    かつ "ページを更新"ボタンをクリックする
    ならば "これはテストページです"と表示されていること

  シナリオ: ラベルを変更する
    前提 ノート"a_note"のページ"FrontPage"を表示している

    もし  ラベルを"ラベル 2"に変更する

    ならば "SKIP Wikiへようこそ"と表示されていること
    かつ "ラベル 2"と表示されていること

  シナリオ: FrontPage以外のページを未公開に
    前提 ノート"a_note"のページ"page_1"を表示している
    もし "未公開にする"ボタンをクリックする

    ならば "エラーが発生しました"と表示されていないこと

  シナリオ: ページ作成に失敗
    前提   ノート"a_note"のページ"FrontPage"を表示している

    もし   ノートメニューの"新しいページを作る"リンクをクリックする
    ならば "新しいページを作る"と表示されていること

    もし "ページ名"に"ページ「い」"と入力する
    かつ "内容"に"これはテストページです"と入力する
    かつ "ページを作成"ボタンをクリックする

    ならば "新しいページを作る"と表示されていること
    かつ   "エラーが発生しました。"と表示されていること

    もし "ページ識別子"に"abc"と入力する
    もし "ページ名"に"ページ「い」"と入力する
    かつ "内容"に""と入力する
    かつ "ページを作成"ボタンをクリックする

    ならば "新しいページを作る"と表示されていること
    かつ   "ページにエラーが発生しました。"と表示されていること

