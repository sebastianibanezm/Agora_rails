class Avo::Resources::SourceOfTruthRuleTarget < Avo::BaseResource
  self.includes = [ :organization, :source_of_truth_rule, :document_template ]

  def fields
    field :id, as: :id
    field :organization, as: :belongs_to
    field :source_of_truth_rule, as: :belongs_to
    field :document_template, as: :belongs_to
    field :correction_note, as: :textarea
  end
end
