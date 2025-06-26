require "rails_helper"

RSpec.describe LimitedSharingTask, type: :model do
  let(:user) { create(:user) }
  let(:milestone) { create(:limited_sharing_milestone, user: user) }

  describe "validation" do
    subject do
      build(:limited_sharing_task, user: user, limited_sharing_milestone_id: milestone.id, create_milestone: false)
    end

    it "factoryが有効であること" do
      expect(subject).to be_valid
    end

    describe "presence validations" do
      it { should validate_presence_of(:title) }
      it { should validate_presence_of(:progress) }
      it { should validate_presence_of(:limited_sharing_milestone_id) }
    end
  end

  describe "associations" do
    it do
      should belong_to(:milestone)
        .class_name("LimitedSharingMilestone")
        .with_foreign_key("limited_sharing_milestone_id")
    end
    it { should belong_to(:user) }
  end

  describe "enums" do
    it { should define_enum_for(:progress).with_values(not_started: 0, in_progress: 1, completed: 2) }
  end

  describe "scope" do
    describe ".valid_dates_nil" do
      let!(:task_with_dates) do
        create(:limited_sharing_task, user: user,
                                      limited_sharing_milestone_id: milestone.id,
                                      start_date: Date.new(2025, 6, 1),
                                      end_date: Date.new(2025, 6, 10),
                                      create_milestone: false)
      end
      let!(:task_without_dates) do
        create(:limited_sharing_task, :no_dates, user: user,
                                                 limited_sharing_milestone_id: milestone.id,
                                                 create_milestone: false)
      end

      it "両方の日付がnilでないタスクのみを返すこと" do
        expect(LimitedSharingTask.valid_dates_nil).to include(task_with_dates)
        expect(LimitedSharingTask.valid_dates_nil).not_to include(task_without_dates)
      end
    end

    describe ".start_date_asc" do
      let!(:early_task) do
        create(:limited_sharing_task, user: user,
                                      limited_sharing_milestone_id: milestone.id,
                                      start_date: Date.new(2025, 1, 1),
                                      create_milestone: false)
      end
      let!(:late_task) do
        create(:limited_sharing_task, user: user,
                                      limited_sharing_milestone_id: milestone.id,
                                      start_date: Date.new(2025, 6, 1),
                                      create_milestone: false)
      end

      it "開始日の昇順でタスクを並べ替えること" do
        results = LimitedSharingTask.where(id: [early_task.id, late_task.id])
                                    .start_date_asc
        expect(results.first).to eq(early_task)
        expect(results.last).to eq(late_task)
      end
    end
  end

  describe "instanceメソッド" do
    let(:completed_milestone) do
      create(:limited_sharing_milestone, user: user, progress: :completed)
    end
    let(:task) do
      create(:limited_sharing_task, user: user,
                                    limited_sharing_milestone_id: completed_milestone.id,
                                    create_milestone: false)
    end

    describe "#milestone_completed?" do
      it "星座が完了している場合trueを返すこと" do
        expect(task.milestone_completed?).to be true
      end

      it "星座が未完了の場合falseを返すこと" do
        completed_milestone.update(progress: :not_started)
        expect(task.milestone_completed?).to be false
      end

      it "星座がnilの場合falseを返すこと" do
        task.update(limited_sharing_milestone_id: nil)
        expect(task.milestone_completed?).to be false
      end
    end

    describe "#completed?" do
      it "進捗が完了の場合trueを返すこと" do
        task.update(progress: :completed)
        expect(task.completed?).to be true
      end

      it "進捗が未完了の場合falseを返すこと" do
        task.update(progress: :not_started)
        expect(task.completed?).to be false
      end
    end

    describe "#in_progress?" do
      it "進捗が進行中の場合trueを返すこと" do
        task.update(progress: :in_progress)
        expect(task.in_progress?).to be true
      end

      it "進捗が進行中でない場合falseを返すこと" do
        task.update(progress: :completed)
        expect(task.in_progress?).to be false
      end
    end

    describe "#not_started?" do
      it "進捗が未着手の場合trueを返すこと" do
        task.update(progress: :not_started)
        expect(task.not_started?).to be true
      end

      it "進捗が未着手でない場合falseを返すこと" do
        task.update(progress: :in_progress)
        expect(task.not_started?).to be false
      end
    end
  end

  describe "NanoidGenerator concern" do
    let(:user) { create(:user) }
    let(:milestone) { create(:limited_sharing_milestone, user: user) }

    describe "#set_id" do
      it "初期化時にユニークなIDが設定されること" do
        task = build(:limited_sharing_task, user: user,
                                            limited_sharing_milestone_id: milestone.id,
                                            create_milestone: false)
        task.save
        expect(task.id).to be_present
        expect(task.id.length).to eq(21)
      end

      it "IDが既に設定されている場合は変更されないこと" do
        existing_id = "existing_test_id_123"
        task = build(:limited_sharing_task, user: user,
                                            limited_sharing_milestone_id: milestone.id,
                                            id: existing_id, create_milestone: false)
        task.save
        expect(task.id).to eq(existing_id)
      end
    end

    describe ".generate_nanoid" do
      it "指定された長さのIDを生成すること" do
        id = LimitedSharingTask.generate_nanoid(size: 10)
        expect(id.length).to eq(10)
      end

      it "指定された文字セットを使用すること" do
        id = LimitedSharingTask.generate_nanoid(alphabet: "abc123",
                                                size: 10)
        expect(id).to match(/\A[abc123]+\z/)
      end
    end
  end

  describe "factory" do
    describe ":limited_sharing_task" do
      it "有効な限定共有タスクを作成すること" do
        task = create(:limited_sharing_task)
        expect(task).to be_valid
      end

      it "関連する星座が自動作成されること" do
        task = create(:limited_sharing_task)
        expect(task.milestone).to be_present
        expect(task.milestone).to be_a(LimitedSharingMilestone)
      end
    end

    describe ":not_started trait" do
      it "未着手状態のタスクを作成すること" do
        task = build(:limited_sharing_task, :not_started)
        expect(task.progress).to eq("not_started")
      end
    end

    describe ":in_progress trait" do
      it "進行中状態のタスクを作成すること" do
        task = build(:limited_sharing_task, :in_progress)
        expect(task.progress).to eq("in_progress")
      end
    end

    describe ":completed trait" do
      it "完了状態のタスクを作成すること" do
        task = build(:limited_sharing_task, :completed)
        expect(task.progress).to eq("completed")
      end
    end

    describe ":no_dates trait" do
      it "日付が設定されていないタスクを作成すること" do
        task = build(:limited_sharing_task, :no_dates)
        expect(task.start_date).to be_nil
        expect(task.end_date).to be_nil
      end
    end
  end
end
