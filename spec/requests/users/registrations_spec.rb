require "rails_helper"

RSpec.describe "Users::Registrations", type: :request do
  describe "DELETE /users" do
    let!(:user) { create(:user, name: "削除テストユーザー") }

    before { sign_in user }

    context "正しいユーザーネームを入力し削除確認を完了した場合" do
      it "ユーザーが削除され、通知付きでトップページへリダイレクトされること" do
        expect do
          delete user_registration_path, params: { user: { delete_confirmation: user.name } }
        end.to change(User, :count).by(-1)

        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to be_present
      end
    end

    context "誤ったユーザーネームを入力して削除確認に失敗した場合" do
      it "ユーザーは削除されず、モーダルが再表示され入力内容が保持されること" do
        expect do
          delete user_registration_path, params: { user: { delete_confirmation: "別の名前" } }
        end.not_to change(User, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("ユーザーネームが一致しません。")
        expect(response.body).to include("delete_confirm_modal")
        expect(response.body).to include("value=\"別の名前\"")
      end
    end
  end
end
