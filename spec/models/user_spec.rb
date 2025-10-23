require "rails_helper"

RSpec.describe User, type: :model do
  describe "validation" do
    subject { build(:user) }

    it "factoryが有効であること" do
      expect(subject).to be_valid
    end

    describe "presence validations" do
      it { should validate_presence_of(:name).with_message("が入力されていません。") }
      it { should validate_presence_of(:email).with_message("が入力されていません。") }
      it { should validate_presence_of(:password).with_message("が入力されていません。") }
      it { should validate_presence_of(:notification_time) }
    end

    describe "length validations" do
      it { should validate_length_of(:name).is_at_most(20).with_message("は20文字以下に設定して下さい。") }
      it { should validate_length_of(:bio).is_at_most(200).with_message("は200文字以内で入力してください") }
      it { should validate_length_of(:password).is_at_least(6).with_message("は6文字以上に設定して下さい。") }
    end

    describe "uniqueness validations" do
      it { should validate_uniqueness_of(:email).case_insensitive.with_message("は既に使用されています。") }
    end

    describe "inclusion validations" do
      it { should validate_inclusion_of(:notification_time).in_range(0..23) }
    end

    describe "confirmation validation" do
      it { should validate_confirmation_of(:password).with_message("がパスワードと一致していません。") }
    end

    context "email format" do
      it "有効なメールアドレス形式であること" do
        valid_emails = %w[user@example.com test.email@example.co.jp user+tag@example.org]
        valid_emails.each do |email|
          subject.email = email
          expect(subject).to be_valid, "#{email} should be valid"
        end
      end

      it "無効なメールアドレス形式の場合無効であること" do
        invalid_emails = %w[user.com usercom]
        invalid_emails.each do |email|
          subject.email = email
          expect(subject).to_not be_valid, "#{email} should be invalid"
          expect(subject.errors[:email]).to include("は有効でありません。")
        end
      end
    end

    context "bio optional validation" do
      it "Bioが空の場合有効であること" do
        subject.bio = nil
        expect(subject).to be_valid
      end

      it "Bioが空文字の場合有効であること" do
        subject.bio = ""
        expect(subject).to be_valid
      end
    end

    context "uid conditional uniqueness" do
      let!(:existing_user) { create(:user, :with_oauth) }

      it "providerがある場合、uidの一意性が検証されること" do
        subject.provider = "line"
        subject.uid = "123456789"
        expect(subject).to_not be_valid
        expect(subject.errors[:uid]).to include("はすでに存在します")
      end

      it "providerが空の場合、uidの検証は行われないこと" do
        subject.provider = nil
        subject.uid = "123456789"
        expect(subject).to be_valid
      end

      it "異なるproviderの場合、同じuidでも有効であること" do
        subject.provider = "google"
        subject.uid = "123456789"
        expect(subject).to be_valid
      end
    end
  end

  describe "associations" do
    it { should have_many(:tasks).dependent(:destroy) }
    it { should have_many(:milestones).dependent(:destroy) }
    it { should have_many(:limited_sharing_milestones).dependent(:destroy) }
    it { should have_many(:limited_sharing_tasks).dependent(:destroy) }
  end

  describe "scope" do
    describe ".notifications_enabled" do
      let!(:user_with_notifications) { create(:user, :with_notifications) }
      let!(:user_without_notifications) { create(:user) }

      it "通知が有効なユーザーのみを返すこと" do
        expect(User.notifications_enabled).to include(user_with_notifications)
        expect(User.notifications_enabled).not_to include(user_without_notifications)
      end

      it "通知が有効なユーザーの数が正しいこと" do
        expect(User.notifications_enabled.count).to eq(1)
      end
    end
  end

  describe "instanceメソッド" do
    let(:user) { build(:user) }
    let(:guest_user) { build(:user, :guest) }
    let(:oauth_user) { build(:user, :with_oauth) }

    describe "#guest?" do
      it "ゲストユーザーの場合trueを返すこと" do
        expect(guest_user.guest?).to be true
      end

      it "通常ユーザーの場合falseを返すこと" do
        expect(user.guest?).to be false
      end

      it "is_guestがfalseの場合falseを返すこと" do
        user.is_guest = false
        expect(user.guest?).to be false
      end

      it "is_guestがnilの場合falseを返すこと" do
        user.is_guest = nil
        expect(user.guest?).to be false
      end
    end

    describe "#notifications_enabled?" do
      it "通知が有効な場合trueを返すこと" do
        user.is_notifications_enabled = true
        expect(user.notifications_enabled?).to be true
      end

      it "通知が無効な場合falseを返すこと" do
        user.is_notifications_enabled = false
        expect(user.notifications_enabled?).to be false
      end

      it "is_notifications_enabledがnilの場合falseを返すこと" do
        user.is_notifications_enabled = nil
        expect(user.notifications_enabled?).to be false
      end
    end

    describe "#uid_required?" do
      it "providerがある場合trueを返すこと" do
        expect(oauth_user.uid_required?).to be true
      end

      it "providerがない場合falseを返すこと" do
        expect(user.uid_required?).to be false
      end

      it "providerが空文字の場合falseを返すこと" do
        user.provider = ""
        expect(user.uid_required?).to be false
      end

      it "providerがnilの場合falseを返すこと" do
        user.provider = nil
        expect(user.uid_required?).to be false
      end
    end

    describe "#completed_tasks_hidden?" do
      it "is_hide_completed_tasksがtrueの場合trueを返すこと" do
        user.is_hide_completed_tasks = true
        expect(user.completed_tasks_hidden?).to be true
      end

      it "is_hide_completed_tasksがfalseの場合falseを返すこと" do
        user.is_hide_completed_tasks = false
        expect(user.completed_tasks_hidden?).to be false
      end

      it "is_hide_completed_tasksがnilの場合falseを返すこと" do
        user.is_hide_completed_tasks = nil
        expect(user.completed_tasks_hidden?).to be false
      end

      describe "#set_values" do
        let(:omniauth_hash) do
          {
            "provider" => "line",
            "uid" => "123456789",
            "credentials" => {
              "refresh_token" => "refresh_token_value",
              "secret" => "secret_value"
            },
            "info" => {
              "name" => "Test User"
            }
          }
        end

        it "providerとuidが一致する場合、値を設定すること" do
          expect(oauth_user.set_values(omniauth_hash)).to be_truthy
        end

        it "providerが一致しない場合、早期returnすること" do
          omniauth_hash["provider"] = "google"
          expect(oauth_user.set_values(omniauth_hash)).to be_nil
        end

        it "uidが一致しない場合、早期returnすること" do
          omniauth_hash["uid"] = "different_uid"
          expect(oauth_user.set_values(omniauth_hash)).to be_nil
        end
      end
    end
  end

  describe "classメソッド" do
    describe ".guest" do
      subject { User.guest }

      it "新しいゲストユーザーを作成すること" do
        expect { subject }.to change(User, :count).by(1)
      end

      it "作成されたユーザーはゲストユーザーであること" do
        expect(subject.is_guest).to be true
        expect(subject.name).to eq "ゲストユーザー"
        expect(subject.email).to match(/guest_.*@example\.com/)
        expect(subject.password).to eq "password"
      end

      it "bioが適切に設定されること" do
        expected_bio = <<~BIO
          ゲストユーザーです。
          星座やタスクの作成や編集、削除は出来ませんが、一部の機能を体験できます。
          ぜひ、アカウントを作成して、全ての機能を体験してみてください！
        BIO
        expect(subject.bio).to eq expected_bio
      end

      it "毎回異なるメールアドレスが生成されること" do
        guest1 = User.guest
        guest2 = User.guest
        expect(guest1.email).not_to eq(guest2.email)
      end

      it "ゲストユーザーとして識別されること" do
        expect(subject.guest?).to be true
      end
    end
  end

  describe "Devise設定" do
    it "データベース認証が有効であること" do
      expect(User.devise_modules).to include(:database_authenticatable)
    end

    it "ユーザー登録が有効であること" do
      expect(User.devise_modules).to include(:registerable)
    end

    it "パスワード回復が有効であること" do
      expect(User.devise_modules).to include(:recoverable)
    end

    it "ログイン状態記憶が有効であること" do
      expect(User.devise_modules).to include(:rememberable)
    end

    it "バリデーションが有効であること" do
      expect(User.devise_modules).to include(:validatable)
    end

    it "OAuth認証が有効であること" do
      expect(User.devise_modules).to include(:omniauthable)
    end

    it "LINEプロバイダーが設定されていること" do
      expect(User.omniauth_providers).to include(:line)
    end
  end

  describe "factory" do
    describe ":user" do
      it "有効なユーザーを作成すること" do
        user = build(:user)
        expect(user).to be_valid
      end
    end

    describe ":guest trait" do
      it "ゲストユーザーを作成すること" do
        user = build(:user, :guest)
        expect(user.is_guest).to be true
      end
    end

    describe ":with_notifications trait" do
      it "通知有効ユーザーを作成すること" do
        user = build(:user, :with_notifications)
        expect(user.is_notifications_enabled).to be true
      end
    end

    describe ":with_oauth trait" do
      it "OAuth ユーザーを作成すること" do
        user = build(:user, :with_oauth)
        expect(user.provider).to eq "line"
        expect(user.uid).to be_present
      end
    end
  end
end
