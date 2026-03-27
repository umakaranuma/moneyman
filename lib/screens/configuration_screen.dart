

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:money_man/services/theme_service.dart';
import '../core/router/app_router.dart';
import '../models/account.dart';
import '../services/storage_service.dart';
import 'passcode_lock_screen.dart';
import 'passcode_setup_screen.dart';
import '../theme/app_theme.dart';

class ConfigurationScreen extends StatefulWidget {
  const ConfigurationScreen({super.key});

  @override
  State<ConfigurationScreen> createState() => _ConfigurationScreenState();
}

class _ConfigurationScreenState extends State<ConfigurationScreen> {
  String _mainCurrency = 'LKR (Rs.)';
  bool _subcategoryEnabled = true;
  bool _carryOverEnabled = true;
  bool _passcodeEnabled = false;

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
    _carryOverEnabled = StorageService.getConfigCarryOverEnabled();
    _passcodeEnabled = StorageService.getConfigPasscodeEnabled();
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
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
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
            color: theme.textTheme.titleLarge?.color,
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
              _buildCard(context, [
                _buildSettingItem(
                  context,
                  icon: Icons.account_balance_wallet_rounded,
                  iconColor: AppColors.income,
                  title: 'Income Category Setting',
                  onTap: () => context.goToCategories(isExpense: false),
                ),
                _buildDivider(context),
                _buildSettingItem(
                  context,
                  icon: Icons.shopping_bag_rounded,
                  iconColor: AppColors.expense,
                  title: 'Expenses Category Setting',
                  onTap: () => context.goToCategories(isExpense: true),
                ),
                _buildDivider(context),
                _buildSettingItem(
                  context,
                  icon: Icons.account_tree_rounded,
                  iconColor: Colors.purpleAccent,
                  title: 'Subcategory',
                  trailing: Switch(
                    value: _subcategoryEnabled,
                    activeThumbColor: AppColors.primary,
                    onChanged: (value) async {
                      await StorageService.setConfigSubcategoryEnabled(value);
                      if (!mounted) return;
                      setState(() => _subcategoryEnabled = value);
                    },
                  ),
                ),
                _buildDivider(context),
                _buildSettingItem(
                  context,
                  icon: Icons.pie_chart_rounded,
                  iconColor: Colors.orangeAccent,
                  title: 'Budget Setting',
                  onTap: () => context.goToBudgetSetting(),
                ),
              ]),
              const SizedBox(height: 24),
              _buildSectionTitle('General Configuration'),
              _buildCard(context, [
                _buildSettingItem(
                  context,
                  icon: Icons.currency_exchange_rounded,
                  iconColor: AppColors.primary,
                  title: 'Main Currency',
                  subtitle: _mainCurrency,
                  onTap: _pickMainCurrency,
                ),
                _buildDivider(context),
                _buildSettingItem(
                  context,
                  icon: Icons.palette_rounded,
                  iconColor: Colors.indigoAccent,
                  title: 'Theme',
                  subtitle: ThemeService().isDarkMode ? 'Dark' : 'Light',
                  onTap: () => _pickTheme(context),
                ),
                _buildDivider(context),
                _buildSettingItem(
                  context,
                  icon: Icons.forward_rounded,
                  iconColor: Colors.teal,
                  title: 'Carry-over Setting',
                  trailing: Switch(
                    value: _carryOverEnabled,
                    activeThumbColor: AppColors.primary,
                    onChanged: (value) async {
                      await StorageService.setConfigCarryOverEnabled(value);
                      if (!mounted) return;
                      setState(() => _carryOverEnabled = value);
                    },
                  ),
                ),
              ]),
              const SizedBox(height: 24),
              _buildSectionTitle('Security & Other'),
              _buildCard(context, [
                _buildSettingItem(
                  context,
                  icon: Icons.lock_rounded,
                  iconColor: Colors.blue,
                  title: 'Passcode',
                  subtitle: _passcodeEnabled ? 'Enabled' : 'Disabled',
                  trailing: Switch(
                    value: _passcodeEnabled,
                    activeThumbColor: AppColors.primary,
                    onChanged: (value) async {
                      await _onPasscodeToggle(value);
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
          color: AppColors.navUnselected,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, List<Widget> children) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
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
                        color: theme.textTheme.titleMedium?.color,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null)
                trailing
              else if (onTap != null)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: theme.textTheme.bodySmall?.color,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    final theme = Theme.of(context);
    return Divider(
      height: 1,
      thickness: 1,
      indent: 56,
      endIndent: 16,
      color: theme.dividerColor.withValues(alpha: 0.1),
    );
  }

  Future<void> _pickTheme(BuildContext context) async {
    final theme = Theme.of(context);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.bottomSheetTheme.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Select Theme',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.titleLarge?.color,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(
                  Icons.light_mode_rounded,
                  color: Colors.orange,
                ),
                title: Text('Light', style: GoogleFonts.inter()),
                trailing: !ThemeService().isDarkMode
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.primary,
                      )
                    : null,
                onTap: () {
                  ThemeService().setThemeMode(ThemeMode.light);
                  Navigator.pop(sheetContext);
                  setState(() {});
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.dark_mode_rounded,
                  color: Colors.indigo,
                ),
                title: Text('Dark', style: GoogleFonts.inter()),
                trailing: ThemeService().isDarkMode
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.primary,
                      )
                    : null,
                onTap: () {
                  ThemeService().setThemeMode(ThemeMode.dark);
                  Navigator.pop(sheetContext);
                  setState(() {});
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickMainCurrency() async {
    final theme = Theme.of(context);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.bottomSheetTheme.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
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
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Main Currency Setting',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.titleLarge?.color,
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
                              color: theme.textTheme.bodyLarge?.color,
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
                            if (sheetContext.mounted) {
                              Navigator.pop(sheetContext);
                            }
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

  Future<void> _onPasscodeToggle(bool enable) async {
    if (enable) {
      final pin = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (_) => const PasscodeSetupScreen(),
          fullscreenDialog: false,
        ),
      );
      if (pin == null || pin.length != 4) return;
      await StorageService.setConfigPin(pin);
      await StorageService.setConfigPasscodeEnabled(true);
      if (!mounted) return;
      setState(() => _passcodeEnabled = true);
      _showMessage('Passcode enabled');
      return;
    }

    final currentPin = StorageService.getConfigPin();
    if (currentPin == null || currentPin.length != 4) {
      await StorageService.setConfigPasscodeEnabled(false);
      if (!mounted) return;
      setState(() => _passcodeEnabled = false);
      return;
    }

    final confirmed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PasscodeLockScreen(
          expectedPin: currentPin,
          popOnSuccess: true,
          title: 'Confirm passcode',
          subtitle: 'Enter your current passcode to turn it off',
        ),
        fullscreenDialog: false,
      ),
    );

    if (confirmed == true) {
      await StorageService.setConfigPin(null);
      await StorageService.setConfigPasscodeEnabled(false);
      if (!mounted) return;
      setState(() => _passcodeEnabled = false);
      _showMessage('Passcode disabled');
      return;
    }

    _showMessage('Passcode confirmation required');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: GoogleFonts.inter())),
    );
  }
}
