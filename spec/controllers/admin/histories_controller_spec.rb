require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Admin::HistoriesController do
  fixtures :notes, :pages
  before do
    controller.stub!(:authenticate).and_return(true)
    controller.stub!(:require_admin).and_return(true)
  end

  def mock_page(stubs={})
    @mock_page ||= mock_model(Page,stubs)
  end

  def mock_note(stubs={})
    @mock_note ||= mock_model(Note,stubs)
  end

  def mock_user(stubs={})
    @mock_user ||= mock_model(User,stubs)
  end

  def mock_history(stubs={})
    default_attribute = {:content =>"hoge", :user => mock_user, :revision => 1 }
    @mock_history ||= mock_model(History, default_attribute.merge!(stubs))
  end

  describe "GET 'new'" do
    before do
      controller.stub!(:requested_note).and_return(mock_note)
      Page.should_receive(:find_by_name).with('our_note_page_1').and_return(mock_page)
      mock_page.should_receive(:display_name).and_return("hoge")
      get :new, :note_id => "our_note", :page_id => 'our_note_page_1'
    end

    it "ページが1件取得できていること" do
      assigns[:note].should == mock_note
      assigns[:page].should == mock_page
    end

    it "ぱんくずが空でないこと" do
      assigns[:topics].should_not be_empty
    end
  end

  describe "POST 'create'" do
    before do
      Page.stub(:find_by_name).with("page_id").and_return(mock_page)
      controller.stub(:current_user).and_return(mock_user)
    end
    describe "Historyの編集が成功する場合" do
      before do
        controller.stub(:requested_note).and_return(mock_note)
        mock_page.stub(:edit).with("update params", mock_user).and_return(mock_history)
        mock_history.stub(:save).and_return(true)
      end
      it "リダイレクトされること" do
        post :create, :note_id => 'note_id', :page_id => 'page_id', :history => {:content => "update params"}
        response.should redirect_to(admin_note_page_url(mock_note, mock_page))
      end
      describe "jsでアクセスした場合" do
        it "ヘッダーが返ること" do
          post :create, :note_id => 'note_id', :page_id => 'page_id', :history => {:content => "update params"}, :format => 'js'
          response.header["Location"].should == admin_note_page_history_path(mock_note, mock_page, mock_history)
        end
      end
    end

    describe "Historyの編集が失敗する場合" do
      before do
        errors = mock('errors', :full_messages => "validation error")
        mock_page.stub(:edit).and_return(mock_history(:save => false,
                                                      :errors => errors,
                                                      :content => mock('content',
                                                                       :errors => errors)))
      end
      it "エラーが含まれるjsが返ること" do
        post :create, :note_id => 'note_id', :page_id => 'page_id', :history => {:content => "update params"}, :format => 'js'
        response.body.should == "[\"validation error\",\"validation error\"]"
      end
    end
  end

end
