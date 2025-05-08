module Tasks
  class CopiesController < ApplicationController
    before_action :authenticate_user!
    before_action :set_task, only: [:show, :create]

    def show; end

    def create
      set_date = copy_params[:start_date]
      set_date = @task.start_date || @task.end_date if set_date.blank?

      @copy = @task.copy(set_date)

      if @copy.save
        flash.now[:notice] = "タスクをコピーしました"
        @copy_success = true
      else
        flash.now[:alert] = "タスクのコピーに失敗しました"
        @copy_success = false
      end
    end

    private

    def set_task
      @task = Task.find(params[:id])
    end

    def copy_params
      params.require(:task).permit(:start_date).merge(user_id: current_user.id)
    end
  end
end
