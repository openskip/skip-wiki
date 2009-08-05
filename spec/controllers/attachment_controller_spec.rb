require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AttachmentsController do
  fixtures :users, :notes
  before do
    controller.stub!(:current_user).and_return(@user = users(:quentin))
    controller.stub!(:current_note).and_return(@note = notes(:our_note))

    controller.stub!(:writable_user_required).and_return(true)
    controller.stub!(:only_if_list_attachments_or_group_member).and_return(true)
  end

  describe "GET index.js" do
    before do
      @attachments = [
        @note.attachments.create!(:uploaded_data => fixture_file_upload("data/at_small.png", "image/png", true),
                                  :display_name  => "user iconとかの画像です", :user_id => 1),
      ]
      xhr :get, :index, :note_id=>notes(:our_note)
    end

    it do
      response.should be_success
    end

    describe "レスポンスのJSON" do
      before do
        @attachments_json = ActiveSupport::JSON.decode(response.body)
      end

      it do
        @attachments_json.should be_an_instance_of(Array)
      end

      it "最初のデータの[attachment][display_name]は/^user icon/にマッチすること" do
        @attachments_json.first["attachment"]["display_name"].should =~ /^user icon/
      end

      it "最初のデータの[attachment][path]は%r[/attachments/\d+]にマッチすること" do
        @attachments_json.first["attachment"]["path"].should =~ %r[/attachments/\d+]
      end

      it "最初のデータの[attachment][inline]がnilでないこと" do
        @attachments_json.first["attachment"]["inline"].should_not be_nil
      end
    end
  end

  describe "GET /new" do
    it 'page_idがparamsにない場合' do
      get :new
      assigns(:attachment).attachable_type.should == Note.to_s
    end
    it 'page_idがparamsにある場合' do
      page_id = 10
      get :new, :page_id => page_id
      assigns(:attachment).attachable_id.should == page_id
      assigns(:attachment).attachable_type.should == Page.to_s
    end

  end

  describe "DELETE /destroy" do
    before do
      @attachment = @note.attachments.create!(:uploaded_data => fixture_file_upload("data/at_small.png", "image/png", true),
                                              :display_name  => "user iconとかの画像です", :user_id => 1)
    end

    it do
      pending
      delete :destroy, :id => @attachment.id
      lambda{ Attachment.find(@attachment) }.should raise_error(ActiveRecord::RecordNotFound)
    end

    it do
      pending
      delete :destroy, :id => @attachment.id
      flash[:notice].should_not be_blank
    end
  end

end

