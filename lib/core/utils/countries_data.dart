/// Country model for filtering
class Country {
  final String code;
  final String name;
  final String flag;
  final String region;

  const Country({
    required this.code,
    required this.name,
    required this.flag,
    required this.region,
  });
}

/// List of countries with flags and ISO codes
const List<Country> countries = [
  // Middle East & North Africa
  Country(code: 'LB', name: 'Lebanon', flag: '🇱🇧', region: 'Middle East'),
  Country(code: 'AE', name: 'United Arab Emirates', flag: '🇦🇪', region: 'Middle East'),
  Country(code: 'SA', name: 'Saudi Arabia', flag: '🇸🇦', region: 'Middle East'),
  Country(code: 'QA', name: 'Qatar', flag: '🇶🇦', region: 'Middle East'),
  Country(code: 'KW', name: 'Kuwait', flag: '🇰🇼', region: 'Middle East'),
  Country(code: 'BH', name: 'Bahrain', flag: '🇧🇭', region: 'Middle East'),
  Country(code: 'OM', name: 'Oman', flag: '🇴🇲', region: 'Middle East'),
  Country(code: 'JO', name: 'Jordan', flag: '🇯🇴', region: 'Middle East'),
  Country(code: 'EG', name: 'Egypt', flag: '🇪🇬', region: 'Middle East'),
  Country(code: 'MA', name: 'Morocco', flag: '🇲🇦', region: 'Middle East'),
  Country(code: 'TN', name: 'Tunisia', flag: '🇹🇳', region: 'Middle East'),

  // Europe
  Country(code: 'FR', name: 'France', flag: '🇫🇷', region: 'Europe'),
  Country(code: 'ES', name: 'Spain', flag: '🇪🇸', region: 'Europe'),
  Country(code: 'IT', name: 'Italy', flag: '🇮🇹', region: 'Europe'),
  Country(code: 'DE', name: 'Germany', flag: '🇩🇪', region: 'Europe'),
  Country(code: 'GB', name: 'United Kingdom', flag: '🇬🇧', region: 'Europe'),
  Country(code: 'CH', name: 'Switzerland', flag: '🇨🇭', region: 'Europe'),
  Country(code: 'GR', name: 'Greece', flag: '🇬🇷', region: 'Europe'),
  Country(code: 'TR', name: 'Turkey', flag: '🇹🇷', region: 'Europe'),
  Country(code: 'CY', name: 'Cyprus', flag: '🇨🇾', region: 'Europe'),
  Country(code: 'PT', name: 'Portugal', flag: '🇵🇹', region: 'Europe'),

  // Americas
  Country(code: 'US', name: 'United States', flag: '🇺🇸', region: 'Americas'),
  Country(code: 'CA', name: 'Canada', flag: '🇨🇦', region: 'Americas'),
  Country(code: 'MX', name: 'Mexico', flag: '🇲🇽', region: 'Americas'),
  Country(code: 'BR', name: 'Brazil', flag: '🇧🇷', region: 'Americas'),
  Country(code: 'AR', name: 'Argentina', flag: '🇦🇷', region: 'Americas'),

  // Asia Pacific
  Country(code: 'JP', name: 'Japan', flag: '🇯🇵', region: 'Asia Pacific'),
  Country(code: 'CN', name: 'China', flag: '🇨🇳', region: 'Asia Pacific'),
  Country(code: 'SG', name: 'Singapore', flag: '🇸🇬', region: 'Asia Pacific'),
  Country(code: 'AU', name: 'Australia', flag: '🇦🇺', region: 'Asia Pacific'),
  Country(code: 'NZ', name: 'New Zealand', flag: '🇳🇿', region: 'Asia Pacific'),
  Country(code: 'TH', name: 'Thailand', flag: '🇹🇭', region: 'Asia Pacific'),
  Country(code: 'MY', name: 'Malaysia', flag: '🇲🇾', region: 'Asia Pacific'),
  Country(code: 'ID', name: 'Indonesia', flag: '🇮🇩', region: 'Asia Pacific'),
];

/// Get country by code
Country? getCountryByCode(String code) {
  try {
    return countries.firstWhere((c) => c.code == code);
  } catch (_) {
    return null;
  }
}
