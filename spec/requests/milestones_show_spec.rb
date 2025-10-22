require "rails_helper"

RSpec.describe "Milestones show", type: :request do
  let(:user) { create(:user, email: "owner@example.com", password: "password", password_confirmation: "password") }

  def parsed_body
    Nokogiri::HTML(response.body)
  end

  describe "GET /milestones/:id" do
    context "未完了の星座" do
      let!(:milestone) do
        create(
          :milestone,
          user: user,
          title: "Active Milestone",
          progress: :in_progress,
          is_public: true,
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
          milestone: milestone
        )
      end
      let!(:in_progress_task) do
        create(
          :task,
          title: "Task In Progress",
          progress: :in_progress,
          user: user,
          milestone: milestone
        )
      end
      let!(:completed_task) do
        create(
          :task,
          title: "Task Completed",
          progress: :completed,
          user: user,
          milestone: milestone
        )
      end

      before do
        sign_in(user)
        get milestone_path(milestone)
      end

      it "未完了と完了のタブが表示される" do
        doc = parsed_body
        expect(doc.css('input.tab[aria-label="未完了"]').count).to eq(1)
        expect(doc.css('input.tab[aria-label="完了"]').count).to eq(1)
      end

      it "未完了一覧には未完了タスクのみが含まれる" do
        doc = parsed_body
        titles = doc.css("turbo-frame#search_sort_content_frame p.text-lg").map { |node| node.text.strip }
        expect(titles).to match_array(["Task Not Started", "Task In Progress"])
      end

      it "完了一覧には完了タスクのみが含まれる" do
        doc = parsed_body
        titles = doc.css("turbo-frame#secondary_search_sort_content_frame p.text-lg").map { |node| node.text.strip }
        expect(titles).to eq(["Task Completed"])
      end

      it "autocompleteのURLに適切なprogressが付与される" do
        doc = parsed_body
        autocomplete_urls = doc.css('div[data-controller="autocomplete"]').map do |node|
          node["data-autocomplete-url-value"]
        end

        expect(autocomplete_urls).to include(a_string_including("progress=not_completed"))
        expect(autocomplete_urls).to include(a_string_including("progress=completed"))
      end
    end

    context "完了済みの星座" do
      let!(:completed_milestone) do
        create(
          :milestone,
          user: user,
          title: "Finished Milestone",
          progress: :completed,
          completed_comment: "完了",
          constellation: create(:constellation),
          is_public: true,
          is_on_chart: false,
          is_open: true,
          start_date: Date.today - 10.days,
          end_date: Date.today
        )
      end
      let!(:completed_task_one) do
        create(
          :task,
          title: "Completed Task 1",
          progress: :completed,
          user: user,
          milestone: completed_milestone
        )
      end
      let!(:completed_task_two) do
        create(
          :task,
          title: "Completed Task 2",
          progress: :completed,
          user: user,
          milestone: completed_milestone
        )
      end

      before do
        sign_in(user)
        get milestone_path(completed_milestone)
      end

      it "未完了タブではなく単一のタブが表示される" do
        doc = parsed_body
        expect(doc.css('input.tab[aria-label="未完了"]').count).to eq(0)
        expect(doc.css('input.tab[aria-label="完了"]').count).to eq(0)
        expect(doc.css('input.tab[aria-label="タスク"]').count).to eq(1)
      end

      it "完了タブ用のフレームは表示されない" do
        doc = parsed_body
        expect(doc.at_css("turbo-frame#secondary_search_sort_content_frame")).to be_nil
      end

      it "autocompleteのURLにprogress=allが付与される" do
        doc = parsed_body
        autocomplete_urls = doc.css('div[data-controller="autocomplete"]').map do |node|
          node["data-autocomplete-url-value"]
        end

        expect(autocomplete_urls).to all(include("progress=all"))
      end

      it "タスク一覧には全てのタスクが含まれる" do
        doc = parsed_body
        titles = doc.css("turbo-frame#search_sort_content_frame p.text-lg").map { |node| node.text.strip }
        expect(titles).to match_array(["Completed Task 1", "Completed Task 2"])
      end
    end
  end
end
