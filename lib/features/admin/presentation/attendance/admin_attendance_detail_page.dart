import 'package:flutter/material.dart';
import '../../data/models/rsvp.dart';
import '../../data/repositories/attendance_repository.dart';
import '../shell/admin_session_controller.dart';
import '../widgets/admin_page_header.dart';
import '../widgets/admin_state_widgets.dart';

class AdminAttendanceDetailPage extends StatefulWidget {
  final String rsvpId;
  const AdminAttendanceDetailPage({super.key, required this.rsvpId});

  @override
  State<AdminAttendanceDetailPage> createState() =>
      _AdminAttendanceDetailPageState();
}

class _AdminAttendanceDetailPageState extends State<AdminAttendanceDetailPage> {
  late final AttendanceRepository _repository;
  late Future<Rsvp> _rsvp;

  @override
  void initState() {
    super.initState();
    _repository = AttendanceRepository(AdminSessionController.instance.api);
    _load();
  }

  void _load() => setState(() => _rsvp = _repository.get(widget.rsvpId));

  Future<void> _edit(Rsvp rsvp) async {
    final formKey = GlobalKey<FormState>();
    final adults = TextEditingController(text: rsvp.qtdAdultos.toString());
    final children = TextEditingController(text: rsvp.qtdCriancas.toString());
    final notes = TextEditingController(text: rsvp.observacoes ?? '');
    final reason = TextEditingController();
    var attending = rsvp.vaiComparecer;
    var saving = false;
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, update) => AlertDialog(
            title: Text('Editar presença de ${rsvp.nome}'),
            content: SizedBox(
              width: 440,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SwitchListTile(
                          title: const Text('Vai comparecer'),
                          value: attending,
                          onChanged: (value) =>
                              update(() => attending = value)),
                      TextFormField(
                          controller: adults,
                          keyboardType: TextInputType.number,
                          decoration:
                              const InputDecoration(labelText: 'Adultos'),
                          validator: (v) => int.tryParse(v ?? '') == null
                              ? 'Informe um número'
                              : null),
                      TextFormField(
                          controller: children,
                          keyboardType: TextInputType.number,
                          decoration:
                              const InputDecoration(labelText: 'Crianças'),
                          validator: (v) => int.tryParse(v ?? '') == null
                              ? 'Informe um número'
                              : null),
                      TextFormField(
                          controller: notes,
                          decoration:
                              const InputDecoration(labelText: 'Observações')),
                      TextFormField(
                          controller: reason,
                          decoration: const InputDecoration(
                              labelText: 'Motivo da alteração'),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Obrigatório para auditoria'
                              : null),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: saving ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar')),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        update(() => saving = true);
                        try {
                          await _repository.patch(rsvp.id,
                              vaiComparecer: attending,
                              qtdAdultos: int.parse(adults.text),
                              qtdCriancas: int.parse(children.text),
                              observacoes: notes.text,
                              motivo: reason.text.trim());
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                          if (mounted) _load();
                        } catch (_) {
                          update(() => saving = false);
                          if (dialogContext.mounted) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Não foi possível salvar a presença.')));
                          }
                        }
                      },
                child: const Text('Salvar'),
              ),
            ],
          ),
        ),
      );
    } finally {
      adults.dispose();
      children.dispose();
      notes.dispose();
      reason.dispose();
    }
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(32),
            child: AdminPageHeader(
              title: 'Detalhe da Presença',
              subtitle: 'RSVP',
              trailing: TextButton(
                  onPressed: () => Navigator.pushReplacementNamed(
                      context, '/admin/presenca'),
                  child: const Text('Voltar à lista')),
            ),
          ),
          Expanded(
            child: FutureBuilder<Rsvp>(
              future: _rsvp,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return snapshot.hasError
                      ? AdminErrorState(
                          message: 'Não foi possível carregar a presença.',
                          onRetry: _load)
                      : const AdminLoadingState();
                }
                final rsvp = snapshot.data!;
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _field('Nome', rsvp.nome),
                          _field('E-mail', rsvp.email),
                          _field('Telefone', rsvp.telefone),
                          _field('Status',
                              rsvp.vaiComparecer ? 'Confirmado' : 'Recusado'),
                          _field('Adultos', '${rsvp.qtdAdultos}'),
                          _field('Crianças', '${rsvp.qtdCriancas}'),
                          _field('Observações', rsvp.observacoes),
                          _field(
                              'Criado em', rsvp.criadoEm.toLocal().toString()),
                          FilledButton.icon(
                              onPressed: () => _edit(rsvp),
                              icon: const Icon(Icons.edit),
                              label: const Text('Editar presença')),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );

  Widget _field(String label, String? value) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          SelectableText(value == null || value.isEmpty ? '—' : value),
        ]),
      );
}
