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
      "アンドロメダ座" => "And.webp", "やぎ座" => "Cap.webp", "みずがめ座" => "Aqr.webp",
      "わし座" => "Aql.webp", "さいだん座" => "Ara.webp", "おひつじ座" => "Ari.webp",
      "ぎょしゃ座" => "Aur.webp", "うしかい座" => "Boo.webp", "ちょうこくぐ座" => "Cae.webp",
      "きりん座" => "Cam.webp", "かに座" => "Cnc.webp", "りょうけん座" => "CVn.webp",
      "おおいぬ座" => "CMa.webp", "こいぬ座" => "CMi.webp", "りゅうこつ座" => "Car.webp",
      "カシオペヤ座" => "Cas.webp", "ケンタウルス座" => "Cen.webp", "ケフェウス座" => "Cep.webp",
      "くじら座" => "Cet.webp", "カメレオン座" => "Cha.webp", "コンパス座" => "Cir.webp",
      "はと座" => "Col.webp", "かみのけ座" => "Com.webp", "みなみじゅうじ座" => "Cru.webp",
      "コップ座" => "Crt.webp", "からす座" => "Crv.webp", "みなみのかんむり座" => "CrA.webp",
      "かんむり座" => "CrB.webp", "はくちょう座" => "Cyg.webp", "いるか座" => "Del.webp",
      "かじき座" => "Dor.webp", "りゅう座" => "Dra.webp", "こうま座" => "Equ.webp",
      "エリダヌス座" => "Eri.webp", "ろ座" => "For.webp", "ふたご座" => "Gem.webp",
      "つる座" => "Gru.webp", "ヘルクレス座" => "Her.webp", "とけい座" => "Hor.webp",
      "うみへび座" => "Hya.webp", "みずへび座" => "Hyi.webp", "とかげ座" => "Lac.webp",
      "しし座" => "Leo.webp", "こじし座" => "LMi.webp", "うさぎ座" => "Lep.webp",
      "てんびん座" => "Lib.webp", "おおかみ座" => "Lup.webp", "やまねこ座" => "Lyn.webp",
      "こと座" => "Lyr.webp", "テーブルさん座" => "Men.webp", "けんびきょう座" => "Mic.webp",
      "いっかくじゅう座" => "Mon.webp", "はえ座" => "Mus.webp", "じょうぎ座" => "Nor.webp",
      "はちぶんぎ座" => "Oct.webp", "へびつかい座" => "Oph.webp", "オリオン座" => "Ori.webp",
      "くじゃく座" => "Pav.webp", "ペガスス座" => "Peg.webp", "ペルセウス座" => "Per.webp",
      "ほうおう座" => "Phe.webp", "がか座" => "Pic.webp", "うお座" => "Psc.webp",
      "みなみのうお座" => "PsA.webp", "とも座" => "Pup.webp", "らしんばん座" => "Pyx.webp",
      "レチクル座" => "Ret.webp", "へび座" => "Ser.webp", "ろくぶんぎ座" => "Sex.webp",
      "たて座" => "Sct.webp", "さそり座" => "Sco.webp", "ちょうこくしつ座" => "Scl.webp",
      "いて座" => "Sgr.webp", "おうし座" => "Tau.webp", "ぼうえんきょう座" => "Tel.webp",
      "さんかく座" => "Tri.webp", "みなみさんかく座" => "TrA.webp", "とびうお座" => "Vol.webp",
      "こぐま座" => "UMi.webp", "おおぐま座" => "UMa.webp", "ほ座" => "Vel.webp",
      "おとめ座" => "Vir.webp", "こぎつね座" => "Vul.webp", "ポンプ座" => "Ant.webp",
      "ふうちょう座" => "Aps.webp", "インディアン座" => "Ind.webp", "や座" => "Sge.webp",
      "きょしちょう座" => "Tuc.webp"
    }

    name_hash[name]
  end
end
