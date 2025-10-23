module ConstellationsHelper
  def constellation_url(constellation)
    return unless constellation

    "https://www.study-style.com/seiza/#{constellation.image_name}.html"
  end
end
