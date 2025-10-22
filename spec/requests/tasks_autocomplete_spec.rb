require "rails_helper"

RSpec.describe "Tasks Autocomplete", type: :request do
  let(:user) { create(:user, email: "owner@example.com", password: "password", password_confirmation: "password") }
  let(:milestone) do
    create(
      :milestone,
      user: user,
      title: "Project Milestone",
      progress: :in_progress,
      is_public: false,
      is_on_chart: false,
      is_open: true,
      start_date: Date.today,
      end_date: Date.today + 7.days
    )
  end
  let!(:not_started_task) do
    create(
      :task,
      title: "Task Not Started",
      progress: :not_started,
      user: user,
      milestone: milestone,
      start_date: Date.today,
      end_date: Date.today + 1.day
    )
  end
  let!(:in_progress_task) do
    create(
      :task,
      title: "Task In Progress",
      progress: :in_progress,
      user: user,
      milestone: milestone,
      start_date: Date.today,
      end_date: Date.today + 2.days
    )
  end
  let!(:completed_task) do
    create(
      :task,
      title: "Task Completed",
      progress: :completed,
      user: user,
      milestone: milestone,
      start_date: Date.today,
      end_date: Date.today + 3.days
    )
  end

  before do
    sign_in user
  end

  def response_titles
    Nokogiri::HTML(response.body).css("li").map { |node| node.text.strip }
  end

  describe "GET /tasks/autocomplete" do
    context "milestoneを指定しprogressを指定しない場合" do
      it "対象の星座のタスクが全て返る" do
        get autocomplete_tasks_path, params: { milestone_id: milestone.id, q: "Task" }

        expect(response).to have_http_status(:ok)
        expect(response_titles).to match_array(["Task Not Started", "Task In Progress", "Task Completed"])
      end
    end

    context "progress=not_completedを指定した場合" do
      it "未完了のタスクのみ返る" do
        get autocomplete_tasks_path,
            params: { milestone_id: milestone.id, progress: "not_completed", q: "Task" }

        expect(response_titles).to match_array(["Task Not Started", "Task In Progress"])
      end
    end

    context "progress=completedを指定した場合" do
      it "完了したタスクのみ返る" do
        get autocomplete_tasks_path,
            params: { milestone_id: milestone.id, progress: "completed", q: "Task" }

        expect(response_titles).to eq(["Task Completed"])
      end
    end

    context "progress=allを指定した場合" do
      it "全てのタスクが返る" do
        get autocomplete_tasks_path,
            params: { milestone_id: milestone.id, progress: "all", q: "Task" }

        expect(response_titles).to match_array(["Task Not Started", "Task In Progress", "Task Completed"])
      end
    end

    context "未知のprogressを指定した場合" do
      it "全てのタスクが返る" do
        get autocomplete_tasks_path,
            params: { milestone_id: milestone.id, progress: "in_progress", q: "Task" }

        expect(response_titles).to match_array(["Task Not Started", "Task In Progress", "Task Completed"])
      end
    end
  end
end
