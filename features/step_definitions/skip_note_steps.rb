require 'rubygems'

valid_attributes = {
  :note => {
    :name => "value for name",
    :display_name => "value for display_name",
    :description => "value for note description",
    :publicity => 0,
    :category_id => "1",
    :group_backend_type => "BuiltinGroup",
    :group_backend_id => ""
  }.freeze,
  :page => {
    :display_name => "value for display_name",
    :published => true,
    :format_type => "html",
  }.freeze,
  :label => {
      :display_name => "Ruby",
      :color => "#ff0000",
  }.freeze
}

def prepare_default_category
  Category.transaction do
    Category.delete_all
    [
      %w[OFFICE オフィス  社内の公式資料の置き場所として利用する場合に選択してください。],
      %w[BIZ    ビジネス  プロジェクト内など、業務で利用する場合に選択してください。],
      %w[LIFE   ライフ    業務に直結しない会社内の活動で利用する場合に選択してください。],
      %w[OFF    オフ      趣味などざっくばらんな話題で利用する場合に選択してください。],
    ].each_with_index do |(name, display_name, desc), idx|
      Category.create(:name=>name, :display_name=>display_name, :description => desc) do |c|
        c.lang = "ja"
        c.id = idx + 1
      end
    end
  end
end

def disable_sso
  SkipEmbedded::OpFixation.skip_url = nil
end

def lookup_publicity(val)
  case val
  when _("Not display") then LabelIndex::NAVIGATION_STYLE_NONE
  when _("Display and enable toggle") then LabelIndex::NAVIGATION_STYLE_TOGGLE
  when _("Display always") then LabelIndex::NAVIGATION_STYLE_ALWAYS
  end
end

Before do
  prepare_default_category
  disable_sso
end

Given(/^Wiki"(.*)"が作成済みである/) do |note_name|
  builder = NoteBuilder.new(@user, valid_attributes[:note].merge({ :name => note_name, :display_name => note_name }))
  builder.note.save!
  @note = builder.note
end

Given( /^そのWikiにはページ"(.*)"が作成済みである$/)  do |page_name|
  attrs = valid_attributes[:page].merge({ :display_name => page_name })
  attrs[:content_html] = "Content for the page `#{page_name}'"
  @page = @note.pages.add(attrs, @user)
  @page.save!
end

Given(/^そのWikiにはラベル"(.*?)"が作成済みである$/)  do |label|
  @label = @note.label_indices.create!(valid_attributes[:label].merge(:display_name => label))
end

Given(/^そのページはラベル"(.*?)"と関連付けられている$/) do |label|
  label = @note.label_indices.find_by_display_name(label)
  @page.label_index_id = label.id
  @page.save!
end

Given( /^そのページの更新日時を"(\d+)"分進める$/ ) do |min|
  t = Integer(min).minutes.since(@page.updated_at)
  Page.update_all("updated_at = '#{t.to_s(:db)}'", ["id = ?", @page.id])
end

Given( /^Wiki"(.*)"の情報を表示している$/) do |note|
  visit note_path(note)
end

Given( /^Wiki"(.*)"のページ"(.*)"を表示している$/) do |note_name, page_name|
  note = Note.find_by_name(note_name)
  page = note.pages.find_by_display_name(page_name)
  visit note_page_path(note_name, page.id)
end

Given( /^Wiki"(.*)"のページ"(.*)"を表示すると"(.*)"エラーが発生すること$/) do |note, page, e|
  begin
    visit note_page_path(note, page)
    flunk("No error raised.")
  rescue StandardError => ex
    ex.should be_kind_of(e.constantize)
  end
end

Given(/^"(.+)"を"(\d+)"日前に設定する/) do |label, n|
  date = Integer(n).days.ago(Time.now)
  select_datetime(date, :from => label, :use_month_numbers=>true)
end

Given(/^"(.+)"を"(\d+)"日後に設定する/) do |label, n|
  date = Integer(n).days.since(Time.now)
  select_datetime(date, :from => label, :use_month_numbers=>true)
end

Given(/固定OPの設定をする/) do
  pending("このシナリオは手動で実行する")
end

Given(/ペンディング:\s*(\w.+)$/) do |reason|
  pending(reason)
end

Given(/((?:Wiki)|(?:ページ))メニューの"(\w+)"リンクをクリックする/) do |type, label|
  container = {
    "Wiki" => "div#note-menu",
    "ページ" => "div#page-menu",
  }[type]
  Given %Q["#{container}"中の"#{label}"リンクをクリックする]
end

Given(/Wiki"(\w+)"の公開範囲を「全員が読める。メンバーのみが書き込める。」に設定する/) do |note|
  Note.find_by_name(note).update_attributes!(:publicity => Note::PUBLICITY_READABLE)
end

Given(/Wiki"(\w+)"の公開範囲を「メンバーのみが読み書きできる」に設定する/) do |note|
  Note.find_by_name(note).update_attributes!(:publicity => Note::PUBLICITY_MEMBER_ONLY)
end

Given(/Wiki"(\w+)"の公開範囲を「全員が読み書きできる」に設定する/) do |note|
  Note.find_by_name(note).update_attributes!(:publicity => Note::PUBLICITY_WRITABLE)
end

Given(/トップページを表示している/) do
  visit root_path
end

Given /ラベルを"([^\"]*)"に変更する/ do |new_label|
  pending("JSでサブミットしているため手動で確認すること")
end

Then /^flashメッセージに"([^\"]*)"と表示されていること$/ do |message|
  response.body.should =~ /#{Regexp.escape(message.to_json)}/m
end
