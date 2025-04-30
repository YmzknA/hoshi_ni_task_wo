# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
#
constellation_stars = {
  "アンドロメダ座" => 16, "インディアン座" => 5, "うお座" => 19, "うさぎ座" => 11, 
  "うしかい座" => 13, "うみへび座" => 19, "おおいぬ座" => 17, "おおかみ座" => 14, 
  "おおぐま座" => 20, "おうし座" => 28, "おとめ座" => 15, "おひつじ座" => 4, 
  "オリオン座" => 17, "かじき座" => 4, "かに座" => 7, "かみのけ座" => 12, 
  "カシオペヤ座" => 5, "カメレオン座" => 5, "がか座" => 4, "きょしちょう座" => 6, 
  "きりん座" => 7, "ぎょしゃ座" => 8, "くじゃく座" => 9, "くじら座" => 15, 
  "ケフェウス座" => 9, "ケンタウルス座" => 27, "けんびきょう座" => 5, "こうま座" => 4, 
  "こぎつね座" => 3, "こぐま座" => 7, "こじし座" => 4, "こいぬ座" => 3, 
  "こと座" => 6, "コップ座" => 8, "コンパス座" => 3, "さいだん座" => 8, 
  "さそり座" => 18, "さんかく座" => 3, "しし座" => 17, "じょうぎ座" => 6, 
  "たて座" => 3, "ちょうこくしつ座" => 6, "ちょうこくぐ座" => 4, "つる座" => 9, 
  "てんびん座" => 6, "とかげ座" => 8, "とけい座" => 6, "とびうお座" => 6, 
  "とも座" => 8, "はえ座" => 6, "はくちょう座" => 11, "はちぶんぎ座" => 3, 
  "はと座" => 7, "ヘルクレス座" => 21, "へび座" => 15, "へびつかい座" => 13, 
  "ペガスス座" => 14, "ペルセウス座" => 21, "ぼうえんきょう座" => 5, "ほ座" => 9, 
  "ほうおう座" => 7, "ポンプ座" => 4, "みずがめ座" => 17, "みずへび座" => 4, 
  "みなみじゅうじ座" => 4, "みなみさんかく座" => 3, "みなみのうお座" => 8, "みなみのかんむり座" => 7, 
  "や座" => 4, "やぎ座" => 12, "やまねこ座" => 7, "らしんばん座" => 3, 
  "りゅう座" => 15, "りゅうこつ座" => 10, "りょうけん座" => 2, "レチクル座" => 5, 
  "ろ座" => 4, "ろくぶんぎ座" => 3, "わし座" => 12, "いっかくじゅう座" => 7, 
  "いるか座" => 5, "エリダヌス座" => 28, "からす座" => 5, "かんむり座" => 7, 
  "ふうちょう座" => 4, "ふたご座" => 16, "いて座" => 20, "テーブルさん座" => 6
}

# Create constellations
constellation_stars.each do |name, number_of_stars|
  Constellation.find_or_create_by!(name: name) do |constellation|
    constellation.number_of_stars = number_of_stars
  end
end
