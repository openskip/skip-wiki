require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Page do
  describe "deafult values" do
    it ".format_type.should == 'html'" do
      Page.new.format_type.should == 'html'
    end
  end

  before(:each) do
    @valid_attributes = {
      :note_id => "1",
      :last_modied_user_id => "1",
      :display_name => "value for display_name",
      :format_type => "hiki",
      :published => true,
      :deleted_at => Time.now,
      :lock_version => "1"
    }
  end

  describe "#label_index_id = an_label.id" do
    before do
      @note = mock_model(Note, :pages => [mock_model(Page), mock_model(Page)])
      @page = Page.new(@valid_attributes.merge(:note=>@note))
      @label = LabelIndex.create(:note=>@note, :display_name=>"foobar")

      @page.label_index_id = @label.id
    end

    it "should be new_record" do
      @page.should be_new_record
    end

    it "#label_index_id.should == @label.id" do
      @page.label_index_id.should == @label.id
    end

    describe "save!" do
      before do
        @note.stub!(:label_indices).and_return(LabelIndex)
        @page.edit("content", mock_model(User))
        @page.published = true
        @page.save!
      end

      it "then should have 1 label_indexings" do
        @page.reload.label_index.should_not be_nil
      end

      it "#label_index_id.should_not be nil" do
        Page.find(@page).label_index_id.should_not be_nil
      end

      it "#label_indexings.firstのpage_orderは1であること" do
        l = Page.find(@page).label_indexing
        l.page_order.should == 1
      end

      describe "別のページを追加した場合" do
        before do
          @another = Page.new(@page.attributes) do |page|
            page.note = @note
            page.label_index_id = @label.id
          end
          @another.edit("content", mock_model(User))
          @another.save!
        end

        it "#label_indexings.firstのpage_orderは2であること" do
          l = Page.find(@another).label_indexing
          l.page_order.should == 2
        end
      end
    end
  end

  describe "edit(content, user)" do
    before do
      @page = Page.new(@valid_attributes)
      @page.edit("hogehogehoge", mock_model(User))
    end

    it "Historyを作ること" do
      lambda{@page.save!}.should change(History,:count).by(1)
    end

    it "保存後のrevisionは1であること" do
      @page.save!; @page.reload
      @page.revision.should == 1
    end

    it "最新のコンテンツは'hogehogehoge'であること" do
      @page.save!
      @page.content.should == "hogehogehoge"
    end

    it "未保存でも最新のコンテンツは'hogehogehoge'であること" do
      @page.content.should == "hogehogehoge"
    end

    it "未保存でも最新のコンテンツは'hogehogehoge'であること" do
      @page.content.should == "hogehogehoge"
    end

    describe "同じ内容で保存した場合" do
      before do
        @page.save!
      end

      it "Historyを追加しないこと" do
        lambda{
          @page.edit("hogehogehoge", mock_model(User))
          @page.save!
        }.should_not change(History,:count)
      end
    end

    describe "再編集した場合" do
      before do
        @page.save!
        @page.reload
        @page.edit("edit to revision 2", mock_model(User))
        @page.save!
      end

      it "contentは新しいものであること" do
        @page.reload.content.should == "edit to revision 2"
      end

      it "contentの引数でrevisionを指定できること" do
        @page.reload.content(1).should == "hogehogehoge"
      end
    end

    describe "入力されたnew_historyがvalidでない場合" do
      before do
        @page.new_history.stub!(:valid?).and_return(false)
      end

      it "Pageもvalidでないこと" do
        @page.should_not be_valid
      end

      it "new_historyにエラーがあること" do
        @page.valid?
        @page.should have(1).errors_on(:new_history)
      end
    end
  end

  describe "edit(content, user) FAIL" do
    before do
      @page = Page.new(@valid_attributes)
      @page.edit("", mock_model(User))
    end

    it "should not be valid" do
      @page.should_not be_valid
    end
  end

  describe ".fulltext('keyword')" do
    before do
      History.should_receive(:find_all_by_head_content).
        with('keyword').
        and_return( [@history = mock_model(History, :page_id => "10")] )
    end

    it ".options.should == {:conditions => ['pages.id IN (?)', @history.page_id]}" do
      Page.fulltext("keyword").proxy_options.should ==
        {:conditions => ["#{Page.quoted_table_name}.id IN (?)", [@history.page_id]]}
    end
  end

  describe ".admin_fulltext('keyword')" do
    before do
      History.should_receive(:find_all_by_head_content).
        with('keyword').
        and_return( [@history = mock_model(History, :page_id => "10")] )
    end

    it ".options.should == {:conditions => ['pages.id IN (?)', @history.page_id]}" do
      Page.admin_fulltext("keyword").proxy_options.should ==
        {:conditions => ["#{Page.quoted_table_name}.id IN (?) OR #{Page.quoted_table_name}.display_name LIKE ?", [@history.page_id], '%keyword%']}
    end
  end

  describe "fulltext()で実際に検索する場合" do
    before do
      @page = Page.new(@valid_attributes)
      @page.edit("the keyword", mock_model(User))
      @page.save!
    end

    it "結果は[@page]であること" do
      Page.fulltext("keyword").should == [@page]
    end
  end

  describe '#front_cant_destory' do
    fixtures :notes
    before do
      @front_page = Page.new(@valid_attributes)
      @front_page.edit("content", mock_model(User))
      @note = notes(:our_note)
      @note.front_page = @front_page
    end
    it "FrontPageは削除できないこと" do
      lambda{ @front_page.destroy }.should_not change(Page, :count)
    end
  end

  describe ".authored(*authors)" do
    fixtures :users
    before do
      @page = Page.new(@valid_attributes)
      @page.edit("hogehogehoge", users(:quentin))
      @page.save!

      another = Page.new(@valid_attributes)
      another.edit("foobar", users(:aaron))
      another.save!
    end

    it "authored('quentin') should == [@page]" do
      Page.authored("quentin").should == [@page]
    end

    it do
      Page.authored("quentin").fulltext("foobar").should == []
    end
  end

  describe ".labeled(*labels)" do
    fixtures :users, :notes, :pages
    before do
      @label = LabelIndex.create(:note=>notes(:our_note), :display_name=>"foobar")

      @page = pages(:our_note_page_1)
      @page.label_index_id = @label.id
      @page.edit("content", mock_model(User))
      @page.save!

      another_label = LabelIndex.create(:note=>notes(:our_note), :display_name=>"piyo")
      @another = pages(:our_note_page_2)
      @another.label_index_id = another_label.id
      @another.edit("another content", mock_model(User))
      @another.save!
    end

    it "labeled(@label) should == [@page]" do
      Page.labeled(@label.id).should == [@page]
    end

    it "labeled([]) should == [@page, @another]" do
      Page.labeled([]).should == [@page, @another]
      Page.labeled([]).labeled(@label.id).should == [@page]
    end

    it do
      Page.authored("quentin").fulltext("foobar").should == []
    end
  end

  describe ".active" do
    fixtures :notes
    before do
      @page = Page.new(@valid_attributes)
      @page.edit("hogehogehoge", mock_model(User))
      @page.save!
      @page.reload

      @page.logical_destroy
    end

    it "can't find logical_destroy-ed page" do
      lambda{ Page.active.find(@page) }.should raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe ".admin" do
    fixtures :notes
    before do
      @page = Page.new(@valid_attributes)
      @page.note_id = @valid_attributes[:note_id]
      @page.edit("hogehogehoge", mock_model(User))
      @page.save!
    end

    it "note_id=1に関連するページが取得できること" do
      Page.admin(1).should == [@page]
    end
  end

  describe '#after_create' do
    fixtures :notes, :groups
    describe '所属するWikiの最初のページの場合' do
      before do
        @note = notes(:our_note)
        @note.pages.clear
        @front_page = Page.new(@valid_attributes)
        @front_page.edit('content', mock_model(User))
      end
      it '所属するWikiのfront_pageが設定されること' do
        lambda do
          @note.pages << @front_page
          @note.reload
        end.should change(@note, :front_page).from(nil).to(@front_page)
      end
    end
    describe '所属するWikiの最初のページ以外の場合' do
    end
  end

end

