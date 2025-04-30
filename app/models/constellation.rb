class Constellation < ApplicationRecord
  has_many :milestones

  def self.range_of_stars_from_num_of_tasks(num_of_tasks)
    return 2 if num_of_tasks.zero?

    case num_of_tasks
    when 1..2
      2..10
    when 3..4
      5..15
    when 5
      10..20
    else
      15..28
    end
  end

  def self.random_constellation_from_num_of_stars(range_of_stars)
    constellations = Constellation.where(number_of_stars: range_of_stars)
    constellations.sample
  end

  def image_name
    name_hash = {
      "アンドロメダ座" => "And", "やぎ座" => "Cap", "みずがめ座" => "Aqr",
      "わし座" => "Aql", "さいだん座" => "Ara", "おひつじ座" => "Ari",
      "ぎょしゃ座" => "Aur", "うしかい座" => "Boo", "ちょうこくぐ座" => "Cae",
      "きりん座" => "Cam", "かに座" => "Cnc", "りょうけん座" => "CVn",
      "おおいぬ座" => "CMa", "こいぬ座" => "CMi", "りゅうこつ座" => "Car",
      "カシオペヤ座" => "Cas", "ケンタウルス座" => "Cen", "ケフェウス座" => "Cep",
      "くじら座" => "Cet", "カメレオン座" => "Cha", "コンパス座" => "Cir",
      "はと座" => "Col", "かみのけ座" => "Com", "みなみじゅうじ座" => "Cru",
      "コップ座" => "Crt", "からす座" => "Crv", "みなみのかんむり座" => "CrA",
      "かんむり座" => "CrB", "はくちょう座" => "Cyg", "いるか座" => "Del",
      "かじき座" => "Dor", "りゅう座" => "Dra", "こうま座" => "Equ",
      "エリダヌス座" => "Eri", "ろ座" => "For", "ふたご座" => "Gem",
      "つる座" => "Gru", "ヘルクレス座" => "Her", "とけい座" => "Hor",
      "うみへび座" => "Hya", "みずへび座" => "Hyi", "とかげ座" => "Lac",
      "しし座" => "Leo", "こじし座" => "LMi", "うさぎ座" => "Lep",
      "てんびん座" => "Lib", "おおかみ座" => "Lup", "やまねこ座" => "Lyn",
      "こと座" => "Lyr", "テーブルさん座" => "Men", "けんびきょう座" => "Mic",
      "いっかくじゅう座" => "Mon", "はえ座" => "Mus", "じょうぎ座" => "Nor",
      "はちぶんぎ座" => "Oct", "へびつかい座" => "Oph", "オリオン座" => "Ori",
      "くじゃく座" => "Pav", "ペガスス座" => "Peg", "ペルセウス座" => "Per",
      "ほうおう座" => "Phe", "がか座" => "Pic", "うお座" => "Psc",
      "みなみのうお座" => "PsA", "とも座" => "Pup", "らしんばん座" => "Pyx",
      "レチクル座" => "Ret", "へび座" => "Ser", "ろくぶんぎ座" => "Sex",
      "たて座" => "Sct", "さそり座" => "Sco", "ちょうこくしつ座" => "Scl",
      "いて座" => "Sgr", "おうし座" => "Tau", "ぼうえんきょう座" => "Tel",
      "さんかく座" => "Tri", "みなみさんかく座" => "TrA", "とびうお座" => "Vol",
      "こぐま座" => "UMi", "おおぐま座" => "UMa", "ほ座" => "Vel",
      "おとめ座" => "Vir", "こぎつね座" => "Vul", "ポンプ座" => "Ant",
      "ふうちょう座" => "Aps", "インディアン座" => "Ind", "や座" => "Sge",
      "きょしちょう座" => "Tuc"
    }

    name_hash[name]
  end
end
