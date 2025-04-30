module MilestonesHelper
  def milestone_constellation_url(milestone)
    return unless milestone.constellation

    "https://www.study-style.com/seiza/#{milestone.constellation.image_name}.html"
  end
end
