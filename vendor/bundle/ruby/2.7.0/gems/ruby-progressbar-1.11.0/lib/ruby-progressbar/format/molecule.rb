class ProgressBar
  module Format
    class Molecule
      MOLECULES = {
        t: %i[title_comp title],
        T: %i[title_comp title],
        c: %i[progressable progress],
        C: %i[progressable total],
        u: %i[progressable total_with_unknown_indicator],
        p: %i[percentage percentage],
        P: %i[percentage percentage_with_precision],
        j: %i[percentage justified_percentage],
        J: %i[percentage justified_percentage_with_precision],
        a: %i[time elapsed_with_label],
        e: %i[time estimated_with_unknown_oob],
        E: %i[time estimated_with_friendly_oob],
        f: %i[time estimated_with_no_oob],
        B: %i[bar complete_bar],
        b: %i[bar bar],
        W: %i[bar complete_bar_with_percentage],
        w: %i[bar bar_with_percentage],
        i: %i[bar incomplete_space],
        r: %i[rate rate_of_change],
        R: %i[rate rate_of_change_with_precision]
      }.freeze

      BAR_MOLECULES = %w[W w B b i].freeze

      attr_accessor :key,
                    :method_name

      def initialize(letter)
        self.key = letter
        self.method_name = MOLECULES.fetch(key.to_sym)
      end

      def bar_molecule?
        BAR_MOLECULES.include? key
      end

      def non_bar_molecule?
        !bar_molecule?
      end

      def full_key
        "%#{key}"
      end

      def lookup_value(environment, length = 0)
        component = environment.__send__(method_name[0])

        if bar_molecule?
          component.__send__(method_name[1], length).to_s
        else
          component.__send__(method_name[1]).to_s
        end
      end
    end
  end
end
