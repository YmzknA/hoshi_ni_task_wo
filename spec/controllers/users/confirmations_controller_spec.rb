require 'rails_helper'

RSpec.describe Users::ConfirmationsController, type: :controller do
  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe "GET #show" do
    let(:user) { create(:user, confirmed_at: nil) }
    let(:confirmation_token) { user.confirmation_token }

    context "有効なトークンの場合" do
      it "ユーザーが認証される" do
        get :show, params: { confirmation_token: confirmation_token }
        
        user.reload
        expect(user.confirmed_at).to be_present
      end

      it "認証完了後のフラッシュメッセージが表示される" do
        get :show, params: { confirmation_token: confirmation_token }
        
        expect(flash[:notice]).to be_present
      end

      it "認証完了後に適切なページにリダイレクトされる" do
        get :show, params: { confirmation_token: confirmation_token }
        
        expect(response).to redirect_to(how_to_use_path)
      end
    end

    context "無効なトークンの場合" do
      it "ユーザーが認証されない" do
        get :show, params: { confirmation_token: "invalid_token" }
        
        user.reload
        expect(user.confirmed_at).to be_nil
      end

      it "エラーが表示される" do
        get :show, params: { confirmation_token: "invalid_token" }
        
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "トークンが期限切れの場合" do
      before do
        user.update(confirmation_sent_at: 25.hours.ago)
      end

      it "ユーザーが認証されない" do
        get :show, params: { confirmation_token: confirmation_token }
        
        user.reload
        expect(user.confirmed_at).to be_nil
      end
    end
  end

  describe "POST #create" do
    context "有効なメールアドレスの場合" do
      let(:user) { create(:user, confirmed_at: nil) }

      it "認証メールが再送される" do
        expect {
          post :create, params: { user: { email: user.email } }
        }.to change { ActionMailer::Base.deliveries.count }.by(1)
      end

      it "成功メッセージが表示される" do
        post :create, params: { user: { email: user.email } }
        
        expect(flash[:notice]).to be_present
      end

      it "ルートページにリダイレクトされる" do
        post :create, params: { user: { email: user.email } }
        
        expect(response).to redirect_to(root_path)
      end
    end

    context "存在しないメールアドレスの場合" do
      it "paranoid設定により同じメッセージが表示される" do
        post :create, params: { user: { email: "nonexistent@example.com" } }
        
        expect(flash[:notice]).to be_present
      end
    end

    context "空のメールアドレスの場合" do
      it "エラーが表示される" do
        post :create, params: { user: { email: "" } }
        
        expect(response).to render_template(:new)
      end
    end
  end
end