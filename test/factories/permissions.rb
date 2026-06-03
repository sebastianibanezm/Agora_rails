FactoryBot.define do
  factory :permission do
    resource { "documents" }
    sequence(:action) { |n| "action_#{n}" }

    trait :documents_view    do resource { "documents" }; action { "view" }    end
    trait :documents_create  do resource { "documents" }; action { "create" }  end
    trait :documents_update  do resource { "documents" }; action { "update" }  end
    trait :documents_destroy do resource { "documents" }; action { "destroy" } end
    trait :members_view      do resource { "members" };   action { "view" }    end
    trait :members_invite    do resource { "members" };   action { "invite" }  end
    trait :members_remove    do resource { "members" };   action { "remove" }  end
    trait :members_promote   do resource { "members" };   action { "promote" } end
  end
end
