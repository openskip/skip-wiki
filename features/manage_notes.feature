フィーチャ: ノート管理
  ログインしたユーザは自分たちが使うノートを作成できるようにしたい

  シナリオ: ノート作成
    前提   言語は"ja-JP"
    かつ   デフォルトのカテゴリが登録されている
    かつ   ユーザ"alice"を登録する
    かつ   ユーザのIdentity URLを"http://nimloth.local:3333/user/alice"として登録する
    かつ   OpenId "http://nimloth.local:3333/user/alice"でログインする
    かつ   "New Note"リンクをクリックする

    もし "個人用ノート"を選択する
    かつ "ビジネス"を選択する
    かつ "グループメンバーのみ閲覧/書込できる"を選択する
    かつ "ノート名"に"テスト用ノート"と入力する
    かつ "ノート識別子"に"a_note"と入力する
    かつ "ノートの説明"に"ノートですテストです"と入力する
    かつ "作成"ボタンをクリックする

    ならば "表紙"と表示されていること

