/// Kitchen Localizations
/// Multi-language support for Kitchen Orders (English, Amharic, Oromo)
class KitchenLocalizations {
  final String languageCode;
  
  KitchenLocalizations(this.languageCode);
  
  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // Status labels
      'pending': 'Pending',
      'confirmed': 'Confirmed',
      'preparing': 'Preparing',
      'ready': 'Ready',
      'completed': 'Completed',
      'cancelled': 'Cancelled',
      
      // Action buttons
      'accept_order': 'Accept Order',
      'reject_order': 'Reject',
      'start_preparing': 'Start Preparing',
      'mark_ready': 'Mark as Ready',
      'complete': 'Complete',
      'edit_order': 'Edit Order',
      'save_changes': 'Save Changes',
      'cancel': 'Cancel',
      
      // Notifications
      'order_accepted': 'Order Accepted',
      'order_rejected': 'Order Rejected',
      'order_ready': 'Order Ready',
      'order_completed': 'Order Completed',
      'order_preparing': 'Order Being Prepared',
      'customer_notified': 'Customer has been notified',
      
      // Messages
      'reject_confirmation': 'Are you sure you want to reject this order?',
      'reject_reason': 'Reason for rejection (optional)',
      'add_item': 'Add Item',
      'remove_item': 'Remove',
      'quantity': 'Quantity',
      'price': 'Price',
      'total': 'Total',
      'notes': 'Notes',
      'table': 'Table',
      'order_number': 'Order',
      
      // Waiter calls
      'waiter_calls': 'Waiter Calls',
      'customer_assistance': 'Customer needs assistance',
      'attend': 'Attend',
      'no_active_calls': 'No active waiter calls',
      
      // Errors
      'failed_accept': 'Failed to accept order',
      'failed_reject': 'Failed to reject order',
      'failed_update': 'Failed to update order',
    },
    
    'am': {
      // Status labels - Amharic
      'pending': 'በመጠባበቅ ላይ',
      'confirmed': 'የተረጋገጠ',
      'preparing': 'በማዘጋጀት ላይ',
      'ready': 'ዝግጁ',
      'completed': 'የተጠናቀቀ',
      'cancelled': 'የተቋረጠ',
      
      // Action buttons - Amharic
      'accept_order': 'ትዕዛዝ ተቀበል',
      'reject_order': 'አትቀበል',
      'start_preparing': 'ማዘጋጀት ጀምር',
      'mark_ready': 'ዝግጁ አድርግ',
      'complete': 'ጨርስ',
      'edit_order': 'ትዕዛዝ አስተካክል',
      'save_changes': 'ለውጦችን አስታምር',
      'cancel': 'ተው',
      
      // Notifications - Amharic
      'order_accepted': 'ትዕዛዝ ተቀብሏል',
      'order_rejected': 'ትዕዛዝ ተከልክሏል',
      'order_ready': 'ትዕዛዝ ዝግጁ ነው',
      'order_completed': 'ትዕዛዝ ተጠናቋል',
      'order_preparing': 'ትዕዛዝ በማዘጋጀት ላይ ነው',
      'customer_notified': 'ደንበኛው ተነግሮታል',
      
      // Messages - Amharic
      'reject_confirmation': 'ይህን ትዕዛዝ ለመቀበል እንደማይፈልጉ እርግጠኛ ነዎት?',
      'reject_reason': 'ምክንያት (ከፈለጉ)',
      'add_item': 'አክል',
      'remove_item': 'አስወግድ',
      'quantity': 'ብዛት',
      'price': 'ዋጋ',
      'total': 'ጠቅላላ',
      'notes': 'ማስታወሻ',
      'table': 'ማዘዣ ጠረፍ',
      'order_number': 'ትዕዛዝ',
      
      // Waiter calls - Amharic
      'waiter_calls': 'አስተናጋጅ ጥሪዎች',
      'customer_assistance': 'ደንበኛው እርዳታ ይፈልጋል',
      'attend': 'ተንከባክብ',
      'no_active_calls': 'ንቁ ጥሪዎች የሉም',
      
      // Errors - Amharic
      'failed_accept': 'ትዕዛዝ መቀበል አልተቻለም',
      'failed_reject': 'ትዕዛዝ መከልከል አልተቻለም',
      'failed_update': 'ትዕዛዝ ማዘመን አልተቻለም',
    },
    
    'om': {
      // Status labels - Oromo
      'pending': 'Eeggataa jira',
      'confirmed': 'Mirkaneeffame',
      'preparing': 'Qophaa\'aa jira',
      'ready': 'Qopheessa',
      'completed': 'Xummurame',
      'cancelled': 'Haqsame',
      
      // Action buttons - Oromo
      'accept_order': 'Ajaja Fudhadhu',
      'reject_order': 'Dhiisi',
      'start_preparing': 'Qophaa\'uu Eegali',
      'mark_ready': 'Qopheessaa Akkasi',
      'complete': 'Xumuri',
      'edit_order': 'Ajaja Gulaali',
      'save_changes': 'Jijjiirama Qusadhu',
      'cancel': 'Dhiisi',
      
      // Notifications - Oromo
      'order_accepted': 'Ajaja Fudhatame',
      'order_rejected': 'Ajaja Dhiisame',
      'order_ready': 'Ajaja Qopheesse',
      'order_completed': 'Ajaja Xummurame',
      'order_preparing': 'Ajaja Qophaa\'aa jira',
      'customer_notified': 'Maamilaa beeksifameera',
      
      // Messages - Oromo
      'reject_confirmation': 'Ajaja kana dhiisuuf amantaa qabduu?',
      'reject_reason': 'Sababa (yoo barbaaddan)',
      'add_item': 'Dabali',
      'remove_item': 'Haqi',
      'quantity': 'Hamma',
      'price': 'Gatii',
      'total': 'Waliigala',
      'notes': 'Yaadannoo',
      'table': 'Taablee',
      'order_number': 'Ajaja',
      
      // Waiter calls - Oromo
      'waiter_calls': 'Waayitarii Bilbiloota',
      'customer_assistance': 'Maamila gargaarsa barbaada',
      'attend': 'Tumsaa',
      'no_active_calls': 'Bilbiloota socho\'aa hin jiru',
      
      // Errors - Oromo
      'failed_accept': 'Ajaja fudhachuu hin dandeenye',
      'failed_reject': 'Ajaja dhiisuu hin dandeenye',
      'failed_update': 'Ajaja haaromsuu hin dandeenye',
    },
  };
  
  String get(String key) {
    return _localizedValues[languageCode]?[key] ?? 
           _localizedValues['en']?[key] ?? 
           key;
  }
  
  // Static method for supported languages
  static List<String> get supportedLanguages => ['en', 'am', 'om'];
  
  static String getLanguageName(String code) {
    switch (code) {
      case 'en': return 'English';
      case 'am': return 'አማርኛ';
      case 'om': return 'Afaan Oromoo';
      default: return 'English';
    }
  }
}
