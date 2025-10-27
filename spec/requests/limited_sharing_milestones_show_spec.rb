require "rails_helper"

RSpec.describe "LimitedSharingMilestones show", type: :request do
  let(:user) { create(:user) }
  let(:constellation) { create(:constellation, name: "アンドロメダ座") }
  context "星座が割り当てられている場合" do
    let(:limited_milestone) do
      create(
        :limited_sharing_milestone,
        :completed,
        user: user,
        constellation: constellation,
        completed_comment: "やった！"
      )
    end

    it "外部リンク確認モーダルに正しいURLが含まれる" do
      get share_milestone_path(limited_milestone)

      expect(response).to have_http_status(:success)

      doc = Nokogiri::HTML(response.body)
      modal = doc.at_css("dialog#constellation_external_link_modal")
      expect(modal).to be_present

      expected_url = "https://www.study-style.com/seiza/#{constellation.image_name}.html"
      link = modal.at_css("a.link")
      expect(link["href"]).to eq(expected_url)
      expect(link.text).to include(expected_url)
    end
  end

  context "星座がまだ割り当てられていない場合" do
    let(:limited_milestone_without_constellation) do
      create(:limited_sharing_milestone, :in_progress, constellation: nil, user: user)
    end

    it "モーダルは表示されない" do
      get share_milestone_path(limited_milestone_without_constellation)

      doc = Nokogiri::HTML(response.body)
      modal = doc.at_css("dialog#constellation_external_link_modal")
      expect(modal).to be_nil
    end
  end
end
