Given /^言語は"([^\"]*)"$/ do |lang|
  header("ACCEPT_LANGUAGE", lang)
end

When /"([^\"]*)"中の"([^\"]*)"リンクをクリックする$/ do |element, label|
  click_link_within(element, label)
end

When /^テーブル"([^\"]*)"の"([^\"]*)"行目の"([^\"]*)"リンクをクリックする$/ do |css, nth, label|
  selector = "table.#{css} tbody tr:nth(#{nth})"
  click_link_within(selector, label)
end

When /^デバッグのため$/ do
  save_and_open_page
end

Then /^テキストフィールドに"([^\"]*)"と表示されていること$/ do |text|
  response.should have_tag("input[type=text][value=#{text}]")
end

Then /^"([^\"]*)"というリンクがあること$/ do |label|
  response.should have_tag("a", label)
end

Then /^"([^\"]*)"というリンクがないこと$/ do |label|
  response.should_not have_tag("a", label)
end

Then /^"([^\"]*)"というボタンがあること$/ do |label|
  response.should have_tag("input[type=submit][value=?]", label)
end

Then /^"([^\"]*)"というボタンがないこと$/ do |label|
  response.should_not have_tag("input[type=submit][value=?]", label)
end
