import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../contacts/contacts.dart';
import '../theme.dart';
import 'widgets.dart';

Future<void> dial(BuildContext context, String number) async {
  final ok = await launchUrl(Uri(scheme: 'tel', path: number));
  if (!ok && context.mounted) {
    showToast(context, 'Não foi possível abrir o telefone');
  }
}

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  late final Future<List<Contact>> _contacts = loadContacts();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contactos úteis')),
      body: FutureBuilder(
        future: _contacts,
        builder: (context, snapshot) {
          final all = snapshot.data ?? const <Contact>[];
          final shown = _query.isEmpty
              ? all
              : all.where((c) => c.matches(_query)).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              SearchBar(
                hintText: 'Procurar nome, assunto ou número',
                leading: const Icon(Icons.search),
                elevation: const WidgetStatePropertyAll(0),
                onChanged: (q) => setState(() => _query = q),
              ),
              const SizedBox(height: 12),
              if (_query.isEmpty) const _EmergencyCard(),
              const SizedBox(height: 4),
              if (snapshot.hasData && shown.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text('Sem resultados')),
                ),
              for (final c in shown) _ContactTile(contact: c),
            ],
          );
        },
      ),
    );
  }
}

class _EmergencyCard extends StatelessWidget {
  const _EmergencyCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Palette.red,
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
        title: const Text(
          'Emergência',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        subtitle: const Text(
          '112',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        trailing: IconButton.filled(
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Palette.red,
          ),
          iconSize: 28,
          onPressed: () => dial(context, '112'),
          icon: const Icon(Icons.call),
          tooltip: 'Ligar 112',
        ),
      ),
    );
  }
}

class _ContactTile extends StatefulWidget {
  const _ContactTile({required this.contact});

  final Contact contact;

  @override
  State<_ContactTile> createState() => _ContactTileState();
}

class _ContactTileState extends State<_ContactTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.contact;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Card(
        child: InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        c.formattedNumber,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 150),
                        alignment: Alignment.topCenter,
                        child: Text(
                          c.description,
                          maxLines: _expanded ? null : 2,
                          overflow: _expanded ? null : TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  iconSize: 26,
                  onPressed: () => dial(context, c.number),
                  icon: const Icon(Icons.call),
                  tooltip: 'Ligar ${c.title}',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
