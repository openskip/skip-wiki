#
# Added for Ruby-GetText-Package
#
ENV["MSGMERGE_PATH"] = "msgmerge --no-location"
desc "Create mo-files for L10n"
task :makemo do
  require 'gettext_rails/tools'
  GetText.create_mofiles
end

desc "Update pot/po files to match new version."
task :updatepo do
  require 'gettext_rails/tools'
  require 'gettext_haml_parser'
  GetText::RGetText.add_parser(HamlParser)
  GetText.update_pofiles("skip-note", Dir.glob("{app,lib}/**/*.{rb,erb,haml}"), "skip-note 1.0.0")
end
