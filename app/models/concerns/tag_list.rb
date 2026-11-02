# String array columns that also take text with commas ("Coach, VIP"): squished, blanks and repeats dropped.
#   tag_list :tags
module TagList
  extend ActiveSupport::Concern

  class_methods do
    def tag_list(*columns)
      columns.each do |col|
        define_method(:"#{col}=") do |value|
          list = value.is_a?(String) ? value.split(",") : Array(value).flat_map { |v| v.to_s.split(",") }
          super(list.map(&:squish).compact_blank.uniq)
        end
      end
    end
  end
end
