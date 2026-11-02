# Turns an uploaded file into a Claude content block: PDF as a document, photos as an image
# (HEIC and other formats converted to JPEG), spreadsheets and CSV as text (Claude does not read .xlsx).
module Ai
  class Attachment
    IMAGE_TYPES = %w[image/jpeg image/png image/gif image/webp].freeze
    SHEET_EXTS = %w[xlsx csv].freeze
    MAX_ROWS = 2000

    def self.block(uploader) = new(uploader).block

    def initialize(uploader)
      @uploader = uploader
      @path = uploader.path
      @name = uploader.file&.filename.to_s
      @ext = File.extname(@name).delete(".").downcase
      @type = uploader.content_type.to_s
    end

    def block
      if @type == "application/pdf" || @ext == "pdf"
        { type: :document, source: { type: :base64, media_type: "application/pdf", data: base64(File.binread(@path)) } }
      elsif IMAGE_TYPES.include?(@type)
        { type: :image, source: { type: :base64, media_type: @type, data: base64(File.binread(@path)) } }
      elsif @type.start_with?("image/") || %w[heic heif].include?(@ext)
        { type: :image, source: { type: :base64, media_type: "image/jpeg", data: base64(jpeg) } }
      elsif SHEET_EXTS.include?(@ext)
        { type: :text, text: "File #{@name}, first sheet as rows (columns separated by |):\n#{sheet_text}" }
      elsif @ext == "txt" || @type.start_with?("text/")
        { type: :text, text: "File #{@name}:\n#{File.read(@path)}" }
      else
        raise ApplicationService::Error, "#{@name} can't be read. Use a PDF, a photo, an Excel (.xlsx) file or a CSV"
      end
    end

    private

    def base64(bytes) = Base64.strict_encode64(bytes)

    def jpeg
      image = MiniMagick::Image.open(@path)
      image.format("jpg")
      image.resize("2000x2000>")
      File.binread(image.path)
    end

    def sheet_text
      sheet = Roo::Spreadsheet.open(@path, extension: @ext.to_sym).sheet(0)
      return "" unless sheet.first_row

      last = [ sheet.last_row, sheet.first_row + MAX_ROWS - 1 ].min
      (sheet.first_row..last).map { |i| sheet.row(i).map { |c| c.to_s.squish }.join(" | ") }.join("\n")
    end
  end
end
