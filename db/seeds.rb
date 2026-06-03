PERMISSIONS_SEED = [
  { resource: "documents", action: "view" },
  { resource: "documents", action: "create" },
  { resource: "documents", action: "update" },
  { resource: "documents", action: "destroy" },
  { resource: "members",   action: "view" },
  { resource: "members",   action: "invite" },
  { resource: "members",   action: "remove" },
  { resource: "members",   action: "promote" },
  { resource: "trading_partners", action: "view" },
  { resource: "trading_partners", action: "create" },
  { resource: "trading_partners", action: "update" },
  { resource: "trading_partners", action: "destroy" },
  { resource: "master_agreements", action: "view" },
  { resource: "master_agreements", action: "create" },
  { resource: "master_agreements", action: "update" },
  { resource: "master_agreements", action: "destroy" },
  { resource: "purchase_orders", action: "view" },
  { resource: "purchase_orders", action: "create" },
  { resource: "purchase_orders", action: "update" },
  { resource: "purchase_orders", action: "destroy" },
  { resource: "shipments", action: "view" },
  { resource: "shipments", action: "create" },
  { resource: "shipments", action: "update" },
  { resource: "shipments", action: "destroy" },
  { resource: "shipment_documents", action: "view" },
  { resource: "shipment_documents", action: "create" },
  { resource: "shipment_documents", action: "update" },
  { resource: "shipment_documents", action: "destroy" },
  { resource: "shipment_documents", action: "approve" },
  { resource: "shipment_documents", action: "waive" },
].freeze

PERMISSIONS_SEED.each do |attrs|
  Permission.find_or_create_by!(attrs)
end

puts "Seeded #{Permission.count} permissions."

Organization.find_each do |organization|
  SeedOrganizationRoles.call(organization)
  SeedWorkflowTemplates.call(organization)
end

puts "Seeded workflow templates for #{Organization.count} organizations."
