import 'package:flutter/material.dart';

import '../app.dart';
import '../patient/chamu.dart';
import '../patient/patient.dart';
import '../theme.dart';
import 'widgets.dart';

/// The history taken in the secondary survey, as on the national form:
/// Circunstâncias, História, Alergias, Medicação habitual, Última refeição.
class ChamuPage extends StatelessWidget {
  const ChamuPage({super.key});

  @override
  Widget build(BuildContext context) {
    final patient = AppScope.of(context).patient;
    return ListenableBuilder(
      listenable: patient,
      builder: (context, _) {
        final chamu = patient.chamu;
        return Scaffold(
          appBar: AppBar(
            title: const Text('CHAMU'),
            actions: [
              IconButton(
                tooltip: 'Limpar CHAMU',
                icon: const Icon(Icons.restart_alt),
                onPressed: chamu.isEmpty
                    ? null
                    : () async {
                        if (await confirm(
                          context,
                          title: 'Limpar CHAMU?',
                          message: 'Apaga tudo o que foi registado aqui.',
                        )) {
                          patient.chamu = const Chamu();
                        }
                      },
              ),
            ],
          ),
          body: ListView(
            padding: listPadding,
            children: [
              const NoteCard(
                icon: Icons.privacy_tip_outlined,
                text: TextSpan(
                  text:
                      'Não escreva dados de identificação (nome, morada, '
                      'n.º de utente).',
                ),
              ),
              for (final q in chamuQuestions)
                _Question(question: q, patient: patient),
              ItemHeader(
                title: 'U · Última refeição',
                trailing: chamu.mealAnswered ? ItemHeader.done(context) : null,
              ),
              TimeStampTile(
                label: 'Hora da última refeição',
                at: chamu.lastMeal,
                onChanged: (at) => patient.chamu = chamu.withLastMeal(at),
              ),
              _NoteField(
                key: const ValueKey(chamuMealNote),
                value: chamu.note(chamuMealNote),
                hint: 'O que comeu ou bebeu',
                onChanged: (t) =>
                    patient.chamu = patient.chamu.withNote(chamuMealNote, t),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Question extends StatelessWidget {
  const _Question({required this.question, required this.patient});

  final ChamuQuestion question;
  final PatientStore patient;

  @override
  Widget build(BuildContext context) {
    final q = question;
    final chamu = patient.chamu;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ItemHeader(
          title: '${q.letter} · ${q.title}',
          trailing: chamu.answered(q) ? ItemHeader.done(context) : null,
        ),
        if (!q.textOnly)
          ChoiceField(
            title: q.title,
            hint: 'Escolher',
            multi: !q.single,
            options: [for (final o in q.options) (o.id, o.label)],
            listenable: patient,
            selected: () => patient.chamu.picked(q),
            onToggle: (id) => patient.chamu = patient.chamu.toggle(q, id),
          ),
        // Opens for "Outra" and the like; always for the medication.
        if (chamu.showsNote(q))
          _NoteField(
            // Keeps the text while the page rebuilds.
            key: ValueKey(q.id),
            value: chamu.note(q.id),
            hint: q.textHint,
            lines: 3,
            onChanged: (t) => patient.chamu = patient.chamu.withNote(q.id, t),
          ),
      ],
    );
  }
}

/// A short free-text line under a question, saved as it is typed.
class _NoteField extends StatefulWidget {
  const _NoteField({
    super.key,
    required this.value,
    required this.hint,
    required this.onChanged,
    this.lines = 1,
  });

  final String value;
  final String hint;
  final ValueChanged<String> onChanged;

  /// Visible lines: more than one makes it a text area.
  final int lines;

  @override
  State<_NoteField> createState() => _NoteFieldState();
}

class _NoteFieldState extends State<_NoteField> {
  late final _controller = TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(_NoteField old) {
    super.didUpdateWidget(old);
    // Cleared from outside (the reset button).
    if (widget.value.isEmpty && _controller.text.trim().isNotEmpty) {
      _controller.clear();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: TextField(
        controller: _controller,
        minLines: widget.lines,
        maxLines: widget.lines == 1 ? 1 : widget.lines + 2,
        maxLength: 300,
        keyboardType: widget.lines == 1
            ? TextInputType.text
            : TextInputType.multiline,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: widget.lines == 1
            ? TextInputAction.done
            : TextInputAction.newline,
        decoration: InputDecoration(
          hintText: widget.hint,
          counterText: '',
          filled: true,
          fillColor: Theme.of(context).colorScheme.tile,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.tileBorder,
            ),
          ),
        ),
        onChanged: widget.onChanged,
      ),
    );
  }
}
