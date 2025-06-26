module KanaNormalizer
  extend ActiveSupport::Concern

  def normalize_kana(text)
    return "" if text.blank?

    # ひらがなをカタカナに変換
    # Unicode範囲: ひらがな（ぁ-ん: U+3041-U+3096）→ カタカナ（ァ-ン: U+30A1-U+30F6）
    text.tr("ぁ-ん", "ァ-ン")
  end

  def reverse_normalize_kana(text)
    return "" if text.blank?

    # カタカナをひらがなに変換
    # Unicode範囲: カタカナ（ァ-ン: U+30A1-U+30F6）→ ひらがな（ぁ-ん: U+3041-U+3096）
    text.tr("ァ-ン", "ぁ-ん")
  end
end
