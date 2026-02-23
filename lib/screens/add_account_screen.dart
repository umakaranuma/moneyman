import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/account.dart';
import '../services/account_service.dart';
import '../services/storage_service.dart';

class AddAccountScreen extends StatefulWidget {
  final Account? account; // For editing existing account

  const AddAccountScreen({super.key, this.account});

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  AccountCategory _selectedCategory = AccountCategory.cash;
  CurrencyType _selectedCurrency = CurrencyType.lkr;

  @override
  void initState() {
    super.initState();
    if (widget.account != null) {
      // Editing existing account
      _nameController.text = widget.account!.name;
      _amountController.text = widget.account!.balance.toStringAsFixed(2);
      _descriptionController.text = widget.account!.description ?? '';
      _selectedCategory = widget.account!.category;
      _selectedCurrency = widget.account!.currency;
    } else {
      _amountController.text = '0.00';
      // Use default currency from settings for new accounts
      final code = StorageService.getDefaultCurrencyCode();
      if (code != null) {
        _selectedCurrency = CurrencyType.values.firstWhere(
          (e) => e.name == code,
          orElse: () => CurrencyType.lkr,
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveAccount() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final name = _nameController.text.trim();
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final description = _descriptionController.text.trim().isEmpty
        ? null
        : _descriptionController.text.trim();

    final account = Account(
      id: widget.account?.id ??
          '${_selectedCategory.name}_${_selectedCurrency.name}_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      category: _selectedCategory,
      currency: _selectedCurrency,
      balance: amount,
      description: description,
      balancePayable: _selectedCategory == AccountCategory.card ? 0.0 : null,
      outstandingBalance: _selectedCategory == AccountCategory.card ? 0.0 : null,
      createdAt: widget.account?.createdAt ?? DateTime.now(),
    );

    if (widget.account != null) {
      await AccountService.updateAccount(account);
    } else {
      await AccountService.addAccount(account);
    }

    if (mounted) {
      Navigator.pop(context, true); // Return true to indicate success
    }
  }

  void _showCurrencyModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 3,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Currency',
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: CurrencyType.values.length,
                separatorBuilder: (context, index) => Divider(
                  color: AppColors.surfaceVariant,
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  final currency = CurrencyType.values[index];
                  final isSelected = _selectedCurrency == currency;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    dense: true,
                    title: Text(
                      currency.displayLabel,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(
                            Icons.check_rounded,
                            color: AppColors.textSecondary,
                            size: 20,
                          )
                        : null,
                    onTap: () {
                      setState(() => _selectedCurrency = currency);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAccountGroupModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 3,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Account Group',
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: AccountCategory.values.length,
                separatorBuilder: (context, index) => Divider(
                  color: AppColors.surfaceVariant,
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  final category = AccountCategory.values[index];
                  final account = Account(
                    id: 'temp',
                    name: '',
                    category: category,
                  );
                  final isSelected = _selectedCategory == category;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    dense: true,
                    title: Text(
                      account.categoryLabel,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(
                            Icons.check_rounded,
                            color: AppColors.textSecondary,
                            size: 20,
                          )
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedCategory = category;
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final account = Account(
      id: 'temp',
      name: '',
      category: _selectedCategory,
      currency: _selectedCurrency,
    );

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
          widget.account != null ? 'Edit Account' : 'New Account',
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                /// SECTION 1 — BASIC INFO
                _buildSection(
                  children: [
                    _buildSelectorRow(
                      title: 'Group',
                      value: account.categoryLabel,
                      onTap: _showAccountGroupModal,
                    ),
                    _buildDivider(),
                    _buildTextFieldRow(
                      label: 'Name',
                      controller: _nameController,
                      hint: 'Account name',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter account name';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                /// SECTION 2 — FINANCIAL
                _buildSection(
                  children: [
                    _buildAmountField(account),
                    _buildDivider(),
                    _buildSelectorRow(
                      title: 'Currency',
                      value: _selectedCurrency.displayLabel,
                      onTap: _showCurrencyModal,
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                /// SECTION 3 — OPTIONAL
                _buildSection(
                  children: [
                    _buildTextFieldRow(
                      label: 'Description',
                      controller: _descriptionController,
                      hint: 'Optional note',
                      maxLines: 2,
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                _buildAppleSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
    );
  }

  Widget _buildSelectorRow({
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFieldRow({
    required String label,
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: validator,
        style: GoogleFonts.inter(
          fontSize: 15,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.textMuted,
          ),
          hintText: hint,
          hintStyle: GoogleFonts.inter(
            fontSize: 15,
            color: AppColors.textMuted,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildAmountField(Account account) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: TextFormField(
        controller: _amountController,
        keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter amount';
          }
          final amount = double.tryParse(value);
          if (amount == null) {
            return 'Please enter a valid amount';
          }
          return null;
        },
        style: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          labelText: 'Amount',
          labelStyle: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.textMuted,
          ),
          prefixText: account.currencySymbol + ' ',
          prefixStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildAppleSaveButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: _saveAccount,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: Text(
          'Save',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
