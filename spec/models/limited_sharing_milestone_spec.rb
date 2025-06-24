require "rails_helper"

RSpec.describe LimitedSharingMilestone, type: :model do
  let(:user) { create(:user) }

  describe "validation" do
    subject { build(:limited_sharing_milestone, user: user) }

    it "factoryが有効であること" do
      expect(subject).to be_valid
    end

    describe "presence validations" do
      it { should validate_presence_of(:title) }
      it { should validate_presence_of(:progress) }
      it { should validate_presence_of(:color) }
      it { should validate_presence_of(:user_id) }
    end
  end

  describe "associations" do
    it { should belong_to(:user) }
    it { should belong_to(:constellation).optional }
    it { should have_many(:tasks).dependent(:destroy).class_name("LimitedSharingTask") }
  end

  describe "enums" do
    it { should define_enum_for(:progress).with_values(not_started: 0, in_progress: 1, completed: 2) }
  end

  describe "instanceメソッド" do
    let(:milestone) { create(:limited_sharing_milestone, user: user) }

    describe "#completed_tasks_percentage" do
      context "タスクがない場合" do
        it "0を返すこと" do
          expect(milestone.completed_tasks_percentage).to eq(0)
        end
      end

      context "一部のタスクが完了している場合" do
        let(:milestone_with_mixed_tasks) do
          create(:limited_sharing_milestone, :with_tasks,
                 user: user, tasks_count: 2)
        end

        before do
          milestone_with_mixed_tasks.tasks.first
                                    .update(progress: :completed)
          milestone_with_mixed_tasks.tasks.second
                                    .update(progress: :not_started)
        end

        it "正しい完了率を返すこと" do
          expect(milestone_with_mixed_tasks.completed_tasks_percentage)
            .to eq(50)
        end
      end

      context "すべてのタスクが完了している場合" do
        let(:milestone_with_completed_tasks) do
          create(:limited_sharing_milestone, :with_tasks, user: user, tasks_count: 2)
        end

        before do
          milestone_with_completed_tasks.tasks
                                        .each do |task|
                                          task.update(progress: :completed)
                                        end
        end

        it "100を返すこと" do
          expect(milestone_with_completed_tasks.completed_tasks_percentage)
            .to eq(100)
        end
      end
    end

    describe "#open?" do
      it "常にtrueを返すこと" do
        expect(milestone.open?).to be true
      end
    end

    describe "#on_chart?" do
      it "is_on_chartがtrueの場合trueを返すこと" do
        milestone.update(is_on_chart: true)
        expect(milestone.on_chart?).to be true
      end

      it "is_on_chartがfalseの場合falseを返すこと" do
        milestone.update(is_on_chart: false)
        expect(milestone.on_chart?).to be false
      end
    end
  end

  describe "NanoidGenerator concern" do
    describe "#set_id" do
      it "初期化時にユニークなIDが設定されること" do
        milestone = build(:limited_sharing_milestone, user: user)
        milestone.save
        expect(milestone.id).to be_present
        expect(milestone.id.length).to eq(21)
      end

      it "IDが既に設定されている場合は変更されないこと" do
        existing_id = "existing_test_id_123"
        milestone = build(:limited_sharing_milestone, user: user, id: existing_id)
        milestone.save
        expect(milestone.id).to eq(existing_id)
      end
    end

    describe ".generate_nanoid" do
      it "指定された長さのIDを生成すること" do
        id = LimitedSharingMilestone.generate_nanoid(size: 10)
        expect(id.length).to eq(10)
      end

      it "指定された文字セットを使用すること" do
        id = LimitedSharingMilestone.generate_nanoid(alphabet: "abc123",
                                                     size: 10)
        expect(id).to match(/\A[abc123]+\z/)
      end
    end
  end

  describe "factory" do
    describe ":limited_sharing_milestone" do
      it "有効な限定共有マイルストーンを作成すること" do
        milestone = create(:limited_sharing_milestone)
        expect(milestone).to be_valid
      end

      it "デフォルトでチャート表示がfalseであること" do
        milestone = build(:limited_sharing_milestone)
        expect(milestone.is_on_chart).to be false
      end
    end

    describe ":completed trait" do
      it "完了状態のマイルストーンを作成すること" do
        milestone = build(:limited_sharing_milestone, :completed)
        expect(milestone.progress).to eq("completed")
        expect(milestone.completed_comment).to be_present
      end
    end

    describe ":with_tasks trait" do
      it "関連するタスクを持つマイルストーンを作成すること" do
        milestone = create(:limited_sharing_milestone, :with_tasks)
        expect(milestone.tasks.count).to eq(3)
        milestone.tasks.each do |task|
          expect(task).to be_a(LimitedSharingTask)
          expect(task.user).to eq(milestone.user)
        end
      end

      it "タスク数をカスタマイズできること" do
        milestone = create(:limited_sharing_milestone, :with_tasks, tasks_count: 5)
        expect(milestone.tasks.count).to eq(5)
      end
    end
  end

  describe "タスクとの連携" do
    let(:milestone_with_tasks) { create(:limited_sharing_milestone, user: user) }

    it "マイルストーンが削除されると関連するタスクも削除されること" do
      create(:limited_sharing_task, user: user,
                                    limited_sharing_milestone_id: milestone_with_tasks.id,
                                    create_milestone: false)
      create(:limited_sharing_task, user: user,
                                    limited_sharing_milestone_id: milestone_with_tasks.id,
                                    create_milestone: false)

      expect { milestone_with_tasks.destroy }
        .to change(LimitedSharingTask, :count).by(-2)
    end

    it "タスクの進捗に基づいて完了率が正しく計算されること" do
      milestone_with_percentage = create(:limited_sharing_milestone,
                                         :with_tasks, user: user,
                                                      tasks_count: 5)

      # 2つ完了、1つ進行中、2つ未着手に設定
      milestone_with_percentage.tasks[0].update(progress: :completed)
      milestone_with_percentage.tasks[1].update(progress: :completed)
      milestone_with_percentage.tasks[2].update(progress: :in_progress)
      milestone_with_percentage.tasks[3].update(progress: :not_started)
      milestone_with_percentage.tasks[4].update(progress: :not_started)

      expect(milestone_with_percentage.completed_tasks_percentage)
        .to eq(40) # 2/5 = 40%
    end
  end

  describe "Constellation関連" do
    let(:constellation) { create(:constellation) }

    it "星座を関連付けることができること" do
      milestone = create(:limited_sharing_milestone, user: user,
                                                     constellation: constellation)
      expect(milestone.constellation).to eq(constellation)
    end

    it "星座なしでも有効であること" do
      milestone = create(:limited_sharing_milestone, user: user,
                                                     constellation: nil)
      expect(milestone).to be_valid
      expect(milestone.constellation).to be_nil
    end
  end
end
