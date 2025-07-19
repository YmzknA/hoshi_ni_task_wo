module UserInitializationConcern
  extend ActiveSupport::Concern

  private

  def initialize_new_user(user)
    return unless user.respond_to?(:new_user?) && user.new_user?

    UserRegistration::MakeTasksMilestones.create_tasks_and_milestones(user)
  end
end
