require "rails_helper"

RSpec.describe UsersController, type: :request do
  let(:user) { create(:user, :with_oauth) }
  let(:other_user) { create(:user, :with_oauth) }

  before do
    sign_in user
  end

  describe "PATCH /users/:id/update_notification_time" do
    context "自分のユーザー設定を更新する場合" do
      it "通知時間が正常に更新される" do
        expect {
          patch update_notification_time_user_path(user), params: { user: { notification_time: 15 } }
        }.to change { user.reload.notification_time }.from(9).to(15)

        expect(response).to have_http_status(:success)
      end

      it "無効な時間の場合は更新されない" do
        expect {
          patch update_notification_time_user_path(user), params: { user: { notification_time: 25 } }
        }.not_to change { user.reload.notification_time }
      end

      it "0-23の範囲内の時間は有効" do
        [0, 12, 23].each do |time|
          patch update_notification_time_user_path(user), params: { user: { notification_time: time } }
          expect(user.reload.notification_time).to eq(time)
        end
      end
    end

    context "他のユーザーの設定を更新しようとする場合" do
      it "更新が拒否される" do
        expect {
          patch update_notification_time_user_path(other_user), params: { user: { notification_time: 15 } }
        }.not_to change { other_user.reload.notification_time }

        expect(response).to redirect_to(root_path)
      end
    end

    context "ログインしていない場合" do
      before do
        sign_out user
      end

      it "ログインページにリダイレクトされる" do
        patch update_notification_time_user_path(user), params: { user: { notification_time: 15 } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end