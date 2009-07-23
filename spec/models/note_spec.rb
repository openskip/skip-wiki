require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Note do
  fixtures :users
  before(:each) do
    @user = users(:quentin)
    @group = mock_model(Group)
    @valid_attributes = {
      :name => "value_for_name",
      :display_name => "value for display_name",
      :description => "value for description.",
      :publicity => Note::PUBLICITY_MEMBER_ONLY,
      :category_id => "1",
      :owner_group => @group,
      :group_backend_type => "BuiltinGroup",
    }
  end

  it "should create a new instance given valid attributes" do
    Note.create!(@valid_attributes)
  end

  describe "validation" do
    %w[new edit].each do |name|
      context "#{name}という識別子はつけられない" do
        subject{ Note.new(@valid_attributes) }
        before{ subject.name = "new" }
        it{ should_not be_valid }
        it{ should have(1).errors_on(:name) }
      end
    end
    describe "uniqueness" do
      subject do
        Note.create!(@valid_attributes)
        Note.new(@valid_attributes)
      end
      it{ should have(1).errors_on(:name) }
    end
  end

  describe ".fulltext" do
    fixtures :notes
    it "'Our' should hit 1 notes" do
      Note.fulltext("Our").should have(1).items
    end

    it "'description' should hit 3 notes" do
      Note.fulltext("description").should have(3).items
    end

    it "'--none--' should hit 0 notes" do
      Note.fulltext("--none--").should have(0).items
    end

    it "(nil) should hit 3 notes" do
      Note.fulltext(nil).should have(3).items
    end
  end

  describe '.writable_or_accessible' do
    fixtures :notes, :users
    describe 'ユーザの指定がある場合' do
      describe 'ユーザのアクセス可能なノートが取得できる場合' do
        before do
          @user = User.first
          @user.stub_chain(:accessible_notes, :all).and_return([stub_model(Note, :id => 101)])
        end
        it 'should hit 2 notes' do
          Note.writable_or_accessible(@user).should have(2).items
        end
      end
      describe 'ユーザのアクセス可能なノートが取得できない場合' do
        before do
          @user = User.first
          @user.stub_chain(:accessible_notes, :all).and_return([])
        end
        it 'だれでも書けるノートのみ取得されること' do
          Note.writable_or_accessible(@user).should have(1).items
        end
      end
    end
    describe 'ユーザの指定がない場合' do
      fixtures :notes
      it "(nil) should hit 3 notes" do
        Note.writable_or_accessible(nil).should have(3).items
      end
    end
  end

  describe '.readable' do
    fixtures :notes
    it '誰でもかけるノートのみ取得されること' do
      Note.readable.should have(1).items
    end
  end

  describe '.owned_group' do
    describe 'グループの指定がある場合' do
      before do
        skip_group = SkipGroup.create!(:name => 'skip', :display_name => 'SKIPのグループ', :gid => 'skip')
        @group = skip_group.create_group(:name => skip_group.name, :display_name => skip_group.display_name + '(SKIP)')
        @group_owned_note = Note.create!(@valid_attributes.merge!(:owner_group => @group))
      end
      it '指定グループに所属するノートのみ取得されること' do
        Note.owned_group(@group).should == [@group_owned_note]
      end
    end
    describe 'グループの指定がない場合' do
      fixtures :notes
      it "(nil) should hit 3 notes" do
        Note.owned_group(nil).should have(3).items
      end
    end
  end

  describe "pages.add(attrs, user) (hiki)" do
    fixtures :users
    before(:each) do
      @note = NoteBuilder.new(@user, @valid_attributes).note
      @note.save!
      @initialize_attrs = {
        :name=>"FrontPage",
        :display_name => "トップページ",
        :content_hiki => "hogehogehoge",
        :content_html => "<p>hogehogehoge</p>",
      }

    end

    describe "HTML format" do
      before do
        @page = @note.pages.add(@initialize_attrs.merge(:format_type => "html"), @user)
      end
      it "create new page" do
        @page.save!
        @note.reload.should have(1).pages
      end

      it "do not create untill @page.save" do
        @note.reload.should have(0).pages
      end

      it "作成されたページのLabelIndexがデフォルトラベルであること" do
        @page.save!
        @page.reload.label_index.should == @note.default_label
      end

      it "contentは'<p>hogehogehoge</p>'であること" do
        @page.content.should == '<p>hogehogehoge</p>'
      end
    end

    describe "Hiki format" do
      before do
        @page = @note.pages.add(@initialize_attrs.merge(:format_type => "hiki"), @user)
      end

      it "contentは'hogehogehoge'であること" do
        @page.content.should == 'hogehogehoge'
      end
    end
  end

  describe "build_front_page" do
    before(:each) do
      Page.should_receive(:front_page_content).and_return("---FrontPage---")
      builder = NoteBuilder.new(@user, @valid_attributes)
      @note = builder.note
      @page = builder.front_page

      @note.save!
      @page.save!
    end

    it "create new page" do
      @note.reload.should have(1).pages
    end

    it "添付ファイル一覧表示の設定になっていること" do
      @note.should be_list_attachment
    end

    it "添付ファイル一覧表示の設定になっていること" do
      @note.label_navigation_style.should == LabelIndex::NAVIGATION_STYLE_ALWAYS
    end

    it "ページのnameはFrontPageであること" do
      page = @note.reload.pages.first
      page.name.should == "FrontPage"
    end

    it "ページのcontentsは指定したものであること" do
      page = @note.reload.pages.first
      page.content.should == "---FrontPage---"
    end

    describe "#destroy" do
      before do
        @note.destroy
      end

      it{ Page.find_all_by_note_id(@note).should be_empty }
    end
  end

  describe "accessible?" do
    before(:each) do
      @note = @user.build_note(
        :name => "value for name",
        :display_name => "value for display_name",
        :description => "value for note description",
        :publicity => Note::PUBLICITY_READABLE,
        :category_id => "1",
        :group_backend_type => "BuiltinGroup",
        :group_backend_id => ""
      )
      @note.save!
    end

    it "グループのユーザはaccessibleであること" do
      users(:quentin).should be_accessible(@note)
    end

    it "グループ外のユーザはaccessibleでないこと" do
      users(:aaron).should_not be_accessible(@note)
    end
  end

  describe ".create_or_update_wikipedia" do
    before(:all) do
      Note.class_eval{ cattr_writer :wikipedia }
    end
    before do
      Note.destroy_all
      User.all.each do |u|
        u.admin = false
        u.save!
      end
      Note.wikipedia = nil
    end
    describe "管理者がいない場合" do
      it "nilが返ること" do
        Note.create_or_update_wikipedia.should be_nil
      end
    end
    describe "管理者が存在する場合" do
      before do
        @users = (1..4).map{|i|create_user( :name => "user#{i}" )}
        @admin_users = @users[0..2].map{ |u| u.admin = true; u.save ;u }
      end
      describe "wikipediaが存在しないとき" do
        it "新規に作成されること" do
          lambda do
            Note.create_or_update_wikipedia
          end.should change(Note, :count).by(1)
        end
        it "wikipediaが作成されること" do
          Note.wikipedia.should_not be_is_a(Note)
          wikipedia = Note.create_or_update_wikipedia
          Note.wikipedia.should == wikipedia
        end
        it "管理者ユーザがグループに入っていること" do
          Note.create_or_update_wikipedia
          (Note.wikipedia.owner_group.users - @admin_users).should == []
        end
      end
      describe "wikipediaが存在するとき" do
        before do
          wikipedia = Note.create_or_update_wikipedia
        end
        it "管理者が更新されること" do
          lambda do
            u = create_user(:name => "new_user", :admin => true)
            Note.create_or_update_wikipedia
          end.should change(Note.wikipedia.owner_group.users, :count).by(1)
        end
      end
    end
  end

  def build_note
    @user.build_note(
      :name => "value for name",
      :display_name => "value for display_name",
      :description => "value for note description",
      :publicity => Note::PUBLICITY_READABLE,
      :category_id => "1",
      :group_backend_type => "BuiltinGroup",
      :group_backend_id => ""
    )
  end

end
