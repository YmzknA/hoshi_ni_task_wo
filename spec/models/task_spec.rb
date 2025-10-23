require "rails_helper"

RSpec.describe Task, type: :model do
  describe "validation" do
    subject { build(:task) }

    it "factoryが有効であること" do
      expect(subject).to be_valid
    end

    describe "presence validations" do
      it { should validate_presence_of(:title) }
      it { should validate_presence_of(:progress) }
    end

    describe "length validations" do
      it { should validate_length_of(:title).is_at_most(25) }
      it { should validate_length_of(:description).is_at_most(150) }
    end

    describe "enum validations" do
      it { should define_enum_for(:progress).with_values([:not_started, :in_progress, :completed]) }
    end

    describe "optional validations" do
      it { should allow_value("").for(:description) }
      it { should allow_value(nil).for(:description) }
    end

    context "title length validation" do
      it "25文字以下の場合有効であること" do
        subject.title = "a" * 25
        expect(subject).to be_valid
      end

      it "26文字以上の場合無効であること" do
        subject.title = "a" * 26
        expect(subject).to_not be_valid
        expect(subject.errors[:title]).to be_present
      end
    end

    context "description length validation" do
      it "150文字以下の場合有効であること" do
        subject.description = "a" * 150
        expect(subject).to be_valid
      end

      it "151文字以上の場合無効であること" do
        subject.description = "a" * 151
        expect(subject).to_not be_valid
        expect(subject.errors[:description]).to be_present
      end
    end

    context "date validations" do
      it "開始日と終了日が同じ場合有効であること" do
        subject.start_date = Date.today
        subject.end_date = Date.today
        expect(subject).to be_valid
      end

      it "開始日のみ設定の場合有効であること" do
        subject.start_date = Date.today
        subject.end_date = nil
        expect(subject).to be_valid
      end

      it "終了日のみ設定の場合有効であること" do
        subject.start_date = nil
        subject.end_date = Date.today + 7.days
        expect(subject).to be_valid
      end

      it "開始日が終了日より後の場合無効であること" do
        subject.start_date = Date.today + 7.days
        subject.end_date = Date.today
        expect(subject).to_not be_valid
        expect(subject.errors[:start_date]).to include("は終了日と同じか、それより前の日付にしてください")
        expect(subject.errors[:end_date]).to include("は開始日と同じか、それより後の日付にしてください")
      end
    end

    context "milestone date validations" do
      let(:user) { create(:user) }

      context "チャートに表示される星座に紐づく場合" do
        let(:chart_milestone) do
          create(:milestone, :on_chart,
                 start_date: Date.today,
                 end_date: Date.today + 30.days,
                 user: user)
        end

        it "日付が設定されていない場合無効であること" do
          subject.milestone = chart_milestone
          subject.start_date = nil
          subject.end_date = nil
          expect(subject).to_not be_valid
          expect(subject.errors[:start_date]).to include("または終了日のいずれかを設定してください。チャートに表示される星座のタスクには日付が必要です")
          expect(subject.errors[:end_date]).to include("または開始日のいずれかを設定してください。チャートに表示される星座のタスクには日付が必要です")
        end

        it "開始日が星座の開始日より前の場合無効であること" do
          subject.milestone = chart_milestone
          subject.start_date = chart_milestone.start_date - 1.day
          subject.end_date = chart_milestone.end_date
          expect(subject).to_not be_valid
          expect(subject.errors[:start_date]).to include("は星座の開始日以降の日付にしてください")
        end

        it "終了日が星座の終了日より後の場合無効であること" do
          subject.milestone = chart_milestone
          subject.start_date = chart_milestone.start_date
          subject.end_date = chart_milestone.end_date + 1.day
          expect(subject).to_not be_valid
          expect(subject.errors[:end_date]).to include("は星座の終了日以前の日付にしてください")
        end

        it "星座の日付範囲内の場合有効であること" do
          subject.milestone = chart_milestone
          subject.start_date = chart_milestone.start_date + 1.day
          subject.end_date = chart_milestone.end_date - 1.day
          expect(subject).to be_valid
        end
      end

      context "チャートに表示されない星座に紐づく場合" do
        let(:not_on_chart_milestone) { create(:milestone, :not_on_chart, user: user) }

        it "日付が設定されていなくても有効であること" do
          subject.milestone = not_on_chart_milestone
          subject.start_date = nil
          subject.end_date = nil
          expect(subject).to be_valid
        end
      end

      context "星座に紐づかない場合" do
        it "日付が設定されていなくても有効であること" do
          subject.milestone = nil
          subject.start_date = nil
          subject.end_date = nil
          expect(subject).to be_valid
        end
      end
    end
  end

  describe "associations" do
    it { should belong_to(:user) }
    it { should belong_to(:milestone).optional }
  end

  describe "scope" do
    let(:user) { create(:user) }
    let!(:not_on_chart_milestone) { create(:milestone, :not_on_chart, user: user) }
    let!(:not_started_task) do
      create(:task, :not_started, milestone: not_on_chart_milestone, start_date: Date.today,
                                  end_date: Date.today + 1.day)
    end
    let!(:in_progress_task) do
      create(:task, :in_progress, milestone: not_on_chart_milestone, start_date: Date.today,
                                  end_date: Date.today + 1.day)
    end
    let!(:completed_task) do
      create(:task, :completed, milestone: not_on_chart_milestone, start_date: Date.today, end_date: Date.today + 1.day)
    end
    let!(:no_dates_task) { create(:task, :no_dates, milestone: not_on_chart_milestone) }
    let!(:without_milestone_task) { create(:task, :without_milestone, :no_dates) }

    describe ".valid_dates_nil" do
      it "開始日と終了日の両方が設定されているタスクを返すこと" do
        expect(Task.valid_dates_nil).to include(not_started_task, in_progress_task, completed_task)
        expect(Task.valid_dates_nil).not_to include(no_dates_task, without_milestone_task)
      end
    end

    describe ".not_started" do
      it "未着手のタスクのみを返すこと" do
        expect(Task.not_started).to include(not_started_task)
        expect(Task.not_started).not_to include(in_progress_task, completed_task)
      end
    end

    describe ".in_progress" do
      it "進行中のタスクのみを返すこと" do
        expect(Task.in_progress).to include(in_progress_task)
        expect(Task.in_progress).not_to include(not_started_task, completed_task)
      end
    end

    describe ".completed" do
      it "完了したタスクのみを返すこと" do
        expect(Task.completed).to include(completed_task)
        expect(Task.completed).not_to include(not_started_task, in_progress_task)
      end
    end

    describe ".not_completed" do
      it "完了していないタスクを返すこと" do
        expect(Task.not_completed).to include(not_started_task, in_progress_task, no_dates_task, without_milestone_task)
        expect(Task.not_completed).not_to include(completed_task)
      end
    end

    describe ".without_milestone" do
      it "星座に紐づかないタスクのみを返すこと" do
        expect(Task.without_milestone).to include(without_milestone_task)
        expect(Task.without_milestone).not_to include(not_started_task, in_progress_task, completed_task, no_dates_task)
      end
    end
  end

  describe "インスタンスメソッド" do
    subject { create(:task) }

    describe "#next_progress" do
      context "未着手の場合" do
        before { subject.update(progress: :not_started) }

        it "進行中を返すこと" do
          expect(subject.next_progress).to eq("in_progress")
        end
      end

      context "進行中の場合" do
        before { subject.update(progress: :in_progress) }

        it "完了を返すこと" do
          expect(subject.next_progress).to eq("completed")
        end
      end

      context "完了の場合" do
        before { subject.update(progress: :completed) }

        it "未着手を返すこと" do
          expect(subject.next_progress).to eq("not_started")
        end
      end
    end

    describe "#milestone_completed?" do
      let(:user) { create(:user) }

      context "星座が完了している場合" do
        let(:completed_milestone) { create(:milestone, :completed, user: user) }

        before { subject.update(milestone: completed_milestone) }

        it "trueを返すこと" do
          expect(subject.milestone_completed?).to be true
        end
      end

      context "星座が完了していない場合" do
        let(:not_completed_milestone) { create(:milestone, progress: :not_started, user: user) }

        before { subject.update(milestone: not_completed_milestone) }

        it "falseを返すこと" do
          expect(subject.milestone_completed?).to be false
        end
      end

      context "星座がない場合" do
        before { subject.update(milestone: nil) }

        it "falseを返すこと" do
          expect(subject.milestone_completed?).to be false
        end
      end
    end

    describe "#completed?" do
      it "完了状態の場合trueを返すこと" do
        subject.update(progress: :completed)
        expect(subject.completed?).to be true
      end

      it "完了状態でない場合falseを返すこと" do
        subject.update(progress: :not_started)
        expect(subject.completed?).to be false
      end
    end

    describe "#in_progress?" do
      it "進行中状態の場合trueを返すこと" do
        subject.update(progress: :in_progress)
        expect(subject.in_progress?).to be true
      end

      it "進行中状態でない場合falseを返すこと" do
        subject.update(progress: :not_started)
        expect(subject.in_progress?).to be false
      end
    end

    describe "#not_started?" do
      it "未着手状態の場合trueを返すこと" do
        subject.update(progress: :not_started)
        expect(subject.not_started?).to be true
      end

      it "未着手状態でない場合falseを返すこと" do
        subject.update(progress: :completed)
        expect(subject.not_started?).to be false
      end
    end

    describe "#copy" do
      let(:original_task) do
        create(:task,
               title: "Original Task",
               description: "Original Description",
               start_date: Date.today,
               end_date: Date.today + 7.days,
               progress: :completed)
      end

      context "開始日と終了日の両方が設定されている場合" do
        it "日付の差を保持してコピーすること" do
          set_date = Date.today + 10.days
          copy = original_task.copy(set_date)

          expect(copy.start_date).to eq(set_date)
          expect(copy.end_date).to eq(set_date + 7.days)
          expect(copy.title).to eq(original_task.title)
          expect(copy.description).to eq(original_task.description)
          expect(copy.progress).to eq(original_task.progress)
        end
      end

      context "開始日のみが設定されている場合" do
        let(:task_with_start_only) do
          create(:task, start_date: Date.today, end_date: nil)
        end

        it "開始日を指定した日付に設定すること" do
          set_date = Date.today + 10.days
          copy = task_with_start_only.copy(set_date)

          expect(copy.start_date).to eq(set_date)
          expect(copy.end_date).to be_nil
        end
      end

      context "終了日のみが設定されている場合" do
        let(:task_with_end_only) do
          create(:task, start_date: nil, end_date: Date.today + 7.days)
        end

        it "終了日を指定した日付に設定すること" do
          set_date = Date.today + 10.days
          copy = task_with_end_only.copy(set_date)

          expect(copy.start_date).to be_nil
          expect(copy.end_date).to eq(set_date)
        end
      end

      context "両方の日付が設定されていない場合" do
        let(:task_no_dates) { create(:task, start_date: nil, end_date: nil) }

        it "日付を変更しないこと" do
          set_date = Date.today + 10.days
          copy = task_no_dates.copy(set_date)

          expect(copy.start_date).to be_nil
          expect(copy.end_date).to be_nil
        end
      end

      it "元のタスクは変更されないこと" do
        set_date = Date.today + 10.days
        original_start_date = original_task.start_date
        original_end_date = original_task.end_date

        original_task.copy(set_date)

        expect(original_task.start_date).to eq(original_start_date)
        expect(original_task.end_date).to eq(original_end_date)
      end
    end
  end

  describe "クラスメソッド" do
    describe ".ransackable_attributes" do
      it "検索可能な属性を返すこと" do
        expected_attributes = %w[created_at description end_date id milestone_id progress start_date title updated_at
                                 user_id]
        expect(Task.ransackable_attributes).to eq(expected_attributes)
      end
    end

    describe ".ransackable_associations" do
      it "検索可能な関連を返すこと" do
        expected_associations = %w[milestone user]
        expect(Task.ransackable_associations).to eq(expected_associations)
      end
    end
  end
end
