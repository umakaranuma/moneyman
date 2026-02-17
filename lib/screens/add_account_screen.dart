import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/account.dart';
import '../services/account_service.dart';

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
  CurrencyType _selectedCurrency = CurrencyType.inr;

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

  void _showAccountGroupModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Account Group',
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 20),
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
                      horizontal: 20,
                      vertical: 8,
                    ),
                    title: Text(
                      account.categoryLabel,
                      style: GoogleFonts.inter(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(
                            Icons.check_rounded,
                            color: AppColors.primary,
                            size: 24,
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.account != null ? 'Edit Account' : 'Add Account',
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Group Field
                _buildLabel('Group'),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _showAccountGroupModal,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.surfaceVariant,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            account.categoryLabel,
                            style: GoogleFonts.inter(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_drop_down_rounded,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Name Field
                _buildLabel('Name'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter account name',
                    hintStyle: GoogleFonts.inter(
                      color: AppColors.textMuted,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter account name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Amount Field
                _buildLabel('Amount'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _amountController,
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    hintStyle: GoogleFonts.inter(
                      color: AppColors.textMuted,
                    ),
                    prefixText: account.currencySymbol + ' ',
                    prefixStyle: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                    ),
                  ),
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
                ),
                const SizedBox(height: 24),

                // Currency Field
                _buildLabel('Currency'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildCurrencyButton(
                        'Rs.',
                        CurrencyType.inr,
                        Icons.currency_rupee_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildCurrencyButton(
                        '\$',
                        CurrencyType.usd,
                        Icons.attach_money_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.surfaceVariant,
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.add_rounded,
                        color: AppColors.textSecondary,
                        size: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Description Field
                _buildLabel('Description'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                  ),
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Enter description (optional)',
                    hintStyle: GoogleFonts.inter(
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Save Button
                ElevatedButton(
                  onPressed: _saveAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Save',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.inter(
        color: AppColors.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildCurrencyButton(
    String symbol,
    CurrencyType currency,
    IconData icon,
  ) {
    final isSelected = _selectedCurrency == currency;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCurrency = currency;
        });
      },
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primaryLight,
                  ],
                )
              : null,
          color: isSelected ? null : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.surfaceVariant,
            width: 1,
          ),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 4),
              Text(
                symbol,
                style: GoogleFonts.inter(
                  color: isSelected
                      ? Colors.white
                      : AppColors.textSecondary,
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

