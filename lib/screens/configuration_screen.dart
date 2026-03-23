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
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Configuration',
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: ListView(
        children: [
          _buildSectionHeader('Category/Repeat'),
          _buildItem(
            title: 'Income Category Setting',
            onTap: () => context.goToCategories(isExpense: false),
          ),
          _buildItem(
            title: 'Expenses Category Setting',
            onTap: () => context.goToCategories(isExpense: true),
          ),
          _buildItem(
            title: 'Subcategory',
            value: _onOff(_subcategoryEnabled),
            onTap: () async {
              final value = !_subcategoryEnabled;
              await StorageService.setConfigSubcategoryEnabled(value);
              if (!mounted) return;
              setState(() => _subcategoryEnabled = value);
            },
          ),
          _buildItem(
            title: 'Budget Setting',
            onTap: () => context.goToBudgetSetting(),
          ),
          _buildItem(title: 'Repeat Setting', onTap: () => context.goToReminders()),
          const SizedBox(height: 10),
          _buildSectionHeader('Configuration'),
          _buildItem(
            title: 'Main Currency Setting',
            value: _mainCurrency,
            onTap: _pickMainCurrency,
          ),
          _buildItem(
            title: 'Sub Currency Setting',
            value: _subCurrency,
            onTap: () => _pickStringOption(
              title: 'Sub Currency',
              options: const ['\$', 'Rs.', '€', '£', '¥'],
              currentValue: _subCurrency,
              onSelected: (value) async {
                await StorageService.setConfigSubCurrency(value);
                if (!mounted) return;
                setState(() => _subCurrency = value);
              },
            ),
          ),
          _buildItem(
            title: 'Start Screen (Daily/Calendar)',
            value: _startScreen,
            onTap: () => _pickStringOption(
              title: 'Start Screen',
              options: const ['Daily', 'Calendar'],
              currentValue: _startScreen,
              onSelected: (value) async {
                await StorageService.setConfigStartScreen(value);
                if (!mounted) return;
                setState(() => _startScreen = value);
              },
            ),
          ),
          _buildItem(
            title: 'Monthly Start Date',
            value: 'Every $_monthlyStartDate',
            onTap: () => _pickStringOption(
              title: 'Monthly Start Date',
              options: List<String>.generate(28, (index) => 'Every ${index + 1}'),
              currentValue: 'Every $_monthlyStartDate',
              onSelected: (value) async {
                final day = int.tryParse(value.replaceAll('Every ', '')) ?? 1;
                await StorageService.setConfigMonthlyStartDate(day);
                if (!mounted) return;
                setState(() => _monthlyStartDate = day);
              },
            ),
          ),
          _buildItem(
            title: 'Weekly Start Day',
            value: _weeklyStartDay,
            onTap: () => _pickStringOption(
              title: 'Weekly Start Day',
              options: const [
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
          _buildItem(
            title: 'Carry-over Setting',
            value: _onOff(_carryOverEnabled),
            onTap: () async {
              final value = !_carryOverEnabled;
              await StorageService.setConfigCarryOverEnabled(value);
              if (!mounted) return;
              setState(() => _carryOverEnabled = value);
            },
          ),
          _buildItem(
            title: 'Swipe',
            value: _swipeMode,
            onTap: () => _pickStringOption(
              title: 'Swipe',
              options: const ['To Change Date', 'Disabled'],
              currentValue: _swipeMode,
              onSelected: (value) async {
                await StorageService.setConfigSwipeMode(value);
                if (!mounted) return;
                setState(() => _swipeMode = value);
              },
            ),
          ),
          _buildItem(
            title: 'Income-Expenses Color Setting',
            value: _colorSetting,
            onTap: () => _pickStringOption(
              title: 'Income-Expenses Color Setting',
              options: const ['Set. A', 'Set. B', 'Set. C'],
              currentValue: _colorSetting,
              onSelected: (value) async {
                await StorageService.setConfigColorSetting(value);
                if (!mounted) return;
                setState(() => _colorSetting = value);
              },
            ),
          ),
          _buildItem(
            title: 'Time Input',
            value: _timeInput,
            onTap: () => _pickStringOption(
              title: 'Time Input',
              options: const ['Input Only, Desc.', 'Input + Time', 'No Time'],
              currentValue: _timeInput,
              onSelected: (value) async {
                await StorageService.setConfigTimeInput(value);
                if (!mounted) return;
                setState(() => _timeInput = value);
              },
            ),
          ),
          _buildItem(
            title: 'Show description',
            value: _onOff(_showDescription),
            onTap: () async {
              final value = !_showDescription;
              await StorageService.setConfigShowDescription(value);
              if (!mounted) return;
              setState(() => _showDescription = value);
            },
          ),
          _buildItem(
            title: 'Autocomplete',
            value: _onOff(_autocomplete),
            onTap: () async {
              final value = !_autocomplete;
              await StorageService.setConfigAutocomplete(value);
              if (!mounted) return;
              setState(() => _autocomplete = value);
            },
          ),
          _buildItem(
            title: 'Input order',
            value: _inputOrder,
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
          _buildItem(
            title: 'Note button setting',
            value: _onOff(_noteButtonEnabled),
            onTap: () async {
              final value = !_noteButtonEnabled;
              await StorageService.setConfigNoteButtonEnabled(value);
              if (!mounted) return;
              setState(() => _noteButtonEnabled = value);
            },
          ),
          const SizedBox(height: 10),
          _buildSectionHeader('Other'),
          _buildItem(
            title: 'Passcode',
            value: _onOff(_passcodeEnabled),
            onTap: () async {
              final value = !_passcodeEnabled;
              await StorageService.setConfigPasscodeEnabled(value);
              if (!mounted) return;
              setState(() => _passcodeEnabled = value);
            },
          ),
          _buildItem(
            title: 'Alarm Setting',
            value: _onOff(_alarmEnabled),
            onTap: () async {
              final value = !_alarmEnabled;
              await StorageService.setConfigAlarmEnabled(value);
              if (!mounted) return;
              setState(() => _alarmEnabled = value);
            },
          ),
          _buildItem(
            title: 'Quick add',
            value: _onOff(_quickAddEnabled),
            onTap: () async {
              final value = !_quickAddEnabled;
              await StorageService.setConfigQuickAddEnabled(value);
              if (!mounted) return;
              setState(() => _quickAddEnabled = value);
            },
          ),
          _buildItem(
            title: 'Style',
            value: _style,
            onTap: () => _pickStringOption(
              title: 'Style',
              options: const ['Dark', 'Light'],
              currentValue: _style,
              onSelected: (value) async {
                await StorageService.setConfigStyle(value);
                if (!mounted) return;
                setState(() => _style = value);
              },
            ),
          ),
          _buildItem(
            title: 'Language Setting',
            value: _language,
            onTap: () => _pickStringOption(
              title: 'Language',
              options: const ['English', 'Sinhala', 'Tamil'],
              currentValue: _language,
              onSelected: (value) async {
                await StorageService.setConfigLanguage(value);
                if (!mounted) return;
                setState(() => _language = value);
              },
            ),
          ),
          SizedBox(height: 16 + MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.surface,
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildItem({
    required String title,
    String? value,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.surfaceVariant, width: 0.6),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            if (value != null && value.isNotEmpty)
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: AppColors.primaryLight,
                  fontWeight: FontWeight.w400,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _onOff(bool value) => value ? 'ON' : 'OFF';

  Future<void> _pickMainCurrency() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: CurrencyType.values
                .map(
                  (currency) => ListTile(
                    title: Text(
                      currency.displayLabel,
                      style: GoogleFonts.inter(color: AppColors.textPrimary),
                    ),
                    trailing: _mainCurrency == currency.displayLabel
                        ? const Icon(Icons.check_rounded, color: AppColors.primary)
                        : null,
                    onTap: () async {
                      await StorageService.setDefaultCurrencyCode(currency.name);
                      if (!mounted) return;
                      setState(() => _mainCurrency = currency.displayLabel);
                      if (sheetContext.mounted) Navigator.pop(sheetContext);
                    },
                  ),
                )
                .toList(),
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
              const SizedBox(height: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              ...options.map(
                (option) => ListTile(
                  title: Text(
                    option,
                    style: GoogleFonts.inter(color: AppColors.textPrimary),
                  ),
                  trailing: option == currentValue
                      ? const Icon(Icons.check_rounded, color: AppColors.primary)
                      : null,
                  onTap: () async {
                    await onSelected(option);
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
