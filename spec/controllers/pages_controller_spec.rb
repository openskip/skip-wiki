require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe PagesController do
  fixtures :notes

  before do
    @current_note = notes(:our_note)
    controller.stub!(:authenticate).and_return(true)
    controller.stub!(:current_note).and_return(@current_note)

    @user = mock_model(User)
    @user.stub!(:page_editable?).with(@current_note).and_return true
    controller.stub!(:current_user).and_return(@user)
  end

  #Delete this example and add some real ones
  it "should use PagesController" do
    controller.should be_an_instance_of(PagesController)
  end

  describe "GET /notes/hoge/pages/our_note_page_1" do
    fixtures  :pages
    before do
      @page = pages(:our_note_page_1)
      get :show, :note_id=>@current_note.name, :id=>@page.name
    end

    it "statusは200であること" do
      response.code.should == "200"
    end

    it "showテンプレートをrenderしていること" do
      response.should render_template("show")
    end
  end

  describe "GET /notes/hoge/pages/not_exists" do
    fixtures  :pages
    it "responseは404であること" do
      get :show, :note_id=>@current_note.name, :id=>"not_exist"
      response.code.should == "404"
    end
  end

  describe "POST /notes/hoge/pages [SUCCESS]" do
    describe "既存のラベルからページを作成した場合" do
      before do
        controller.should_receive(:explicit_user_required).and_return true

        @current_note.pages.should_receive(:add).
          with(page_param, @user).and_return(page = mock_model(Page, page_param))
        page.should_receive(:save!).and_return(true)

        post :create, :note_id => @current_note.name, :page => page_param
      end

      it "responseは/notes/our_note/pages/page_1へのリダイレクトであること" do
        response.should redirect_to(note_page_path(@current_note, assigns(:page)))
      end
    end

    describe "新しいラベルを設定してページを作成する場合" do
      before do
        controller.should_receive(:explicit_user_required).and_return true
        @label = mock_model(LabelIndex, label_param)
        @label.should_receive(:[]=).with("note_id", @current_note.id).
          and_return(@label)
        @label.should_receive(:save).and_return(true)
        @current_note.pages.should_receive(:add).
          with(page_param, @user).and_return(page = mock_model(Page, page_param))
        page.should_receive(:save!).and_return(true)
        page.should_receive(:label_index_id=).with(@label.id).
          and_return(page)
      end

      it "LabelIndexに対してcreateが呼ばれること" do
        LabelIndex.should_receive(:create).with(label_param).
          and_return(@label)
        post :create, :note_id => @current_note.name, :page => page_param, :label => label_param
      end

      def label_param
        {'display_name' => "hoge", 'color' => "#FFFFFF", 'default_label' => false }
      end
    end

    describe "ノートに紐づくアップロード中のファイルがあった場合" do
      it "file_attach_user=にloginしているユーザが設定されること" do
        controller.should_receive(:explicit_user_required).and_return true

        page = mock_model(Page, page_param)
        page.should_receive(:file_attach_user=).with(@user)
        @current_note.pages.should_receive(:add).
          with(page_param, @user).and_return(page)
        page.should_receive(:save!).and_return(true)

        post :create, :note_id => @current_note.name, :page => page_param
      end
    end
   end

  describe "POST /notes/hoge/pages [FAILED]" do
    before do
      controller.should_receive(:explicit_user_required).and_return true

      @current_note.pages.should_receive(:add).
        with(page_param, @user).and_return(page = mock_model(Page, page_param))
      page.should_receive(:save!).and_raise(ActiveRecord::RecordNotSaved)

      post :create, :note_id => @current_note.name, :page => page_param
    end

    it "newテンプレートを表示すること" do
      response.should render_template("new")
    end
  end

  describe "PUT /notes/hoge/pages [SUCCESS]" do
    fixtures :notes
    before do
      controller.should_receive(:explicit_user_required).and_return true

      page_param = {:published => "1", :name => "page_1", :display_name => "page_1", :format_type => "html", :content_html => "<p>foobar</p>"}.with_indifferent_access
      @current_note.label_indices << LabelIndex::first_label

      @page = @current_note.pages.add(page_param, @user)
      @page.published = false
      @page.save!
    end

    it "responseは/notes/our_note/pages/page_01へのリダイレクトであること" do
      put :update, :note_id => @current_note.name, :id =>@page.to_param,
                   :page => {:label_index_id => @current_note.label_indices.last.id}

      response.should redirect_to(note_page_path(@current_note, assigns(:page)))
    end

    it "コンテンツを指定しても無視されること" do
      put :update, :note_id => @current_note.name, :id =>@page.to_param, :page => {:name => "page_01", :content => "new"}
      assigns(:page).content.should == "<p>foobar</p>"
    end

    describe "via XHR" do
      before do
        xhr :put, :update, :note_id => @current_note.name, :id =>@page.to_param, :page => {:display_name => "page_01", :content => "new"}
      end
      it "ページ名が更新されること" do
        assigns(:page).display_name.should == "page_01"
      end

      it "flashが空であること" do
        flash[:notice].should be_blank
      end
    end
  end

  describe "DELETE /notes/hoge/pages/page_1 [FAILURE]" do
    fixtures :notes
    before do
      controller.should_receive(:explicit_user_required).and_return true

      Page.should_receive(:find_by_name).with("page_1").and_return(@page = mock_model(Page))
      @page.should_receive(:logical_destroy).and_return(false)

      delete :destroy, :note_id => "our_note", :id => "page_1"
    end
    it{ response.should redirect_to( edit_note_page_url("our_note", @page) ) }
    it{ flash[:warn].should_not be_blank }
  end

  describe "GET /notes/hoge/pages/new" do
    before do
      controller.should_receive(:explicit_user_required).and_return true
    end
    it "作成されるページのは公開に設定されていること" do
      get :new
      assigns(:page).should_not be_published
    end
  end

  def page_param
    {:name => "page_1", :display_name => "page_1", :format_type => "html", :content => "<p>foobar</p>", :file_attach_user= => nil}.with_indifferent_access
  end

end

describe PagesController, 'GET /' do
  before do
    controller.stub!(:authenticate).and_return(true)

    @user = mock_model(User)
    controller.stub!(:current_user).and_return(@user)

    @pages = mock('pages')
    @pages.stub(:build)
  end
  describe '誰でも読み書きできるノートがある場合' do
    before do
      @wikipedia = stub_model(Note)
      @wikipedia.stub_chain(:label_indices, :first).and_return(stub_model(LabelIndex, :id => 99))
      Note.should_receive(:wikipedia).and_return(@wikipedia)
    end
    describe 'ページがある場合' do
      before do
        @pages.stub(:size).and_return(1)
        @pages.stub(:find_by_name).and_return(stub_model(Page))
        @wikipedia.stub(:pages).and_return(@pages)
      end
      it 'FrontPageへ遷移すること' do
        get :root
        response.should render_template('show')
      end
    end
    describe 'ページがない場合' do
      before do
        @pages.stub(:size).and_return(0)
        @pages.stub(:find_by_name).and_return(nil)
        @wikipedia.stub(:pages).and_return(@pages)
      end
      describe '管理者の場合' do
        before do
          @user.stub(:note_editable?).and_return(true)
        end
        it 'FrontPage作成画面へ遷移すること' do
          get :root
          response.should render_template('pages/init')
        end
      end
      describe '一般ユーザの場合' do
        before do
          @user.stub(:note_editable?).and_return(false)
        end
        it '404になること' do
          get :root
          response.code.should == '404'
        end
      end
    end
  end
  describe '誰でも読み書きできるノートがない場合' do
    before do
      Note.should_receive(:wikipedia).and_return(nil)
    end
    it '404になること' do
      get :root
      response.code.should == '404'
    end
  end
end
