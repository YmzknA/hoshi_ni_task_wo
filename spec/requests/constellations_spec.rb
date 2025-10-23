require "rails_helper"

RSpec.describe "Constellations", type: :request do
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  describe "GET /constellations" do
    it "星座一覧ページが正常に表示される" do
      get constellations_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("88星座図鑑")
      expect(response.body).to include("獲得済みの星座:")
    end

    it "星座が表示される" do
      create(:constellation, name: "アンドロメダ座", number_of_stars: 20)
      get constellations_path
      expect(response.body).to include("アンドロメダ座")
      expect(response.body).to include("20")
    end

    it "星座カードがクリック可能なリンクになっている" do
      constellation = create(:constellation, name: "アンドロメダ座")
      get constellations_path
      expect(response.body).to include("href=\"/constellations/#{constellation.id}\"")
    end

    it "所有済み星座にマークが表示される" do
      constellation = create(:constellation, name: "アンドロメダ座")
      create(:milestone, user: user, constellation: constellation, progress: :completed)

      get constellations_path
      expect(response.body).to include("data-tip=\"獲得済み\"")
    end

    it "所有済み星座の数が表示される" do
      constellation1 = create(:constellation, name: "アンドロメダ座")
      constellation2 = create(:constellation, name: "うお座")
      create(:milestone, user: user, constellation: constellation1, progress: :completed)
      create(:milestone, user: user, constellation: constellation2, progress: :completed)

      get constellations_path
      expect(response.body).to include("獲得済みの星座: 2個 / 88個")
    end

    it "獲得済み星座のボーダーが表示される" do
      constellation = create(:constellation, name: "アンドロメダ座")
      create(:milestone, user: user, constellation: constellation, progress: :completed)

      get constellations_path
      expect(response.body).to include("border-accent")
    end

    context "未ログインの場合" do
      before { sign_out user }

      it "ログインページにリダイレクトされる" do
        get constellations_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "GET /constellations/:id" do
    let(:constellation) { create(:constellation, name: "アンドロメダ座") }

    it "星座詳細ページが正常に表示される" do
      milestone = create(:milestone, user: user, constellation: constellation, progress: :completed)

      get constellation_path(constellation)
      expect(response).to have_http_status(:success)
      expect(response.body).to include("アンドロメダ座に紐づく星座")
      expect(response.body).to include(milestone.title)
    end

    it "星座画像と詳細情報が表示される" do
      create(:milestone, user: user, constellation: constellation, progress: :completed)

      get constellation_path(constellation)
      expect(response.body).to include(constellation.number_of_stars.to_s)
      expect(response.body).to include("星座の詳細を見る")
      expect(response.body).to include("この星座を獲得した星座")
    end

    it "紐づく星座がない場合もページが表示される" do
      get constellation_path(constellation)
      expect(response).to have_http_status(:success)
      expect(response.body).to include(constellation.name)
    end

    it "存在しない星座IDの場合はリダイレクトされる" do
      get constellation_path(id: 99_999)
      expect(response).to redirect_to(constellations_path)
      expect(flash[:alert]).to eq("星座が見つかりませんでした")
    end

    context "未ログインの場合" do
      before { sign_out user }

      it "ログインページにリダイレクトされる" do
        get constellation_path(constellation)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
