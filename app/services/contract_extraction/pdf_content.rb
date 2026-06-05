require "base64"
require "open3"
require "stringio"
require "tempfile"

module ContractExtraction
  class PdfContent
    Page = Struct.new(:number, :text, :image_base64, keyword_init: true)

    def self.call(master_agreement_document)
      new(master_agreement_document).call
    end

    def initialize(master_agreement_document)
      @master_agreement_document = master_agreement_document
    end

    def call
      pdf_bytes = master_agreement_document.file.download
      pages = extract_text_pages(pdf_bytes)
      images_by_page = render_sparse_pages(pdf_bytes, pages)

      {
        filename: master_agreement_document.file.filename.to_s,
        content_type: master_agreement_document.file.content_type,
        file_base64: Base64.strict_encode64(pdf_bytes),
        pages: pages.map do |page|
          Page.new(number: page.fetch(:number), text: page.fetch(:text), image_base64: images_by_page[page.fetch(:number)])
        end
      }
    end

    private

      attr_reader :master_agreement_document

      def extract_text_pages(pdf_bytes)
        require "pdf/reader"

        reader = PDF::Reader.new(StringIO.new(pdf_bytes))
        reader.pages.map.with_index(1) do |page, index|
          { number: index, text: page.text.to_s }
        end
      rescue StandardError
        [ { number: 1, text: "" } ]
      end

      def render_sparse_pages(pdf_bytes, pages)
        return {} unless pdftoppm_available?

        sparse_pages = pages.select { |page| page.fetch(:text).squish.length < 200 }.map { |page| page.fetch(:number) }
        return {} if sparse_pages.blank?

        Tempfile.create([ "contract-packet", ".pdf" ]) do |pdf|
          pdf.binmode
          pdf.write(pdf_bytes)
          pdf.flush

          sparse_pages.to_h do |page_number|
            [ page_number, render_page(pdf.path, page_number) ]
          end.compact
        end
      end

      def pdftoppm_available?
        system("which pdftoppm > /dev/null 2>&1")
      end

      def render_page(pdf_path, page_number)
        Tempfile.create([ "contract-page", "" ]) do |prefix|
          prefix.close
          output_prefix = prefix.path
          _stdout, _stderr, status = Open3.capture3(
            "pdftoppm",
            "-f", page_number.to_s,
            "-l", page_number.to_s,
            "-png",
            "-r", "180",
            pdf_path,
            output_prefix
          )
          return nil unless status.success?

          image_path = Dir["#{output_prefix}-*.png"].first
          return nil unless image_path && File.exist?(image_path)

          Base64.strict_encode64(File.binread(image_path))
        ensure
          Dir["#{output_prefix}-*.png"].each { |path| File.delete(path) if File.exist?(path) } if output_prefix
        end
      end
  end
end
