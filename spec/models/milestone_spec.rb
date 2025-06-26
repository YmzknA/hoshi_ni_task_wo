require "rails_helper"

RSpec.describe Milestone, type: :model do
  describe "validation" do
    subject { build(:milestone) }

    it "factoryが有効であること" do
      expect(subject).to be_valid
    end

    describe "presence validations" do
      it { should validate_presence_of(:title) }
      it { should validate_presence_of(:progress) }
      it { should validate_presence_of(:color) }
    end

    describe "length validations" do
      it { should validate_length_of(:description).is_at_most(150) }
      it { should validate_length_of(:completed_comment).is_at_most(50) }
    end

    describe "date validations" do
      let(:user) { create(:user) }

      context "開始日と終了日の関係" do
        let(:base_date) { Date.new(2025, 6, 1) }

        it "開始日が終了日より前の場合有効であること" do
          milestone = build(:milestone, user: user, start_date: base_date, end_date: base_date + 1.day)
          expect(milestone).to be_valid
        end

        it "開始日が終了日より後の場合無効であること" do
          milestone = build(:milestone, user: user, start_date: base_date + 1.day, end_date: base_date)
          expect(milestone).not_to be_valid
          expect(milestone.errors[:start_date]).to include("は終了日より前の日付を設定してください")
          expect(milestone.errors[:end_date]).to include("は開始日より後の日付を設定してください")
        end

        it "開始日と終了日が同じ場合無効であること" do
          milestone = build(:milestone, user: user, start_date: base_date, end_date: base_date)
          expect(milestone).not_to be_valid
          expect(milestone.errors[:start_date]).to include("は終了日より前の日付を設定してください")
        end
      end

      context "チャート表示時の日付要件" do
        let(:chart_start_date) { Date.new(2025, 6, 1) }
        let(:chart_end_date) { Date.new(2025, 6, 30) }

        it "チャート表示がtrueで両方の日付がある場合有効であること" do
          milestone = build(:milestone, user: user, is_on_chart: true,
                                        start_date: chart_start_date, end_date: chart_end_date)
          expect(milestone).to be_valid
        end

        it "チャート表示がtrueで開始日がない場合無効であること" do
          milestone = build(:milestone, user: user, is_on_chart: true, start_date: nil, end_date: chart_end_date)
          expect(milestone).not_to be_valid
          expect(milestone.errors[:start_date]).to include("チャートに表示する場合、開始日と終了日を設定してください")
        end

        it "チャート表示がtrueで終了日がない場合無効であること" do
          milestone = build(:milestone, user: user, is_on_chart: true, start_date: chart_start_date, end_date: nil)
          expect(milestone).not_to be_valid
          expect(milestone.errors[:start_date]).to include("チャートに表示する場合、開始日と終了日を設定してください")
        end

        it "チャート表示がfalseで日付がない場合有効であること" do
          milestone = build(:milestone, user: user, is_on_chart: false, start_date: nil, end_date: nil)
          expect(milestone).to be_valid
        end
      end

      context "チャート表示時のタスク日付要件" do
        let(:milestone) { create(:milestone, :on_chart, user: user) }

        it "チャート表示時にタスクに日付がない場合無効であること" do
          task = build(:task, milestone: milestone, user: user, start_date: nil, end_date: nil)
          task.save(validate: false)  # taskのバリデーションを回避
          milestone.reload
          expect(milestone).not_to be_valid
          expect(milestone.errors[:base]).to include(/チャートに表示する場合、タスク「title: .+」は開始日か終了日の少なくとも一方を設定してください/)
        end

        it "チャート表示時にタスクに開始日がある場合有効であること" do
          create(:task, milestone: milestone, user: user, start_date: milestone.start_date + 1.day, end_date: nil)
          milestone.reload
          expect(milestone).to be_valid
        end

        it "チャート表示時にタスクに終了日がある場合有効であること" do
          create(:task, milestone: milestone, user: user, start_date: nil, end_date: milestone.end_date - 1.day)
          milestone.reload
          expect(milestone).to be_valid
        end
      end

      context "タスクの日付範囲チェック" do
        let(:milestone_start) { Date.new(2025, 6, 1) }
        let(:milestone_end) { Date.new(2025, 6, 30) }
        let(:milestone) do
          create(:milestone, user: user, is_on_chart: true, start_date: milestone_start, end_date: milestone_end)
        end

        it "タスクの開始日が星座の開始日より前の場合無効であること" do
          task = build(:task, milestone: milestone, user: user,
                              start_date: milestone_start - 1.day, end_date: milestone_start + 1.day)
          task.save(validate: false)  # taskのバリデーションを回避
          milestone.reload
          expect(milestone).not_to be_valid
          expect(milestone.errors[:start_date]).to include("は紐づくタスクの開始日以前に設定してください。タスクは星座の期間内に収まる必要があります")
        end

        it "タスクの終了日が星座の終了日より後の場合無効であること" do
          task = build(:task, milestone: milestone, user: user,
                              start_date: milestone_end - 1.day, end_date: milestone_end + 1.day)
          task.save(validate: false)  # taskのバリデーションを回避
          milestone.reload
          expect(milestone).not_to be_valid
          expect(milestone.errors[:end_date]).to include("は紐づくタスクの終了日以降に設定してください。タスクは星座の期間内に収まる必要があります")
        end

        it "タスクの日付が星座の日付範囲内の場合有効であること" do
          create(:task, milestone: milestone, user: user,
                        start_date: milestone_start + 1.day, end_date: milestone_end - 1.day)
          milestone.reload
          expect(milestone).to be_valid
        end
      end
    end
  end

  describe "associations" do
    it { should have_many(:tasks).dependent(:nullify) }
    it { should belong_to(:user) }
    it { should belong_to(:constellation).optional }
  end

  describe "enums" do
    it { should define_enum_for(:progress).with_values(not_started: 0, in_progress: 1, completed: 2) }
  end

  describe "scope" do
    let(:user) { create(:user) }
    let!(:on_chart_milestone) { create(:milestone, user: user, is_on_chart: true) }
    let!(:off_chart_milestone) { create(:milestone, user: user, is_on_chart: false) }
    let!(:completed_milestone) { create(:milestone, user: user, progress: :completed) }
    let!(:not_started_milestone) { create(:milestone, user: user, progress: :not_started) }
    let!(:in_progress_milestone) { create(:milestone, user: user, progress: :in_progress) }

    describe ".on_chart" do
      it "チャート表示対象の星座のみを返すこと" do
        expect(Milestone.on_chart).to include(on_chart_milestone)
        expect(Milestone.on_chart).not_to include(off_chart_milestone)
      end
    end

    describe ".not_completed" do
      it "未完了の星座のみを返すこと" do
        results = Milestone.not_completed
        expect(results).to include(not_started_milestone, in_progress_milestone)
        expect(results).not_to include(completed_milestone)
      end
    end

    describe ".start_date_asc" do
      let!(:early_milestone) do
        create(:milestone, user: user, start_date: Date.new(2025, 1, 1), end_date: Date.new(2025, 1, 5))
      end
      let!(:late_milestone) do
        create(:milestone, user: user, start_date: Date.new(2025, 2, 1), end_date: Date.new(2025, 2, 5))
      end

      it "開始日の昇順で星座を並べ替えること" do
        results = Milestone.where(id: [early_milestone.id, late_milestone.id]).start_date_asc
        expect(results.first).to eq(early_milestone)
        expect(results.last).to eq(late_milestone)
      end
    end

    describe ".index_order" do
      let!(:nil_date_milestone) { create(:milestone, user: user, start_date: nil, end_date: nil, is_on_chart: false) }
      let!(:early_milestone) do
        create(:milestone, user: user, start_date: Date.new(2025, 1, 1), end_date: Date.new(2025, 1, 5))
      end
      let!(:late_milestone) do
        create(:milestone, user: user, start_date: Date.new(2025, 2, 1), end_date: Date.new(2025, 2, 5))
      end

      it "日付なしの星座を最後に、その後開始日、終了日順で並べ替えること" do
        ordered = Milestone.where(id: [nil_date_milestone.id, early_milestone.id, late_milestone.id]).index_order
        expect(ordered[0]).to eq(early_milestone)
        expect(ordered[1]).to eq(late_milestone)
        expect(ordered.last).to eq(nil_date_milestone)
      end
    end
  end

  describe "instanceメソッド" do
    let(:user) { create(:user) }

    describe "#completed?" do
      it "進捗が完了の場合trueを返すこと" do
        milestone = create(:milestone, user: user, progress: :completed)
        expect(milestone.completed?).to be true
      end

      it "進捗が未完了の場合falseを返すこと" do
        milestone = create(:milestone, user: user, progress: :not_started)
        expect(milestone.completed?).to be false
      end
    end

    describe "#tasks_completed?" do
      let(:milestone) { create(:milestone, user: user, is_on_chart: false) }

      it "すべてのタスクが完了している場合trueを返すこと" do
        create(:task, milestone: milestone, user: user, progress: :completed)
        create(:task, milestone: milestone, user: user, progress: :completed)
        expect(milestone.tasks_completed?).to be true
      end

      it "一部のタスクが未完了の場合falseを返すこと" do
        create(:task, milestone: milestone, user: user, progress: :completed)
        create(:task, milestone: milestone, user: user, progress: :not_started)
        expect(milestone.tasks_completed?).to be false
      end

      it "タスクがない場合trueを返すこと" do
        expect(milestone.tasks_completed?).to be true
      end
    end

    describe "#completed_tasks_percentage" do
      let(:milestone) { create(:milestone, user: user, is_on_chart: false) }

      it "タスクがない場合0を返すこと" do
        expect(milestone.completed_tasks_percentage).to eq(0)
      end

      it "一部のタスクが完了している場合正しい割合を返すこと" do
        create(:task, milestone: milestone, user: user, progress: :completed)
        create(:task, milestone: milestone, user: user, progress: :not_started)
        expect(milestone.completed_tasks_percentage).to eq(50)
      end

      it "すべてのタスクが完了している場合100を返すこと" do
        create(:task, milestone: milestone, user: user, progress: :completed)
        create(:task, milestone: milestone, user: user, progress: :completed)
        expect(milestone.completed_tasks_percentage).to eq(100)
      end
    end

    describe "#update_progress" do
      let(:milestone) { create(:milestone, user: user, progress: :not_started, is_on_chart: false) }

      it "タスクがない場合進捗を未着手に設定すること" do
        milestone.update_progress
        expect(milestone.progress).to eq("not_started")
      end

      it "進行中のタスクがある場合進捗を進行中に設定すること" do
        create(:task, milestone: milestone, user: user, progress: :in_progress)
        milestone.update_progress
        expect(milestone.progress).to eq("in_progress")
      end

      it "完了したタスクがある場合進捗を進行中に設定すること" do
        create(:task, milestone: milestone, user: user, progress: :completed)
        milestone.update_progress
        expect(milestone.progress).to eq("in_progress")
      end

      it "すべてのタスクが未着手の場合進捗を未着手に設定すること" do
        create(:task, milestone: milestone, user: user, progress: :not_started)
        create(:task, milestone: milestone, user: user, progress: :not_started)
        milestone.update_progress
        expect(milestone.progress).to eq("not_started")
      end
    end

    describe "#public?" do
      it "公開設定がtrueの場合trueを返すこと" do
        milestone = create(:milestone, user: user, is_public: true)
        expect(milestone.public?).to be true
      end

      it "公開設定がfalseの場合falseを返すこと" do
        milestone = create(:milestone, user: user, is_public: false)
        expect(milestone.public?).to be false
      end
    end

    describe "#open?" do
      it "オープン設定がtrueの場合trueを返すこと" do
        milestone = create(:milestone, user: user, is_open: true)
        expect(milestone.open?).to be true
      end

      it "オープン設定がfalseの場合falseを返すこと" do
        milestone = create(:milestone, user: user, is_open: false)
        expect(milestone.open?).to be false
      end
    end

    describe "#on_chart?" do
      it "チャート表示設定がtrueの場合trueを返すこと" do
        milestone = create(:milestone, user: user, is_on_chart: true)
        expect(milestone.on_chart?).to be true
      end

      it "チャート表示設定がfalseの場合falseを返すこと" do
        milestone = create(:milestone, user: user, is_on_chart: false)
        expect(milestone.on_chart?).to be false
      end
    end

    describe "#copy" do
      let(:constellation) { create(:constellation) }
      let(:original_start_date) { Date.new(2025, 6, 1) }
      let(:original_end_date) { Date.new(2025, 6, 6) } # 5日間の期間
      let(:new_start_date) { Date.new(2025, 7, 1) }
      let(:milestone) do
        create(:milestone, user: user, title: "Original", progress: :completed, completed_comment: "Done",
                           constellation: constellation, start_date: original_start_date, end_date: original_end_date)
      end
      let(:set_date) { new_start_date }

      it "属性が修正されたコピーを作成すること" do
        copy = milestone.copy(set_date)

        expect(copy.title).to eq("Original_copy")
        expect(copy.progress).to eq("not_started")
        expect(copy.completed_comment).to be_nil
        expect(copy.constellation).to be_nil
        expect(copy.user).to eq(milestone.user)
        expect(copy.description).to eq(milestone.description)
      end

      context "開始日と終了日が両方存在する場合" do
        it "期間を維持して両方の日付を調整すること" do
          copy = milestone.copy(set_date)
          expected_duration = (original_end_date - original_start_date).to_i

          expect(copy.start_date).to eq(set_date)
          expect(copy.end_date).to eq(set_date + expected_duration.days)
        end
      end

      context "開始日のみ存在する場合" do
        let(:milestone) do
          create(:milestone, user: user, start_date: original_start_date, end_date: nil, is_on_chart: false)
        end

        it "開始日のみを調整すること" do
          copy = milestone.copy(set_date)

          expect(copy.start_date).to eq(set_date)
          expect(copy.end_date).to be_nil
        end
      end

      context "終了日のみ存在する場合" do
        let(:milestone) do
          create(:milestone, user: user, start_date: nil, end_date: original_end_date, is_on_chart: false)
        end

        it "終了日のみを調整すること" do
          copy = milestone.copy(set_date)

          expect(copy.start_date).to be_nil
          expect(copy.end_date).to eq(set_date)
        end
      end

      context "両方の日付がnilの場合" do
        let(:milestone) { create(:milestone, user: user, start_date: nil, end_date: nil, is_on_chart: false) }

        it "両方の日付をnilのまま保持すること" do
          copy = milestone.copy(set_date)

          expect(copy.start_date).to be_nil
          expect(copy.end_date).to be_nil
        end
      end
    end
  end

  describe "classメソッド" do
    describe ".ransackable_attributes" do
      it "ransackで利用可能な属性を返すこと" do
        expect(Milestone.ransackable_attributes).to eq(%w[title description start_date end_date])
      end
    end

    describe ".ransackable_associations" do
      it "ransackで利用可能な関連を返すこと" do
        expect(Milestone.ransackable_associations).to eq(%w[tasks])
      end
    end
  end

  describe "factory" do
    describe ":milestone" do
      it "有効な星座を作成すること" do
        milestone = build(:milestone)
        expect(milestone).to be_valid
      end
    end

    describe ":completed trait" do
      it "完了状態の星座を作成すること" do
        milestone = build(:milestone, :completed)
        expect(milestone.progress).to eq("completed")
        expect(milestone.completed_comment).to be_present
      end
    end

    describe ":on_chart trait" do
      it "チャート表示対象の星座を作成すること" do
        milestone = build(:milestone, :on_chart)
        expect(milestone.is_on_chart).to be true
        expect(milestone.start_date).to be_present
        expect(milestone.end_date).to be_present
      end
    end

    describe ":not_on_chart trait" do
      it "チャート非表示の星座を作成すること" do
        milestone = build(:milestone, :not_on_chart)
        expect(milestone.is_on_chart).to be false
      end
    end
  end
end
