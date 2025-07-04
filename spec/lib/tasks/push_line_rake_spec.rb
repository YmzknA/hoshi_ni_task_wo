require "rails_helper"
require "rake"

RSpec.describe "push_line:send_daily_task_notifications", type: :task do
  include ActiveSupport::Testing::TimeHelpers
  before do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
  end

  let(:task) { Rake::Task["push_line:send_daily_task_notifications"] }

  before do
    task.reenable
  end

  describe "notification時間に基づく通知送信" do
    let!(:user_9am) do
      create(:user, :with_notifications, :with_oauth, notification_time: 9, email: "user9am@example.com",
                                                      uid: "user9am")
    end
    let!(:user_12pm) do
      create(:user, :with_notifications, :with_oauth, notification_time: 12, email: "user12pm@example.com",
                                                      uid: "user12pm")
    end
    let!(:user_notifications_disabled) do
      create(:user, :with_oauth, notification_time: 9, is_notifications_enabled: false,
                                 email: "user_disabled@example.com", uid: "user_disabled")
    end
    let!(:user_no_oauth) do
      create(:user, :with_notifications, notification_time: 9, email: "user_no_oauth@example.com")
    end

    before do
      allow(LineTaskNotifier).to receive(:new).and_return(double("notifier", send_daily_notifications: true))
    end

    context "現在時刻が9時の場合" do
      before do
        travel_to Time.zone.parse("2023-01-01 09:00:00")
      end

      after do
        travel_back
      end

      it "9時に設定されたユーザーのみに通知が送信される" do
        expect(LineTaskNotifier).to receive(:new).with(user_9am).once
        expect(LineTaskNotifier).not_to receive(:new).with(user_12pm)
        expect(LineTaskNotifier).not_to receive(:new).with(user_notifications_disabled)
        expect(LineTaskNotifier).not_to receive(:new).with(user_no_oauth)

        task.execute
      end
    end

    context "現在時刻が12時の場合" do
      before do
        travel_to Time.zone.parse("2023-01-01 12:00:00")
      end

      after do
        travel_back
      end

      it "12時に設定されたユーザーのみに通知が送信される" do
        expect(LineTaskNotifier).to receive(:new).with(user_12pm).once
        expect(LineTaskNotifier).not_to receive(:new).with(user_9am)
        expect(LineTaskNotifier).not_to receive(:new).with(user_notifications_disabled)
        expect(LineTaskNotifier).not_to receive(:new).with(user_no_oauth)

        task.execute
      end
    end

    context "該当する時間のユーザーがいない場合" do
      before do
        travel_to Time.zone.parse("2023-01-01 15:00:00")
      end

      after do
        travel_back
      end

      it "通知が送信されない" do
        expect(LineTaskNotifier).not_to receive(:new)
        task.execute
      end
    end
  end
end
