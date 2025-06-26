module LineBot
  class TaskPresenter
    include KanaNormalizer

    def initialize(user)
      @user = user
    end

    def tasks_list
      return "ユーザーIDが取得できませんでした。" if @user.nil?

      tasks = @user.tasks.order(:start_date).reject { |t| t.milestone.present? && t.milestone.completed? }

      if tasks.empty?
        "タスクはありません！"
      else
        MessageBuilder.tasks_message(tasks)
      end
    end

    def tasks_for_milestone(milestone_title)
      milestone = @user.milestones.find_by(title: milestone_title)

      if milestone
        MessageBuilder.milestone_with_tasks_message(milestone)
      else
        "その星座は見つかりませんでした。"
      end
    end

    def tasks_milestones_info_from_search(search_word)
      # ひらがな・カタカナ正規化でfuzzy検索を実装
      kana_query = normalize_kana(search_word)
      reverse_kana_query = reverse_normalize_kana(search_word)

      # タスク検索（完了したマイルストーンのタスクは除外）
      tasks = @user.tasks.ransack(title_cont_any: [kana_query, reverse_kana_query])
                   .result(distinct: true)
                   .includes(:milestone)
                   .order(:start_date)
                   .to_a
                   .reject { |t| t.milestone.present? && t.milestone.completed? }

      # マイルストーン検索（未完了のもののみ）
      milestones = @user.milestones.not_completed.ransack(title_cont_any: [kana_query, reverse_kana_query])
                        .result(distinct: true)
                        .order(:start_date)

      # tasksやmilestonesが空の場合の分岐はsearch_results_messageメソッド内で行う
      MessageBuilder.search_results_message(tasks, milestones)
    end

    def tasks_from_title(title)
      @user.tasks.where(title: title).order(:start_date).reject { |t| t.milestone.present? && t.milestone.completed? }
    end

    def tasks_from_list(tasks)
      return "ユーザーが見つかりません" unless @user
      return "タスクはありません" if tasks.empty?

      MessageBuilder.tasks_message(tasks)
    end

    def tasks_from_id(task_id)
      @user.tasks.where(id: task_id).reject { |t| t.milestone.present? && t.milestone.completed? }
    end

    def update_task_date_and_get_response(task, date_string, which_date_change)
      which_date = which_date_change == "start_date" ? "開始日" : "終了日"
      # 日付のフォーマットをチェック
      date = date_format(date_string)

      return date_format_error_message unless date

      # 日付のフォーマットが正しい場合、タスクの日付を更新
      task.send("#{which_date_change}=", date)

      if task.save
        Rails.cache.delete("user_#{@user.id}_step")
        Rails.cache.delete("user_#{@user.id}_task_id")
        "📝 #{which_date}を#{date}に変更しました"
      else
        LineBot::MessageBuilder.error_message(task.errors.full_messages)
      end
    end

    private

    def date_format_error_message
      "❌📝 日付のフォーマットが正しくありません\n\
        \n   例: 2023-10-01 または 10-01\
        \n   例: 2023年10月1日 または 10月1日"
    end

    def date_format(date_string)
      # 年の指定が無い場合は、今年に設定される
      formats = ["%Y-%m-%d", "%m-%d", "%Y年%m月%d日", "%m月%d日", "%m%d"]

      formats.each do |format|
        return Date.strptime(date_string, format)
      rescue Date::Error
        next
      end
      nil
    end
  end
end
