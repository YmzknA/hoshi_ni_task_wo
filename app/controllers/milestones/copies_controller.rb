module Milestones
  class CopiesController < ApplicationController
    before_action :authenticate_user!
    before_action :set_milestone, only: [:show, :create]

    def show; end

    def create
      # いずれも無い場合はnilでもかまわない。
      @set_date = copy_params[:start_date]
      @set_date = @milestone.start_date || @milestone.end_date if @set_date.blank?

      # @milestoneをset_dateを基準にコピーする
      # @set_dateは、start_dateとend_dateの両方がnilの場合はそもそも参照しないのでそのまま渡す
      @copy = @milestone.copy(@set_date)

      # @milestoneのtasksの中で一番早い日付を取得する
      # 何度も呼び出す可能性があるので先に取得
      # @milestoneの日付が両方存在せず、始点が指定された場合のみ使用する
      @tasks_first_date = milestone_tasks_first_date

      # @milestoneのtasksを@copyにコピーする
      @milestone.tasks.each do |task|
        # task_set_date()はnilの可能性もある
        # taskにstartかendの日付が存在する場合は必ず値が入る
        # @tasks_first_dateがnilの場合は、全てのtaskに日付が無いので、先にnilを返す
        task_set_date = if @tasks_first_date.nil?
                          nil
                        else
                          task_set_date(task)
                        end

        @copy.tasks << task.copy(task_set_date)
      end

      if @copy.save
        flash.now[:notice] = "星座をコピーしました"
        @copy_success = true
      else
        flash.now[:alert] = "星座のコピーに失敗しました"
        @copy_success = false
      end
    end

    private

    def copy_params
      params.require(:milestone).permit(:start_date)
    end

    def set_milestone
      @milestone = Milestone.find(params[:id])
    end

    # taskから始点とする日付を計算する
    # 呼び出し先で@set_dateを仕様するので、大元のここで@set_dateのnilをチェックし、存在しない場合、taskの日付を与える。
    # これは始点を指定していない場合はtaskの日付をそのままコピーするため。
    def task_set_date(task)
      if @set_date.present?
        calculate_task_set_date(task)
      else
        task.start_date || task.end_date
      end
      # @set_dateも無く、taskの日付も無い場合はnilを返すことになる
    end

    # @milestoneの日付の有無をチェックし、基準となる日付を決定する
    # いづれも存在しない場合は、@milestone.tasksの中で一番早い日付を基準にする
    def calculate_task_set_date(task)
      if @milestone.start_date.present?
        calculate_task_date_difference(task, @milestone.start_date)
      elsif @milestone.end_date.present?
        calculate_task_date_difference(task, @milestone.end_date)
      else
        calculate_task_date_difference(task, @tasks_first_date)
      end
    end

    # taskの日付の有無をチェックし、基準となる日付を決定する
    # いづれも存在しない場合は、nilを返す
    def calculate_task_date_difference(task, milestone_base_date)
      if task.start_date.present?
        apply_date_difference_to_set_date(task.start_date, milestone_base_date)
      elsif task.end_date.present?
        apply_date_difference_to_set_date(task.end_date, milestone_base_date)
      end
      # 両方存在しない場合は日付を設定しないため、何も返さない
      # @tasks_first_dateのnilを最初にチェックしているので、ここでnilになることは無い
    end

    # taskの日付とmilestoneの日付の差分を計算し、@set_dateに加算する
    # taskの日付がmilestoneの日付よりも早い場合は、@set_dateを減算する
    # taskの日付がmilestoneの日付よりも遅い場合は、@set_dateを加算する
    def apply_date_difference_to_set_date(task_base_date, milestone_base_date)
      if task_base_date >= milestone_base_date
        diff = task_base_date - milestone_base_date
        @set_date.to_date + diff
      else
        diff = milestone_base_date - task_base_date
        @set_date.to_date - diff
      end
    end

    # @milestone.tasksの中で一番早い日付を取得する
    def milestone_tasks_first_date
      first_date = Date.new(9999, 1, 1)
      @milestone.tasks.each do |task|
        # startもendもnilの場合は、first_dateを更新しない
        first_date = [first_date, task.start_date, task.end_date].compact.min
      end

      # 9999年1月1日の場合はnilにする
      first_date = nil if first_date == Date.new(9999, 1, 1)
      first_date
    end
  end
end
