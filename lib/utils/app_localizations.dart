/// Localization support for SentryKSA - English & Arabic.
class AppLocalizations {
  final String locale; // 'en' or 'ar'

  AppLocalizations(this.locale);

  bool get isArabic => locale == 'ar';
  bool get isEnglish => locale == 'en';

  static const Map<String, Map<String, String>> _translations = {
    // App-wide
    'app_title': {
      'en': 'SentryKSA',
      'ar': 'حارس المملكة',
    },
    'app_subtitle': {
      'en': 'Strategic Risk Monitoring',
      'ar': 'مراقبة المخاطر الاستراتيجية',
    },

    // War Room
    'war_room': {
      'en': 'War Room',
      'ar': 'غرفة العمليات',
    },
    'imminent_threat': {
      'en': 'IMMINENT THREAT',
      'ar': 'تهديد وشيك',
    },
    'target_corridor': {
      'en': 'Target Corridor',
      'ar': 'ممر الهدف',
    },
    'shelter': {
      'en': 'SHELTER',
      'ar': 'احتماء',
    },
    'evacuate': {
      'en': 'EVACUATE',
      'ar': 'إخلاء',
    },
    'share': {
      'en': 'SHARE',
      'ar': 'مشاركة',
    },

    // Threat types
    'ballistic': {
      'en': 'BALLISTIC',
      'ar': 'باليستي',
    },
    'cruise': {
      'en': 'CRUISE MISSILE',
      'ar': 'صاروخ كروز',
    },
    'drone': {
      'en': 'DRONE / UAV',
      'ar': 'طائرة مسيّرة',
    },
    'cyber': {
      'en': 'CYBER ATTACK',
      'ar': 'هجوم سيبراني',
    },
    'naval': {
      'en': 'NAVAL THREAT',
      'ar': 'تهديد بحري',
    },
    'hybrid': {
      'en': 'HYBRID',
      'ar': 'هجين',
    },

    // Sectors
    'energy': {
      'en': 'Energy',
      'ar': 'الطاقة',
    },
    'water': {
      'en': 'Water',
      'ar': 'المياه',
    },
    'govt': {
      'en': 'Government',
      'ar': 'حكومي',
    },
    'data': {
      'en': 'Data Center',
      'ar': 'مركز بيانات',
    },

    // Risk levels
    'risk_high': {
      'en': 'HIGH RISK',
      'ar': 'خطر مرتفع',
    },
    'risk_medium': {
      'en': 'MEDIUM RISK',
      'ar': 'خطر متوسط',
    },
    'risk_low': {
      'en': 'LOW RISK',
      'ar': 'خطر منخفض',
    },

    // Analytics panel
    'strikes_since_feb': {
      'en': 'Strikes (Feb 28)',
      'ar': 'الضربات (28 فبراير)',
    },
    'intercept_rate': {
      'en': 'Intercept Rate',
      'ar': 'معدل الاعتراض',
    },
    'brent_impact': {
      'en': 'Brent Impact',
      'ar': 'تأثير برنت',
    },
    'critical_hvts': {
      'en': 'Critical HVTs',
      'ar': 'أهداف حرجة',
    },
    'defense_posture_strong': {
      'en': 'DEFENSE POSTURE: STRONG',
      'ar': 'الوضع الدفاعي: قوي',
    },
    'defense_posture_degraded': {
      'en': 'DEFENSE POSTURE: DEGRADED',
      'ar': 'الوضع الدفاعي: متدهور',
    },

    // Economic impact
    'economic_impact': {
      'en': 'ECONOMIC IMPACT',
      'ar': 'الأثر الاقتصادي',
    },
    'daily_revenue_loss': {
      'en': 'Daily Revenue Loss',
      'ar': 'خسارة الإيرادات اليومية',
    },
    'supply_shock': {
      'en': 'Supply Shock',
      'ar': 'صدمة العرض',
    },
    'brent_surge': {
      'en': 'Brent Surge',
      'ar': 'ارتفاع برنت',
    },
    'projected_brent': {
      'en': 'Projected Brent',
      'ar': 'سعر برنت المتوقع',
    },
    'supply_chain_cascade': {
      'en': 'SUPPLY CHAIN CASCADE',
      'ar': 'تأثير سلسلة الإمداد',
    },

    // Recovery
    'day_zero_recovery': {
      'en': 'DAY ZERO RECOVERY',
      'ar': 'خطة إعادة التأهيل - اليوم صفر',
    },
    'damage_tier': {
      'en': 'Damage Tier',
      'ar': 'مستوى الضرر',
    },
    'estimated_repair': {
      'en': 'Estimated Repair',
      'ar': 'مدة الإصلاح المتوقعة',
    },
    'output_value': {
      'en': 'Output Value',
      'ar': 'قيمة الإنتاج',
    },
    'total_recovery_cost': {
      'en': 'Total Recovery Cost',
      'ar': 'تكلفة الاسترداد الكلية',
    },
    'superficial': {
      'en': 'Superficial',
      'ar': 'سطحي',
    },
    'component': {
      'en': 'Component',
      'ar': 'مكوّنات',
    },
    'structural': {
      'en': 'Structural',
      'ar': 'هيكلي',
    },

    // Threat assessment
    'threat_assessment': {
      'en': 'THREAT ASSESSMENT',
      'ar': 'تقييم التهديد',
    },
    'score': {
      'en': 'Score',
      'ar': 'الدرجة',
    },
    'alert_level': {
      'en': 'Alert Level',
      'ar': 'مستوى التنبيه',
    },
    'eta': {
      'en': 'ETA',
      'ar': 'الوقت المتوقع',
    },
    'primary_source': {
      'en': 'Primary Source',
      'ar': 'المصدر الرئيسي',
    },
    'contributing_events': {
      'en': 'Contributing Events',
      'ar': 'الأحداث المساهمة',
    },

    // Prescriptive advice
    'prescriptive_advice': {
      'en': 'PRESCRIPTIVE ADVICE',
      'ar': 'التوصيات',
    },
    'advice_hardened_storage': {
      'en': 'Hardened storage online. Move workers to Safe Zone 4. Maintain Patriot battery readiness.',
      'ar': 'تفعيل التخزين المحصّن. نقل العمال إلى المنطقة الآمنة 4. الحفاظ على جاهزية بطاريات باتريوت.',
    },

    // Proximity alerts
    'proximity_alert_siren': {
      'en': 'EVACUATE: You are near an active threat zone!',
      'ar': 'إخلاء فوري: أنت بالقرب من منطقة تهديد نشطة!',
    },
    'proximity_alert_warning': {
      'en': 'WARNING: Threat detected nearby. Move to safe zone.',
      'ar': 'تحذير: تم رصد تهديد قريب. انتقل إلى منطقة آمنة.',
    },

    // Sources
    'centcom': {
      'en': 'US CENTCOM',
      'ar': 'القيادة المركزية الأمريكية',
    },
    'idf': {
      'en': 'IDF Intelligence',
      'ar': 'استخبارات الجيش الإسرائيلي',
    },
    'irna': {
      'en': 'IRNA / IRGC',
      'ar': 'وكالة إرنا / الحرس الثوري',
    },

    // Connection status
    'live': {
      'en': 'LIVE',
      'ar': 'مباشر',
    },
    'connecting': {
      'en': 'CONNECTING',
      'ar': 'جاري الاتصال',
    },
    'offline': {
      'en': 'OFFLINE',
      'ar': 'غير متصل',
    },
    'idle': {
      'en': 'IDLE',
      'ar': 'خامل',
    },

    // Settings
    'settings': {
      'en': 'Settings',
      'ar': 'الإعدادات',
    },
    'language': {
      'en': 'Language',
      'ar': 'اللغة',
    },
    'arabic': {
      'en': 'Arabic',
      'ar': 'العربية',
    },
    'english': {
      'en': 'English',
      'ar': 'الإنجليزية',
    },
    'notifications': {
      'en': 'Notifications',
      'ar': 'الإشعارات',
    },
    'proximity_alerts': {
      'en': 'Proximity Alerts',
      'ar': 'تنبيهات القرب',
    },
    'siren_enabled': {
      'en': 'Siren Enabled',
      'ar': 'تفعيل صفارة الإنذار',
    },
    'alert_radius': {
      'en': 'Alert Radius',
      'ar': 'نطاق التنبيه',
    },

    // Provinces
    'eastern_province': {
      'en': 'Eastern Province',
      'ar': 'المنطقة الشرقية',
    },
    'riyadh_province': {
      'en': 'Riyadh Province',
      'ar': 'منطقة الرياض',
    },
    'makkah_province': {
      'en': 'Makkah Province',
      'ar': 'منطقة مكة المكرمة',
    },
    'madinah_province': {
      'en': 'Madinah Province',
      'ar': 'منطقة المدينة المنورة',
    },
    'asir_province': {
      'en': 'Asir Province',
      'ar': 'منطقة عسير',
    },
    'jazan_province': {
      'en': 'Jazan Province',
      'ar': 'منطقة جازان',
    },
    'najran_province': {
      'en': 'Najran Province',
      'ar': 'منطقة نجران',
    },
    'tabuk_province': {
      'en': 'Tabuk Province',
      'ar': 'منطقة تبوك',
    },
    'northern_borders': {
      'en': 'Northern Borders',
      'ar': 'منطقة الحدود الشمالية',
    },
    'hail_province': {
      'en': "Ha'il Province",
      'ar': 'منطقة حائل',
    },

    // Days
    'days': {
      'en': 'Days',
      'ar': 'يوم',
    },
    'sources': {
      'en': 'sources',
      'ar': 'مصادر',
    },
    'global': {
      'en': 'global',
      'ar': 'عالمي',
    },
  };

  /// Get translated string by key.
  String tr(String key) {
    return _translations[key]?[locale] ?? _translations[key]?['en'] ?? key;
  }

  /// Get localized risk level label.
  String riskLabel(int level) {
    switch (level) {
      case 3:
        return tr('risk_high');
      case 2:
        return tr('risk_medium');
      default:
        return tr('risk_low');
    }
  }

  /// Get localized sector name.
  String sectorName(String sector) {
    switch (sector) {
      case 'Energy':
        return tr('energy');
      case 'Water':
        return tr('water');
      case 'Govt':
        return tr('govt');
      case 'Data':
        return tr('data');
      default:
        return sector;
    }
  }

  /// Get localized threat type.
  String threatTypeName(String type) {
    return tr(type.toLowerCase());
  }

  /// Get localized repair tier label.
  String repairTierName(int tier) {
    switch (tier) {
      case 1:
        return tr('superficial');
      case 2:
        return tr('component');
      case 3:
        return tr('structural');
      default:
        return 'N/A';
    }
  }
}
