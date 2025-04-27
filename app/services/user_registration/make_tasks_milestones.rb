module UserRegistration
  class MakeTasksMilestones
    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/MethodLength
    def self.create_tasks_and_milestones(user)
      on_chart_milestone = user.milestones.create!(
        title: "サンプル星座",
        description: "サンプル星座を作成しました！
        チャートに表示をオンにしていると、Start DateとEnd Dateを設定する必要があります。
        また、星座を削除する際に、紐づいたタスクを一緒に削除できます。",
        progress: "in_progress",
        start_date: Date.today - 1.week,
        end_date: Date.today + 3.week
      )
      user.tasks.create!(
        title: "完了したタスク",
        description: "完了したタスクはチャートで灰色に表示されます",
        progress: "completed",
        start_date: Date.today - 1.week,
        end_date: Date.today + 1.day,
        milestone_id: on_chart_milestone.id
      )
      user.tasks.create!(
        title: "未着手のタスク",
        description: "未着手のタスクはチャートに〇で表示されます",
        progress: "not_started",
        start_date: Date.today + 1.day,
        end_date: Date.today + 2.week,
        milestone_id: on_chart_milestone.id
      )
      user.tasks.create!(
        title: "進行中のタスク",
        description: "進行中のタスクはチャートに△で表示されます",
        progress: "in_progress",
        start_date: Date.today + 1.week,
        end_date: Date.today + 3.week,
        milestone_id: on_chart_milestone.id
      )
      user.tasks.create!(
        title: "日付が片方だけ設定されているタスク",
        description: "日付が片方だけ設定されているタスクはチャートに一点で表示されます",
        progress: "not_started",
        start_date: Date.today + 1.day,
        milestone_id: on_chart_milestone.id
      )

      complete_milestone = user.milestones.create!(
        title: "完成できる星座",
        description: "紐づくタスクが全て完了している星座です。
        タスク一覧から完成ボタンを推して、星座を完成させてみてください",
        progress: "in_progress",
        start_date: Date.today - 1.week,
        end_date: Date.today + 3.week
      )
      user.tasks.create!(
        title: "完了したタスク",
        description: "完了！",
        progress: "completed",
        start_date: Date.today + 1.day,
        milestone_id: complete_milestone.id
      )
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength
  end
end
