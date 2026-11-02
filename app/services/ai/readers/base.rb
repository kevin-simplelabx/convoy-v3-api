# A reader: what to ask Claude for one kind of document, the schema of the reply and how to clean it.
# Fixed prompts use the class macros; a reader whose prompt depends on the company (Clients, Vehicle Types) overrides
# #instructions. Readers run inside the company (DocumentReadJob).
module Ai
  module Readers
    class Base
      class << self
        attr_reader :fixed_instructions, :schema, :effort

        def ask(text) = @fixed_instructions = text.squish
        def reply(schema) = @schema = schema
        def thinking(effort) = @effort = effort

        def read(attachment: nil, text: nil)
          reader = new
          result = Ai::Extract.call(instructions: reader.instructions, schema:, attachment:, text: reader.input(text),
                                    effort: effort || :medium)
          [ reader.clean(result.data.with_indifferent_access), result ]
        end
      end

      def instructions = self.class.fixed_instructions

      # The text sent after the instructions (a pasted message).
      def input(text) = text

      private

      def str(v) = v.to_s.squish.presence
      def plate(v) = v.to_s.upcase.gsub(/[^A-Z0-9]/, "").presence

      def date(v)
        Date.iso8601(v.to_s).iso8601
      rescue Date::Error
        nil
      end

      def number(v)
        n = v.to_s.gsub(/[^\d.\-]/, "")
        n.match?(/\A-?\d+(\.\d+)?\z/) ? BigDecimal(n).round(2).to_s("F") : nil
      end

      # "84,210 km" -> 84210; "13 seats" -> 13
      def integer(v) = v.to_s.gsub(/(?<=\d)[,\s](?=\d{3})/, "")[/\d+/]&.to_i

      # "8am" is not expected (the prompt asks for HH:MM); "8.15" and "08:15" become "08:15".
      def time(v)
        m = v.to_s.match(/\A(\d{1,2})[:.](\d{2})/)
        m && format("%02d:%s", [ m[1].to_i, 23 ].min, m[2])
      end

      # Digits only; a Singapore number with +65 loses the country code.
      def phone(v)
        d = v.to_s.gsub(/\D/, "")
        d = d[2..] if d.length == 10 && d.start_with?("65")
        d.presence
      end
    end
  end
end
