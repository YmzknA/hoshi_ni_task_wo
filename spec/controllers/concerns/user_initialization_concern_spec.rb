require 'rails_helper'

RSpec.describe UserInitializationConcern, type: :concern do
  # ダミーコントローラーでConcernをテスト
  let(:dummy_controller) do
    Class.new do
      include UserInitializationConcern
    end.new
  end

  describe "#initialize_new_user" do
    let(:new_user) { build(:user) }
    let(:existing_user) { build(:user) }

    before do
      # new_user?メソッドをスタブ
      allow(new_user).to receive(:new_user?).and_return(true)
      allow(existing_user).to receive(:new_user?).and_return(false)
      
      # UserRegistration::MakeTasksMilestonesをスタブ
      allow(UserRegistration::MakeTasksMilestones).to receive(:create_tasks_and_milestones)
    end

    context "新規ユーザーの場合" do
      it "初期データ作成サービスが呼ばれる" do
        dummy_controller.send(:initialize_new_user, new_user)
        
        expect(UserRegistration::MakeTasksMilestones).to have_received(:create_tasks_and_milestones).with(new_user)
      end
    end

    context "既存ユーザーの場合" do
      it "初期データ作成サービスが呼ばれない" do
        dummy_controller.send(:initialize_new_user, existing_user)
        
        expect(UserRegistration::MakeTasksMilestones).not_to have_received(:create_tasks_and_milestones)
      end
    end

    context "ユーザーがnilの場合" do
      it "初期データ作成サービスが呼ばれない" do
        dummy_controller.send(:initialize_new_user, nil)
        
        expect(UserRegistration::MakeTasksMilestones).not_to have_received(:create_tasks_and_milestones)
      end
    end

    context "ユーザーがnew_user?メソッドを持たない場合" do
      let(:invalid_user) { Object.new }

      it "エラーが発生しない" do
        expect {
          dummy_controller.send(:initialize_new_user, invalid_user)
        }.not_to raise_error
        
        expect(UserRegistration::MakeTasksMilestones).not_to have_received(:create_tasks_and_milestones)
      end
    end
  end

  # 実際のコントローラーでの統合テスト
  describe "統合テスト" do
    describe Users::RegistrationsController do
      it "UserInitializationConcernが含まれている" do
        expect(Users::RegistrationsController.included_modules).to include(UserInitializationConcern)
      end
    end

    describe Users::OmniauthCallbacksController do
      it "UserInitializationConcernが含まれている" do
        expect(Users::OmniauthCallbacksController.included_modules).to include(UserInitializationConcern)
      end
    end
  end
end