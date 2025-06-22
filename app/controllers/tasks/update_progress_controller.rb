module Tasks
  class UpdateProgressController < ApplicationController
    include ChartUpdateConcern

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
  end
end
