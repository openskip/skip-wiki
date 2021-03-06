フィーチャ: ラベルをたどる
  Wikiの管理者として
  ラベルの付いたページや、付いていないページをそれぞれ辿れるようにしたい

  シナリオ: ラベルなしページを表示しそのラベルの中でページをたぐる
    前提   言語は"ja-JP"
    かつ   ユーザ"alice"を登録し、ログインする
    かつ   Wiki"a_note"が作成済みである
    かつ   Wiki"a_note"のトップページ"FrontPage"を作成する
    かつ   そのWikiにはページ"page_0"が作成済みである
    かつ   そのWikiにはページ"page_1"が作成済みである
    かつ   Wiki"a_note"のページ"FrontPage"を表示している
    かつ   ペンディング: Wikiメニューのプロパティは設定できない
    かつ   Wikiメニューの"プロパティ"リンクをクリックする
    かつ   "常に表示する"を選択する
    かつ   "更新"ボタンをクリックする

    もし   Wiki"a_note"のページ"page_0"を表示している
    ならば "Content for the page `page_0'"と表示されていること

    もし   "page_1"リンクをクリックする
    ならば "Content for the page `page_1'"と表示されていること

    もし   "page_0"リンクをクリックする
    ならば "Content for the page `page_0'"と表示されていること
    ならば "page_0"と表示されていること
    かつ   "page_1"と表示されていること
    かつ   "FrontPage"と表示されていること

  シナリオ: ラベルを表示しないWikiでは、他のページの情報が表示されないこと
    前提   ペンディング:ラベルを表示しないはできなくなるのでいらなくなる
    前提   言語は"ja-JP"
    かつ   ユーザ"alice"を登録し、ログインする
    かつ   Wiki"a_note"が作成済みである
    かつ   Wiki"a_note"のトップページ"FrontPage"を作成する
    かつ   そのWikiにはページ"page_0"が作成済みである
    かつ   そのWikiにはページ"page_1"が作成済みである
    かつ   Wiki"a_note"のページ"FrontPage"を表示している
    かつ   Wikiメニューの"プロパティ"リンクをクリックする

    かつ   "表示しない"を選択する
    かつ   "更新"ボタンをクリックする

    もし   Wiki"a_note"のページ"page_0"を表示している
    ならば "Page 0"と表示されていること
    かつ   "Page 1"と表示されていないこと
    かつ   "FrontPage"と表示されていないこと

