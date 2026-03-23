import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/router/app_router.dart';
import '../models/account.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class ConfigurationScreen extends StatefulWidget {
  const ConfigurationScreen({super.key});

  @override
  State<ConfigurationScreen> createState() => _ConfigurationScreenState();
}

class _ConfigurationScreenState extends State<ConfigurationScreen> {
  String _mainCurrency = 'LKR (Rs.)';
  bool _subcategoryEnabled = true;
  String _subCurrency = r'$';
  String _startScreen = 'Daily';
  int _monthlyStartDate = 1;
  String _weeklyStartDay = 'Sunday';
  bool _carryOverEnabled = true;
  String _swipeMode = 'To Change Date';
  String _colorSetting = 'Set. A';
  String _timeInput = 'Input Only, Desc.';
  bool _showDescription = false;
  bool _autocomplete = true;
  String _inputOrder = 'From Amount';
  bool _noteButtonEnabled = false;
  bool _passcodeEnabled = false;
  bool _alarmEnabled = true;
  bool _quickAddEnabled = false;
  String _style = 'Dark';
  String _language = 'English';

  @override
  void initState() {
    super.initState();
    _loadConfigurationValues();
  }

  void _loadConfigurationValues() {
    final code = StorageService.getDefaultCurrencyCode()?.toUpperCase();
    _mainCurrency = code != null && code.isNotEmpty
        ? _formatCurrencyLabel(code)
        : _formatCurrencyLabel(CurrencyType.lkr.name.toUpperCase());
    _subcategoryEnabled = StorageService.getConfigSubcategoryEnabled();
    _subCurrency = StorageService.getConfigSubCurrency();
    _startScreen = StorageService.getConfigStartScreen();
    _monthlyStartDate = StorageService.getConfigMonthlyStartDate();
    _weeklyStartDay = StorageService.getConfigWeeklyStartDay();
    _carryOverEnabled = StorageService.getConfigCarryOverEnabled();
    _swipeMode = StorageService.getConfigSwipeMode();
    _colorSetting = StorageService.getConfigColorSetting();
    _timeInput = StorageService.getConfigTimeInput();
    _showDescription = StorageService.getConfigShowDescription();
    _autocomplete = StorageService.getConfigAutocomplete();
    _inputOrder = StorageService.getConfigInputOrder();
    _noteButtonEnabled = StorageService.getConfigNoteButtonEnabled();
    _passcodeEnabled = StorageService.getConfigPasscodeEnabled();
    _alarmEnabled = StorageService.getConfigAlarmEnabled();
    _quickAddEnabled = StorageService.getConfigQuickAddEnabled();
    _style = StorageService.getConfigStyle();
    _language = StorageService.getConfigLanguage();
  }

  String _formatCurrencyLabel(String code) {
    switch (code) {
      case 'LKR':
        return 'LKR (Rs.)';
      case 'USD':
        return 'USD (\$)';
      case 'EUR':
        return 'EUR (€)';
      case 'GBP':
        return 'GBP (£)';
      case 'INR':
        return 'INR (Rs.)';
      case 'JPY':
        return 'JPY (¥)';
      default:
        return code;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Configuration',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Category & Budget'),
              _buildCard([
                _buildSettingItem(
                  icon: Icons.account_balance_wallet_rounded,
                  iconColor: AppColors.income,
                  title: 'Income Category Setting',
                  onTap: () => context.goToCategories(isExpense: false),
                ),
                _buildDivider(),
                _buildSettingItem(
                  icon: Icons.shopping_bag_rounded,
                  iconColor: AppColors.expense,
                  title: 'Expenses Category Setting',
                  onTap: () => context.goToCategories(isExpense: true),
                ),
                _buildDivider(),
                _buildSettingItem(
                  icon: Icons.account_tree_rounded,
                  iconColor: Colors.purpleAccent,
                  title: 'Subcategory',
                  trailing: Switch(
                    value: _subcategoryEnabled,
                    activeColor: AppColors.primary,
                    onChanged: (value) async {
                      await StorageService.setConfigSubcategoryEnabled(value);
                      if (!mounted) return;
                      setState(() => _subcategoryEnabled = value);
                    },
                  ),
                ),
                _buildDivider(),
                _buildSettingItem(
                  icon: Icons.pie_chart_rounded,
                  iconColor: Colors.orangeAccent,
                  title: 'Budget Setting',
                  onTap: () => context.goToBudgetSetting(),
                ),
                _buildDivider(),
                _buildSettingItem(
                  icon: Icons.update_rounded,
                  iconColor: Colors.blueAccent,
                  title: 'Repeat Setting',
                  onTap: () => context.goToReminders(),
                ),
              ]),
              const SizedBox(height: 24),
              _buildSectionTitle('General Configuration'),
              _buildCard([
                _buildSettingItem(
                  icon: Icons.currency_exchange_rounded,
                  iconColor: AppColors.primary,
                  title: 'Main Currency',
                  subtitle: _mainCurrency,
                  onTap: _pickMainCurrency,
                ),
                _buildDivider(),
                _buildSettingItem(
                  icon: Icons.monetization_on_rounded,
                  iconColor: AppColors.secondary,
                  title: 'Sub Currency',
                  subtitle: _subCurrency,
                  onTap: () => _pickStringOption(
                    title: 'Sub Currency',
                    options: ['\$ ', 'Rs.', '€', '£', '¥'],
                    currentValue: _subCurrency,
                    onSelected: (value) async {
                      await StorageService.setConfigSubCurrency(value);
                      if (!mounted) return;
                      setState(() => _subCurrency = value);
                    },
                  ),
                ),
                _buildDivider(),
                _buildSettingItem(
                  icon: Icons.home_rounded,
                  iconColor: Colors.indigoAccent,
                  title: 'Start Screen',
                  subtitle: _startScreen,
                  onTap: () => _pickStringOption(
                    title: 'Start Screen',
                    options: ['Daily', 'Calendar'],
                    currentValue: _startScreen,
                    onSelected: (value) async {
                      await StorageService.setConfigStartScreen(value);
                      if (!mounted) return;
                      setState(() => _startScreen = value);
                    },
                  ),
                ),
                _buildDivider(),
                _buildSettingItem(
                  icon: Icons.calendar_today_rounded,
                  iconColor: Colors.tealAccent,
                  title: 'Monthly Start Date',
                  subtitle: 'Every $_monthlyStartDate',
                  onTap: () => _pickStringOption(
                    title: 'Monthly Start Date',
                    options: List<String>.generate(
                      28,
                      (index) => 'Every ${index + 1}',
                    ),
                    currentValue: 'Every $_monthlyStartDate',
                    onSelected: (value) async {
                      final day =
                          int.tryParse(value.replaceAll('Every ', '')) ?? 1;
                      await StorageService.setConfigMonthlyStartDate(day);
                      if (!mounted) return;
                      setState(() => _monthlyStartDate = day);
                    },
                  ),
                ),
                _buildDivider(),
                _buildSettingItem(
                  icon: Icons.date_range_rounded,
                  iconColor: Colors.brown,
                  title: 'Weekly Start Day',
                  subtitle: _weeklyStartDay,
                  onTap: () => _pickStringOption(
                    title: 'Weekly Start Day',
                    options: [
                      'Sunday',
                      'Monday',
                      'Tuesday',
                      'Wednesday',
                      'Thursday',
                      'Friday',
                      'Saturday',
                    ],
                    currentValue: _weeklyStartDay,
                    onSelected: (value) async {
                      await StorageService.setConfigWeeklyStartDay(value);
                      if (!mounted) return;
                      setState(() => _weeklyStartDay = value);
                    },
                  ),
                ),
                _buildDivider(),
                _buildSettingItem(
                  icon: Icons.forward_rounded,
                  iconColor: Colors.lightGreen,
                  title: 'Carry-over Setting',
                  trailing: Switch(
                    value: _carryOverEnabled,
                    activeColor: AppColors.primary,
                    onChanged: (value) async {
                      await StorageService.setConfigCarryOverEnabled(value);
                      if (!mounted) return;
                      setState(() => _carryOverEnabled = value);
                    },
                  ),
                ),
              ]),
              const SizedBox(height: 24),
              _buildSectionTitle('Input & Display'),
              _buildCard([
                _buildSettingItem(
                  icon: Icons.swipe_rounded,
                  iconColor: Colors.deepPurple,
                  title: 'Swipe Mode',
                  subtitle: _swipeMode,
                  onTap: () => _pickStringOption(
                    title: 'Swipe',
                    options: ['To Change Date', 'Disabled'],
                    currentValue: _swipeMode,
                    onSelected: (value) async {
                      await StorageService.setConfigSwipeMode(value);
                      if (!mounted) return;
                      setState(() => _swipeMode = value);
                    },
                  ),
                ),
                _buildDivider(),
                _buildSettingItem(
                  icon: Icons.palette_rounded,
                  iconColor: Colors.pinkAccent,
                  title: 'Income-Expenses Color',
                  subtitle: _colorSetting,
                  onTap: () => _pickStringOption(
                    title: 'Color Setting',
                    options: const ['Set. A', 'Set. B', 'Set. C'],
                    currentValue: _colorSetting,
                    onSelected: (value) async {
                      await StorageService.setConfigColorSetting(value);
                      if (!mounted) return;
                      setState(() => _colorSetting = value);
                    },
                  ),
                ),
                _buildDivider(),
                _buildSettingItem(
                  icon: Icons.access_time_rounded,
                  iconColor: Colors.amber,
                  title: 'Time Input Method',
                  subtitle: _timeInput,
                  onTap: () => _pickStringOption(
                    title: 'Time Input',
                    options: ['Input Only, Desc.', 'Input + Time', 'No Time'],
                    currentValue: _timeInput,
                    onSelected: (value) async {
                      await StorageService.setConfigTimeInput(value);
                      if (!mounted) return;
                      setState(() => _timeInput = value);
                    },
                  ),
                ),
                _buildDivider(),
                _buildSettingItem(
                  icon: Icons.description_rounded,
                  iconColor: Colors.blueGrey,
                  title: 'Show Description',
                  trailing: Switch(
                    value: _showDescription,
                    activeColor: AppColors.primary,
                    onChanged: (value) async {
                      await StorageService.setConfigShowDescription(value);
                      if (!mounted) return;
                      setState(() => _showDescription = value);
                    },
                  ),
                ),
                _buildDivider(),
                _buildSettingItem(
                  icon: Icons.auto_awesome_rounded,
                  iconColor: Colors.yellow,
                  title: 'Autocomplete',
                  trailing: Switch(
                    value: _autocomplete,
                    activeColor: AppColors.primary,
                    onChanged: (value) async {
                      await StorageService.setConfigAutocomplete(value);
                      if (!mounted) return;
                      setState(() => _autocomplete = value);
                    },
                  ),
                ),
                _buildDivider(),
                _buildSettingItem(
                  icon: Icons.sort_rounded,
                  iconColor: Colors.cyan,
                  title: 'Input Order',
                  subtitle: _inputOrder,
                  onTap: () => _pickStringOption(
                    title: 'Input Order',
                    options: const ['From Amount', 'From Category'],
                    currentValue: _inputOrder,
                    onSelected: (value) async {
                      await StorageService.setConfigInputOrder(value);
                      if (!mounted) return;
                      setState(() => _inputOrder = value);
                    },
                  ),
                ),
                _buildDivider(),
                _buildSettingItem(
                  icon: Icons.note_add_rounded,
                  iconColor: Colors.lime,
                  title: 'Note Button',
                  trailing: Switch(
                    value: _noteButtonEnabled,
                    activeColor: AppColors.primary,
                    onChanged: (value) async {
                      await StorageService.setConfigNoteButtonEnabled(value);
                      if (!mounted) return;
                      setState(() => _noteButtonEnabled = value);
                    },
                  ),
                ),
              ]),
              const SizedBox(height: 24),
              _buildSectionTitle('Security & Other'),
              _buildCard([
                _buildSettingItem(
                  icon: Icons.lock_rounded,
                  iconColor: Colors.redAccent,
                  title: 'Passcode',
                  trailing: Switch(
                    value: _passcodeEnabled,
                    activeColor: AppColors.primary,
                    onChanged: (value) async {
                      await StorageService.setConfigPasscodeEnabled(value);
                      if (!mounted) return;
                      setState(() => _passcodeEnabled = value);
                    },
                  ),
                ),
                _buildDivider(),
                _buildSettingItem(
                  icon: Icons.alarm_rounded,
                  iconColor: Colors.orange,
                  title: 'Alarm Setting',
                  trailing: Switch(
                    value: _alarmEnabled,
                    activeColor: AppColors.primary,
                    onChanged: (value) async {
                      await StorageService.setConfigAlarmEnabled(value);
                      if (!mounted) return;
                      setState(() => _alarmEnabled = value);
                    },
                  ),
                ),
                _buildDivider(),
                _buildSettingItem(
                  icon: Icons.add_circle_rounded,
                  iconColor: Colors.greenAccent,
                  title: 'Quick Add',
                  trailing: Switch(
                    value: _quickAddEnabled,
                    activeColor: AppColors.primary,
                    onChanged: (value) async {
                      await StorageService.setConfigQuickAddEnabled(value);
                      if (!mounted) return;
                      setState(() => _quickAddEnabled = value);
                    },
                  ),
                ),
                _buildDivider(),
                _buildSettingItem(
                  icon: Icons.style_rounded,
                  iconColor: Colors.purple,
                  title: 'App Style',
                  subtitle: _style,
                  onTap: () => _pickStringOption(
                    title: 'Style',
                    options: ['Dark', 'Light'],
                    currentValue: _style,
                    onSelected: (value) async {
                      await StorageService.setConfigStyle(value);
                      if (!mounted) return;
                      setState(() => _style = value);
                    },
                  ),
                ),
                _buildDivider(),
                _buildSettingItem(
                  icon: Icons.language_rounded,
                  iconColor: Colors.blue,
                  title: 'Language',
                  subtitle: _language,
                  onTap: () => _pickStringOption(
                    title: 'Language',
                    options: ['English', 'Sinhala', 'Tamil'],
                    currentValue: _language,
                    onSelected: (value) async {
                      await StorageService.setConfigLanguage(value);
                      if (!mounted) return;
                      setState(() => _language = value);
                    },
                  ),
                ),
              ]),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.surfaceVariant.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null)
                trailing
              else if (onTap != null)
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppColors.textMuted,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 56,
      endIndent: 16,
      color: AppColors.surfaceVariant.withOpacity(0.5),
    );
  }

  Future<void> _pickMainCurrency() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Main Currency Setting',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: CurrencyType.values
                      .map(
                        (currency) => ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 24,
                          ),
                          title: Text(
                            currency.displayLabel,
                            style: GoogleFonts.inter(
                              color: AppColors.textPrimary,
                              fontWeight: _mainCurrency == currency.displayLabel
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                          trailing: _mainCurrency == currency.displayLabel
                              ? const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.primary,
                                )
                              : null,
                          onTap: () async {
                            await StorageService.setDefaultCurrencyCode(
                              currency.name,
                            );
                            if (!mounted) return;
                            setState(
                              () => _mainCurrency = currency.displayLabel,
                            );
                            if (sheetContext.mounted)
                              Navigator.pop(sheetContext);
                          },
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickStringOption({
    required String title,
    required List<String> options,
    required String currentValue,
    required Future<void> Function(String value) onSelected,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: options
                      .map(
                        (option) => ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 24,
                          ),
                          title: Text(
                            option,
                            style: GoogleFonts.inter(
                              color: AppColors.textPrimary,
                              fontWeight: option == currentValue
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                          trailing: option == currentValue
                              ? const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.primary,
                                )
                              : null,
                          onTap: () async {
                            await onSelected(option);
                            if (sheetContext.mounted)
                              Navigator.pop(sheetContext);
                          },
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
