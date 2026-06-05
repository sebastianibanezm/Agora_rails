require "json"
require "net/http"
require "uri"

module ContractExtraction
  class AiClient
    SCHEMA_VERSION = "master_agreement_packet.v1".freeze

    class ConfigurationError < StandardError; end

    def initialize(endpoint: ENV["MASTER_AGREEMENT_EXTRACTION_ENDPOINT"],
                   api_key: ENV["MASTER_AGREEMENT_EXTRACTION_API_KEY"],
                   model: ENV.fetch("MASTER_AGREEMENT_EXTRACTION_MODEL", "contract-extractor"))
      @endpoint = endpoint
      @api_key = api_key
      @model = model
    end

    def extract(master_agreement_document, pdf_content)
      raise ConfigurationError, "MASTER_AGREEMENT_EXTRACTION_ENDPOINT is not configured" if endpoint.blank?

      response = JSON.parse(post_json(payload_for(master_agreement_document, pdf_content)))
      response.fetch("extraction", response)
    end

    private

      attr_reader :endpoint, :api_key, :model

      def payload_for(master_agreement_document, pdf_content)
        {
          model: model,
          schema_version: SCHEMA_VERSION,
          instructions: extraction_instructions,
          document: {
            id: master_agreement_document.id,
            title: master_agreement_document.title,
            document_kind: master_agreement_document.document_kind,
            filename: pdf_content.fetch(:filename),
            content_type: pdf_content.fetch(:content_type)
          },
          pages: pdf_content.fetch(:pages).map do |page|
            {
              number: page.number,
              text: page.text,
              image_base64: page.image_base64
            }.compact
          end,
          file_base64: pdf_content.fetch(:file_base64)
        }
      end

      def extraction_instructions
        <<~TEXT.squish
          Extract a private-label master supply agreement packet into strict JSON.
          Include parties, notice addresses, signers, DocuSign envelope metadata,
          schedules, participating companies, distributors, payment terms, delivery terms,
          lead times, pallet requirements, unsaleables, delivery locations, product pricing
          rows, clause obligations, and individual field values with source page and confidence.
          Return only JSON matching schema_version #{SCHEMA_VERSION}.
        TEXT
      end

      def post_json(payload)
        uri = URI(endpoint)
        request = Net::HTTP::Post.new(uri)
        request["Content-Type"] = "application/json"
        request["Authorization"] = "Bearer #{api_key}" if api_key.present?
        request.body = JSON.generate(payload)

        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
          http.request(request)
        end
        raise "AI extraction failed with HTTP #{response.code}: #{response.body}" unless response.is_a?(Net::HTTPSuccess)

        response.body
      end
  end
end
