class ImagesController < ApplicationController
  def ogp
    text = ogp_params[:text]
    image_name = ogp_params[:image_name] || nil
    image = OgpCreator.build(text, image_name).tempfile.open.read

    send_data image, type: "image/png", disposition: "inline"
  end

  private

  def ogp_params
    params.permit(:text, :image_name)
  end
end
