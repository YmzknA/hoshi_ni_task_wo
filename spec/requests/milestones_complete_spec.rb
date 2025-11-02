require "rails_helper"

RSpec.describe "Milestones complete", type: :request do
  let(:user) { create(:user) }
  let!(:milestone) do
    create(
      :milestone,
      user: user,
      progress: :in_progress,
      is_on_chart: false,
      start_date: nil,
      end_date: nil
    )
  end

  let!(:task) do
    create(:task, milestone: milestone, user: user)
  end
  let!(:constellation) { create(:constellation, name: "アンドロメダ座", number_of_stars: 5) }
  let(:headers) { { "Accept" => "text/vnd.turbo-stream.html" } }

  before do
    allow(Constellation).to receive(:random_constellation_from_num_of_stars).and_return(constellation)
    sign_in user
  end

  it "turbo stream includes external link confirmation modal with correct URL" do
    patch complete_milestone_path(milestone), params: { milestone: { completed_comment: "complete" } }, headers: headers

    expect(response).to have_http_status(:success)
    expect(response.media_type).to eq("text/vnd.turbo-stream.html")

    expected_url = "https://www.study-style.com/seiza/#{constellation.image_name}.html"
    expect(response.body).to include("constellation_external_link_modal")
    expect(response.body).to include(expected_url)
  end
end
