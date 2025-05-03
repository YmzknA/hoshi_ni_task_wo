# frozen_string_literal: true

class OgpCreator
  BASE_IMAGE_PATH = "./app/assets/images/ogp_bg.png"
  GRAVITY = "center"
  TEXT_POSITION = "0,0"
  FONT = "./app/assets/fonts/ZenOldMincho-Regular.ttf"
  FONT_SIZE = 65
  INDENTION_COUNT = 16
  ROW_LIMIT = 8

  def self.build(text, image_name = nil)
    text = prepare_text(text)
    image = MiniMagick::Image.open(BASE_IMAGE_PATH)

    if image_name
      thumb_path = "./app/assets/images/#{image_name}.webp"
      thumb_image = MiniMagick::Image.open(thumb_path)

      MiniMagick::Tool::Convert.new do |img|
        img.size "#{thumb_image.height}x#{thumb_image.width}"
        img << "xc:transparent"
        img.fill thumb_path
        img.draw "translate 600, 600 circle 0,0 600,0"
        img.trim
        img << "out_put.png"
      end

      thumb_image = MiniMagick::Image.open("out_put.png").resize "200x200"

      image = image.composite(thumb_image) do |c|
        c.compose "Over"
        c.geometry "+20+20"
      end
    end

    image.combine_options do |config|
      config.font FONT
      config.fill "red"
      config.gravity GRAVITY
      config.pointsize FONT_SIZE
      config.draw "text #{TEXT_POSITION} '#{text}'"
    end
  end

  def self.prepare_text(text)
    text.to_s.scan(/.{1,#{INDENTION_COUNT}}/)[0...ROW_LIMIT].join("\n")
  end

  private_class_method :prepare_text
end
