import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {
  final _messageController = TextEditingController();
  int _expandedIndex = -1;

  final List<Map<String, String>> _faqs = [
    {
      'question': 'How do I track my order?',
      'answer':
          'Go to My Orders from your profile, tap on any order to see real-time tracking with delivery status updates.',
    },
    {
      'question': 'What payment methods are accepted?',
      'answer':
          'We accept Telebirr, M-Pesa, CBE Birr, Cash on Delivery, and major credit/debit cards.',
    },
    {
      'question': 'How can I cancel my order?',
      'answer':
          'You can cancel within 5 minutes of placing. Go to My Orders, select the order, and tap Cancel.',
    },
    {
      'question': 'What if my order is late?',
      'answer':
          'Contact support through this page. We\'ll investigate and may offer compensation.',
    },
    {
      'question': 'How do I become a delivery partner?',
      'answer':
          'Visit our website or contact us at partners@foodiego.com to apply.',
    },
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildContactCards(),
            const SizedBox(height: 24),
            _buildFAQSection(),
            const SizedBox(height: 24),
            _buildContactForm(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: AppTheme.textPrimary),
        ),
      ),
      title: const Text('Help & Support',
          style: TextStyle(
              color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
      centerTitle: true,
    );
  }

  Widget _buildContactCards() {
    return Row(
      children: [
        Expanded(
          child: _buildContactCard(
            Icons.phone,
            'Call Us',
            '+251 911 123 456',
            AppTheme.accentGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildContactCard(
            Icons.email,
            'Email Us',
            'support@foodiego.com',
            AppTheme.accentBlue,
          ),
        ),
      ],
    );
  }

  Widget _buildContactCard(
      IconData icon, String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildFAQSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text('Frequently Asked Questions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            children: _faqs.asMap().entries.map((entry) {
              final index = entry.key;
              final faq = entry.value;
              return _buildFAQItem(faq, index);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFAQItem(Map<String, String> faq, int index) {
    final isExpanded = _expandedIndex == index;
    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _expandedIndex = isExpanded ? -1 : index),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.help_outline,
                      color: AppTheme.primaryColor, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(faq['question']!,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Container(
            padding: const EdgeInsets.fromLTRB(56, 0, 16, 16),
            child: Text(faq['answer']!,
                style: TextStyle(color: Colors.grey.shade600, height: 1.5)),
          ),
        if (index < _faqs.length - 1)
          Divider(height: 1, color: Colors.grey.shade100),
      ],
    );
  }

  Widget _buildContactForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text('Send us a Message',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            children: [
              TextField(
                controller: _messageController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Describe your issue or question...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: AppTheme.backgroundColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: AppTheme.buttonShadow,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.send, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text('Send Message',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a message'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    _messageController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('Message sent! We\'ll respond soon.'),
          ],
        ),
        backgroundColor: AppTheme.accentGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
