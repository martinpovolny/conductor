module CostEngine
  # implements billing models and utility methods and classing for dealing with
  # billing models
  class BillingModel
    public
    NONE=0

    def self.find(model_num)
      MODELS[model_num][:class]
    end

    # FIXME/note: have to call gettext on these, probably at the view level?
    def self.options_for_select
      MODELS.inject(OptionsForSelect.new) { |options,(model_num,model)| options.merge!(model[:name] => model_num) }
    end

    # collection of all available billing models
    private
    MODELS = {}

    # helper class representing options for <select> html tag and it's rails helper
    class OptionsForSelect < Hash
      def with_none
        merge('none' => NONE)
      end

      def no_parts
        reject { |_,model_num| model_num == 3 }
      end
    end

    # follows implementation of various billing models:
    #  * pay per day/hour/wallclock hour/[minute?]
    #  * later may need per start/stop/whatever
    class WallClockHour
      def self.calculate(price_per_hour, start_t, end_t)
        start_t = start_t.change( :min=> 1  )
        end_t   = end_t.change(   :min=> 59 )
        price_per_hour * ((end_t-start_t + 3600) / 3600).to_i
      end
      BillingModel::MODELS[1] = { 
        :class => self,
        :name  => 'per wall clock hour'
      }
    end

    class Hour
      def self.calculate(price_per_hour, start_t, end_t)
        price_per_hour * ((end_t-start_t + 3600) / 3600).to_i
      end
      BillingModel::MODELS[2] = { 
        :class => self,
        :name  => 'per hour'
      }
    end

    class PerProperty
      def self.calculate(price_per_hour, start_t, end_t)
        0
      end
      BillingModel::MODELS[3] = {
        :class => self,
        :name => 'per property'
      }
    end
  end
end
