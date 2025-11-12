module Currency
  class ConversionService
    # Default conversion rates - in production, these would come from a currency API
    # All rates are relative to USD (base currency)
    CONVERSION_RATES = {
      'USD' => 1.0,
      'NGN' => 0.00065,  # 1 NGN = 0.00065 USD (approximate)
      'GHS' => 0.083,    # 1 GHS = 0.083 USD (approximate)
      'KES' => 0.0077,   # 1 KES = 0.0077 USD (approximate)
      'ZAR' => 0.053,    # 1 ZAR = 0.053 USD (approximate)
      'EUR' => 1.08,     # 1 EUR = 1.08 USD (approximate)
      'GBP' => 1.27      # 1 GBP = 1.27 USD (approximate)
    }.freeze

    SUPPORTED_CURRENCIES = %w[USD NGN GHS KES ZAR EUR GBP].freeze

    class << self
      def convert_to_usd(amount, from_currency)
        return 0 unless amount.present? && from_currency.present?

        rate = CONVERSION_RATES[from_currency] || 1.0
        (amount.to_f * rate).round(2)
      end

      def convert_from_usd(amount_usd, to_currency)
        return 0 unless amount_usd.present? && to_currency.present?

        rate = CONVERSION_RATES[to_currency] || 1.0
        (amount_usd.to_f / rate).round(2)
      end

      def convert(amount, from_currency, to_currency)
        return 0 unless amount.present? && from_currency.present? && to_currency.present?
        return amount if from_currency == to_currency

        # Convert through USD as base currency
        amount_in_usd = convert_to_usd(amount, from_currency)
        convert_from_usd(amount_in_usd, to_currency)
      end

      def supported_currencies
        SUPPORTED_CURRENCIES
      end

      def default_currency
        "NGN" # Default to Nigerian Naira as requested
      end

      def get_rate(currency)
        CONVERSION_RATES[currency] || 1.0
      end

      def update_rates(new_rates)
        # This would typically fetch from an external API
        # For now, we'll keep the static rates
        CONVERSION_RATES.merge(new_rates)
      end
    end
  end
end
