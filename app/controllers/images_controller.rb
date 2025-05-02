class ImagesController < ApplicationController
  def ogp
    text = ogp_params[:text]
    image = OgpCreator.build(text).tempfile.open.read
    send_data image, type: "image/png", disposition: "inline"
  end

  private

  def ogp_params
    params.permit(:text)
  end
end
