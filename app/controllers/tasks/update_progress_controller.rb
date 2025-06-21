module Tasks
  class UpdateProgressController < ApplicationController
    before_action :set_task, only: [:update]
    before_action :authenticate_user!
    before_action :ensure_correct_user, only: [:update]
    before_action :set_task_milestone, only: [:update]

    # タスクの進捗状況を更新
    # 完了した星座に関連付けられている場合は更新できない
    def update
      if @task.milestone_completed?
        flash[:alert] = "完了した星座に関連付けられているタスクの進捗は更新できません"
        redirect_back fallback_location: tasks_path and return
      end

      @task.progress = @task.next_progress

      if @task.save
        update_task_milestone_and_load_tasks
        flash.now.notice = "タスクの進捗状況を更新しました"
      else
        flash.now.alert = "タスクの進捗状況の更新に失敗しました"
      end
    end

    private

    def set_task
      @task = Task.find(params[:id])
    end

    def set_task_milestone
      @task_milestone = @task.milestone if @task.milestone.present?
    end

    def ensure_correct_user
      task = Task.find(params[:id])

      return if task.user.id == current_user.id

      flash[:alert] = "アクセス権限がありません"
      redirect_to user_path(current_user)
    end

    def update_task_milestone_and_load_tasks
      return unless @task_milestone.present?

      # 星座の進捗をタスクの進捗に合わせて更新
      @task_milestone.update_progress

      set_chart_tasks
    end

    def sort_tasks_by_complete_and_start_date(tasks)
      # 完了したタスクを後ろにして、それぞれ開始日でソート
      not_completed_tasks = tasks.not_completed.start_date_asc
      completed_tasks = tasks.completed.start_date_asc
      not_completed_tasks + completed_tasks
    end

    def set_chart_tasks
      return unless @task_milestone.on_chart?

      tasks = fetch_chart_tasks
      @chart_tasks = sort_tasks_by_complete_and_start_date(tasks).to_a

      # いま処理しているタスクがまだdbに存在していればチャートに表示するために追加
      current_task = @task_milestone.tasks.find_by(id: @task.id)
      @chart_tasks << current_task if current_task && @chart_tasks.exclude?(current_task)
    end

    def fetch_chart_tasks
      # アクセス元のページを判定してタスクを取得
      # チャート画面からのアクセスの場合：完了タスクを非表示にする設定を確認する
      # 星座詳細画面からのアクセスの場合：常にすべてのタスクを表示
      return @task_milestone.tasks.valid_dates_nil unless from_chart_page?

      if current_user.completed_tasks_hidden?
        @task_milestone.tasks.not_completed.valid_dates_nil
      else
        @task_milestone.tasks.valid_dates_nil
      end
    end

    def from_chart_page?
      # URLからアクセス元のページを判定
      referer = request.referer
      return false if referer.blank?

      # チャート画面のURLパターンをチェック
      referer.include?("/gantt_chart")
    end
  end
end
