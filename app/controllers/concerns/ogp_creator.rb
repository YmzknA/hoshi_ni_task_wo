# frozen_string_literal: true

class OgpCreator
  # ogp_bgは1200x627の画像

  BASE_IMAGE_PATH = "./app/assets/images/ogp_bg.png"
  GRAVITY = "center"
  FONT = "./app/assets/fonts/ZenOldMincho-Regular.ttf"
  FONT_SIZE = 50
  INDENTION_COUNT = 10
  ROW_LIMIT = 5
  ROUND_IMAGE_POSITION = "+150+168"
  COLOR = "#EAF2F5"

  def self.build(text, image_name = nil)
    # 三項演算子の時は分かりやすさのために.nil?で分岐してます
    # image_nameがnilの場合は、centerに配置
    text_position = "#{image_name.nil? ? '0' : '200'}, -20"

    text = prepare_text(text)
    base_image = MiniMagick::Image.open(BASE_IMAGE_PATH)

    if image_name
      # thumb_imageから円形にくりぬき、ボーダーを付与した画像を作成
      rounded_thumb = rounded_thumb(image_name)

      # くりぬいた画像をbase_imageに合成
      base_image = base_image.composite(rounded_thumb) do |c|
        c.compose "Over"
        c.geometry ROUND_IMAGE_POSITION
        c.border "5"
        c.bordercolor "transparent"
      end
    end

    # base_imageにテキストを合成
    base_image.combine_options do |config|
      config.font FONT
      config.fill COLOR
      config.gravity GRAVITY
      config.pointsize FONT_SIZE
      config.draw "text #{text_position} '#{text}'"
    end
  end

  def self.prepare_text(text)
    text.to_s.scan(/.{1,#{INDENTION_COUNT}}/)[0...ROW_LIMIT].join("\n")
  end

  def self.rounded_thumb(image_name)
    thumb_path = "./app/assets/images/#{image_name}.webp"
    thumb_image = MiniMagick::Image.open(thumb_path)

    # 画像を丸く切り抜き、画像の周りは白色で塗りつぶす
    MiniMagick::Tool::Convert.new do |img|
      img.size "#{thumb_image.height}x#{thumb_image.width}"
      img << "xc:transparent"
      img.fill thumb_path
      img.draw "translate 600, 600 circle 0,0 580,0"
      img.trim
      img.border "20x20"
      img.bordercolor COLOR
      img << "out_put.png"
    end

    out_put_image = MiniMagick::Image.open("out_put.png")

    # 上記で作成した画像を一回り大きく円形にくりぬくことで、白いボーダーを付与
    MiniMagick::Tool::Convert.new do |img|
      img.size "#{out_put_image.height}x#{out_put_image.width}"
      img << "xc:transparent"
      img.fill "out_put.png"
      img.draw "translate 600, 600 circle 0,0 600,0"
      img.trim
      img << "rounded_thumb.png"
    end

    # くりぬいた画像をbase_imageに合成するために、サイズを250x250にリサイズ
    MiniMagick::Image.open("rounded_thumb.png").resize "250x250"
  end

  private_class_method :prepare_text, :rounded_thumb
end
