module LineBot
  class MessageBuilder
    # メッセージの形を形成するクラス

    def self.text(message)
      { type: "text", text: message }
    end

    # tasksのメッセージを生成する
    def self.tasks_message(tasks, is_show_milestone: true, with_id: false)
      tasks.map.with_index do |task, index|
        is_first = index.zero?
        tasks_info(task, is_first: is_first, is_show_milestone: is_show_milestone, with_id: with_id)
      end.join("\n")
    end

    def self.task_change_date_message(task)
      "#{tasks_info(task, is_first: true)}
      \n続いて、日付を送信してください。\
      \n年の指定が無い場合は、今年に設定されます。\
      \n   例: 2023-10-01 または 10-01\
      \n   例: 2023年10月1日 または 10月1日"
    end

    def self.tasks_list_for_change(tasks)
      tasks_message = tasks_message(tasks, with_id: true)
      "どれを変更しますか？\n以下のリストからIDを選んでください。\n\n#{tasks_message}"
    end

    # milestoneと、それのtasksのメッセージを生成する
    def self.milestone_with_tasks_message(milestone)
      milestone_info = milestone_info(milestone, is_first: true)
      tasks = milestone.tasks.order(:start_date)
      tasks_info = tasks.present? ? tasks_message(tasks, is_show_milestone: false) : "タスクはありません"

      "#{milestone_info}\n\n#{tasks_info}"
    end

    # taskの情報表示部分を生成する
    # rubocop:disable Metrics/CyclomaticComplexity
    def self.tasks_info(task, is_first: false, is_show_milestone: true, with_id: false)
      start_date = task.start_date.present? ? to_short_date(task.start_date) : ""
      end_date = task.end_date.present? ? to_short_date(task.end_date) : ""
      task_milestone_title = task.milestone&.title || "---"
      progress = get_progress_message(task)

      "#{"\n" unless is_first}📝：#{"(ID: #{task.id}) " if with_id}#{task.title} - #{progress}\
      #{"\n   🌟：#{task_milestone_title}" if is_show_milestone}\
      \n   #{date_range(start_date, end_date)}"
    end
    # rubocop:enable Metrics/CyclomaticComplexity

    # milestonesのメッセージを生成する
    def self.milestones_message(milestones)
      milestones.map do |milestone|
        is_first = milestone == milestones.first
        milestone_info(milestone, is_first: is_first)
      end.join("\n")
    end

    # milestonesのタイトルのみのメッセージを生成する
    def self.milestones_title_message(milestones)
      milestones.map do |milestone|
        is_first = milestone == milestones.first
        "#{"\n" if is_first}🌟：#{milestone.title}"
      end.join("\n")
    end

    # milestoneの情報表示部分を生成する
    def self.milestone_info(milestone, is_first: false)
      start_date = milestone.start_date.present? ? to_short_date(milestone.start_date) : "未設定"
      end_date = milestone.end_date.present? ? to_short_date(milestone.end_date) : "未設定"
      tasks_count = milestone.tasks.count
      completed_tasks_count = milestone.tasks.completed.count
      completed_tasks_percentage = milestone.completed_tasks_percentage

      "#{"\n" unless is_first}🌟：#{milestone.title}\
      \n   📝：#{tasks_count}(完成：#{completed_tasks_count})\
      \n   🏁：#{completed_tasks_percentage}%\
      \n   #{date_range(start_date, end_date)}"
    end

    def self.search_results_message(tasks, milestones)
      tasks_message = tasks.present? ? tasks_message(tasks) : "📝 タスクはありません"
      milestones_message = milestones.present? ? milestones_message(milestones) : "🌟 星座はありません"

      if tasks.empty? && milestones.empty?
        "どちらも見つかりませんでした。"
      else
        "#{milestones_message}\n\n----------\n\n#{tasks_message}"
      end
    end

    def self.error_message(errors)
      message = errors.join("\n")

      "❌📝 変更に失敗しました。\n#{message}"
    end

    def self.to_short_date(date)
      return if date.nil?

      "#{date.mon}/#{date.mday} (#{day_of_week(date)})"
    end

    # 日付の曜日を日本語で取得する
    def self.day_of_week(date)
      return if date.nil?

      day_name_ja = %w[日 月 火 水 木 金 土]

      d = date.to_date.wday

      day_name_ja[d]
    end

    def self.get_progress_message(task)
      case task.progress
      when "not_started"
        "🍵 未着手"
      when "in_progress"
        "👉 進行中"
      when "completed"
        "✅ 完了"
      else
        "❓状態不明"
      end
    end

    def self.date_range(start_date, end_date)
      "#{start_date} ~ #{end_date}"
    end

    private_class_method :milestone_info, :date_range, :tasks_info
  end
end
