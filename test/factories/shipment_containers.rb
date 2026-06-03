FactoryBot.define do
  factory :shipment_container do
    shipment
    organization { shipment.organization }
    sequence(:container_number) { |n| "CONT#{n.to_s.rjust(7, '0')}" }
    seal_number { "SEAL123" }
    vgm { 20_000 }
    gross_weight { 19_500 }
    net_weight { 18_000 }
    package_count { 1_000 }
  end
end
