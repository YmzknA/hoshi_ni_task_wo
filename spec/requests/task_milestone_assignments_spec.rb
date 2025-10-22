require "rails_helper"

RSpec.describe "TaskMilestoneAssignments", type: :request do
  describe "PATCH /task_milestone_assignments/:id" do
    let(:headers) { { "HTTP_ACCEPT" => "text/vnd.turbo-stream.html" } }
    let(:user) { create(:user) }

    before { sign_in(user) }

    def turbo_stream_contents_for(target)
      pattern = %r{<turbo-stream[^>]*target="#{target}"[^>]*>\s*<template>(.*?)</template>\s*</turbo-stream>}m
      response.body.scan(pattern).map(&:first)
    end

    def titles_for(target)
      html = turbo_stream_contents_for(target).first
      return [] unless html

      Nokogiri::HTML.fragment(html).css("p.text-lg").map { |element| element.text.strip }
    end

    context "未完了の星座を更新するとき" do
      let(:milestone) do
        create(
          :milestone,
          user: user,
          progress: :in_progress,
          is_on_chart: false,
          is_public: true,
          is_open: true,
          start_date: Date.today,
          end_date: Date.today + 7.days
        )
      end
      let!(:not_started_task) do
        create(:task, :not_started, user: user, milestone: milestone, title: "Not Started Task")
      end
      let!(:in_progress_task) do
        create(:task, :in_progress, user: user, milestone: milestone, title: "In Progress Task")
      end
      let!(:completed_task) do
        create(:task, :completed, user: user, milestone: milestone, title: "Completed Task")
      end

      it "Turbo Stream で未完了一覧と完了一覧が更新される" do
        patch task_milestone_assignment_path(milestone),
              params: {
                milestone: {
                  not_started_task.id => "1",
                  in_progress_task.id => "1",
                  completed_task.id => "1"
                }
              },
              headers: headers

        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")

        expect(titles_for("search_sort_content_frame")).to match_array([
                                                                         "Not Started Task",
                                                                         "In Progress Task"
                                                                       ])
        expect(titles_for("secondary_search_sort_content_frame")).to eq(["Completed Task"])
      end
    end

    context "星座がチャートに表示されているとき" do
      let(:milestone) do
        create(
          :milestone,
          :on_chart,
          user: user,
          progress: :in_progress,
          is_public: true,
          is_open: true
        )
      end
      let!(:task_one) do
        create(:task, :in_progress, user: user, milestone: milestone, title: "Chart Task")
      end

      it "ガントチャートのフレームも更新される" do
        patch task_milestone_assignment_path(milestone),
              params: { milestone: { task_one.id => "1" } },
              headers: headers

        expect(turbo_stream_contents_for("gantt_chart")).not_to be_empty
      end
    end

    context "タスクの更新に失敗するとき" do
      let(:milestone) do
        create(
          :milestone,
          :on_chart,
          user: user,
          progress: :in_progress,
          is_public: true,
          is_open: true
        )
      end
      let!(:invalid_task) do
        create(:task, :no_dates, user: user, milestone: nil, title: "Invalid Task")
      end

      it "エラーフレームのみが更新される" do
        patch task_milestone_assignment_path(milestone),
              params: { milestone: { invalid_task.id => "1" } },
              headers: headers

        expect(turbo_stream_contents_for("assignments_error")).not_to be_empty
        expect(turbo_stream_contents_for("search_sort_content_frame")).to be_empty
        expect(turbo_stream_contents_for("secondary_search_sort_content_frame")).to be_empty
      end
    end
  end
end
