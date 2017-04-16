class Ability
  include CanCan::Ability

  def initialize(user)

    if user.is_a?(Member)
      tmp = User.new
      tmp.member = user
      user = tmp
    else
      user ||= User.new
    end


    can :create, User
    can :create, MyTodo
    can :read, Avatar
    can :read, Theme

    if user.admin?
      can :manage, :all
    else
      if user.member.present? && user.member.parent?
        Rails.logger.info "Parent logged in, Member: #{user.member.id} #{user.member.family.name}"
        can [:read, :update], Family do |family|
          user.try(:member).try(:family) == family
        end
        can :manage, Activity do |activity|
          activity.try(:member).try(:family) == user.try(:member).try(:family)
        end
        can :manage, Device do |device|
          device.try(:family) == user.try(:member).try(:family)
        end
        can :manage, Member do |family_member|
          family_member.try(:family) == user.try(:member).try(:family)
        end
        can :manage, ScreenTime do |screen_time|
          screen_time.try(:member).try(:family) == user.try(:member).try(:family)
        end
        can :manage, StOverride do |sto|
          sto.try(:member).try(:family) == user.try(:member).try(:family)
        end
        can :manage, ScreenTimeSchedule do |screen_time_schedule|
          screen_time_schedule.try(:member).try(:family) == user.try(:member).try(:family)
        end
        #can :manage, MyTodo, :family => user.try(:member).try(:family)
        can :manage, MyTodo do |todo|
          todo.member && todo.member.family_id == user.member.family_id
        end
        can :manage, Todo,  :family_id => user.try(:member).try(:family_id)
        can :manage, TodoSchedule do |ts|
          if ts.present? && ts.todo.present?
            ts.todo.family == user.try(:member).try(:family)
          else
            false
          end
        end
        can :read, TodoTemplate, :disabled => false

        # CRM Functions
        can [:read, :create], Ticket, :user_id => user.try(:id)
        can [:read, :create], Note do |note|
          note.try(:ticket).try(:user_id) == user.try(:id)
        end
        can [:read, :create], NoteAttachment do |attachment|
          attachment.try(:note).try(:ticket).try(:user_id) == user.try(:id)
        end

      elsif user.member.present?
        Rails.logger.info "Child logged in, Member: #{user.member.id}"

        # Child permissions
        can [:read, :update], Activity do |activity|
          activity.member_id == user.try(:member_id) || activity.created_by_id == user.try(:member_id)
        end
        can :read, Family, :id => user.try(:member).try(:family_id)
        can :read, Member, :id => user.try(:member_id)
        can :read, ScreenTime, member_id: user.try(:member_id)
        can :read, TodoSchedule, :member_id => user.try(:member_id)
        can :read, Todo, :family_id => user.try(:member).try(:family_id)
        can [:create, :read, :update], MyTodo, :member_id => user.try(:member_id)
      end

      # Both children and parents

      can :create, Activity
      can :read, Activity, :member_id => user.try(:id)
      can :read, ActivityTemplate
      can :read, ActivityType
      can :read, DeviceType
      cannot :index, Family
    end



    # Define abilities for the passed in user here. For example:
    #
    #   user ||= User.new # guest user (not logged in)
    #   if user.admin?
    #     can :manage, :all
    #   else
    #     can :read, :all
    #   end
    #
    # The first argument to `can` is the action you are giving the user 
    # permission to do.
    # If you pass :manage it will apply to every action. Other common actions
    # here are :read, :create, :update and :destroy.
    #
    # The second argument is the resource the user can perform the action on. 
    # If you pass :all it will apply to every resource. Otherwise pass a Ruby
    # class of the resource.
    #
    # The third argument is an optional hash of conditions to further filter the
    # objects.
    # For example, here the user can only update published articles.
    #
    #   can :update, Article, :published => true
    #
    # See the wiki for details:
    # https://github.com/ryanb/cancan/wiki/Defining-Abilities
  end
end
