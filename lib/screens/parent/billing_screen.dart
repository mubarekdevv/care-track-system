import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/parent_demo_data.dart';
import '../../core/theme/app_theme.dart';
import '../../models/parent_insights.dart';
import '../../providers/child_provider.dart';
import '../../widgets/auth/auth_primary_button.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  List<InvoiceItem>? _invoices;

  List<InvoiceItem> get invoices {
    _invoices ??= ParentDemoData.invoicesFor(
      Provider.of<ChildProvider>(context, listen: false).children,
    );
    return _invoices!;
  }

  double get _dueTotal => invoices
      .where((i) => !i.isPaid)
      .fold(0, (sum, i) => sum + i.amount);

  void _payInvoice(InvoiceItem invoice) {
    setState(() {
      final index = invoices.indexWhere((i) => i.id == invoice.id);
      if (index != -1) {
        invoices[index] = InvoiceItem(
          id: invoice.id,
          title: invoice.title,
          childName: invoice.childName,
          amount: invoice.amount,
          dueDate: invoice.dueDate,
          isPaid: true,
        );
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment of ${invoice.amountDisplay} for ${invoice.title} confirmed.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.softGreen,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFmt = DateFormat('MMM d, yyyy');
    final pending = invoices.where((i) => !i.isPaid).toList();
    final paid = invoices.where((i) => i.isPaid).toList();

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.warmNeutral,
      appBar: AppBar(
        title: const Text('Billing & Payments', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        physics: const BouncingScrollPhysics(),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE2894A), Color(0xFFBD7135)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total Due', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 6),
                Text(
                  '\$${_dueTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${pending.length} open invoice${pending.length == 1 ? '' : 's'}',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Outstanding', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          if (pending.isEmpty)
            Text(
              'All caught up — no pending payments.',
              style: TextStyle(color: isDark ? Colors.grey[400] : AppTheme.textSecondary),
            )
          else
            ...pending.map((invoice) => _InvoiceCard(
                  invoice: invoice,
                  isDark: isDark,
                  dateFmt: dateFmt,
                  onPay: () => _payInvoice(invoice),
                )),
          const SizedBox(height: 20),
          const Text('Payment History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          ...paid.map(
            (invoice) => _InvoiceCard(
              invoice: invoice,
              isDark: isDark,
              dateFmt: dateFmt,
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final InvoiceItem invoice;
  final bool isDark;
  final DateFormat dateFmt;
  final VoidCallback? onPay;

  const _InvoiceCard({
    required this.invoice,
    required this.isDark,
    required this.dateFmt,
    this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.grey.shade800 : AppTheme.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invoice.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${invoice.childName} • #${invoice.id}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey[400] : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                invoice.amountDisplay,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                invoice.isPaid
                    ? 'Paid ${dateFmt.format(invoice.dueDate)}'
                    : 'Due ${dateFmt.format(invoice.dueDate)}',
                style: TextStyle(
                  fontSize: 12,
                  color: invoice.isPaid
                      ? AppTheme.softGreen
                      : (isDark ? Colors.grey[400] : AppTheme.textSecondary),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (invoice.isPaid ? AppTheme.softGreen : Colors.orange).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  invoice.isPaid ? 'Paid' : 'Pending',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: invoice.isPaid ? AppTheme.softGreen : Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          if (!invoice.isPaid && onPay != null) ...[
            const SizedBox(height: 14),
            AuthPrimaryButton(
              label: 'Pay Now',
              backgroundColor: const Color(0xFFE2894A),
              icon: Icons.lock_rounded,
              onPressed: onPay,
            ),
          ],
        ],
      ),
    );
  }
}
