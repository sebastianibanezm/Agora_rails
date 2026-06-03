class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    raise Pundit::NotAuthorizedError, "must be logged in" unless user
    @user = user
    @record = record
  end

  class Scope
    def initialize(user, scope)
      @user  = user
      @scope = scope
    end

    def resolve
      raise NotImplementedError, "#{self.class}#resolve is not implemented"
    end

    private

      attr_reader :user, :scope

      def organization_scope
        return scope.none unless user&.organization_id
        return scope.none unless scope.klass.column_names.include?("organization_id")

        scope.where(organization_id: user.organization_id)
      end
  end

  private

    def permitted?(resource, action)
      user.can?(resource, action)
    end
end
