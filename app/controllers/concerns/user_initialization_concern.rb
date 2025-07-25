module UserInitializationConcern
  extend ActiveSupport::Concern

  private

  def initialize_new_user(user)
    # Deviseのresourceは必ずしもUserモデルとは限らないため、respond_to?でチェック
    # また、nilや異なるオブジェクトが渡される可能性も考慮
    return unless user.respond_to?(:new_user?) && user.new_user?

    UserRegistration::MakeTasksMilestones.create_tasks_and_milestones(user)
  end
end
