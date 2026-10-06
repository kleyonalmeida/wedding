import 'package:flutter/material.dart';
import '../../../../app_navigation.dart';
import '../../../../core/network/api_client.dart';
import '../../data/models/rsvp_data.dart';
import '../../data/repositories/rsvp_repository.dart';
import '../widgets/textured_background.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../widgets/wedding_footer.dart';

class RsvpFormPage extends StatefulWidget {
  final RsvpRepository? repository;
  const RsvpFormPage({super.key, this.repository});

  @override
  State<RsvpFormPage> createState() => _RsvpFormPageState();
}

class _RsvpFormPageState extends State<RsvpFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final RsvpRepository _repository;
  final _identificationFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? RsvpRepository();
  }

  bool _isLoading = false;

  String _identificacaoNoConvite = '';
  bool? _attending;
  bool? _bringingChildren;
  int _children = 1; // Default when bringingChildren is true
  String _email = '';
  String _phone = '';
  bool _acceptTerms = false;

  @override
  void dispose() {
    _identificationFocus.dispose();
    super.dispose();
  }

  void _showErrorModal(String textDigitado) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Identificação não encontrada',
            style: TextStyle(color: AppColors.primary)),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Verificamos que "$textDigitado" não consta em nossa lista de convidados para o casamento. Por favor verifique se:',
                style: const TextStyle(fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.only(left: 16.0),
                child: Text(
                  '• O nome está exatamente conforme escrito no convite\n• Devem ser escritos ambos os nomes na caixinha de texto',
                  style: TextStyle(fontSize: 15, height: 1.5),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Caso esteja correto e o aviso continua aparecendo a você, lamentamos o transtorno, mas isso quer dizer que você não foi convidado.',
                style: TextStyle(fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: 12),
              const Text(
                'Pedimos que não insista em novas tentativas. Se desejar esclarecimentos, entre em contato com o noivo ou com a noiva.',
                style: TextStyle(fontSize: 15, height: 1.5),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('VOLTAR',
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    ).then((_) {
      if (mounted) _identificationFocus.requestFocus();
    });
  }

  void _showSuccessModal(bool attending, String identificacao) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(attending ? 'Que Felicidade!!' : 'Tudo certo!',
            style: const TextStyle(color: AppColors.primary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              attending
                  ? 'Agradecemos por confirmar a presença de $identificacao. Nosso dia ficou ainda mais especial! Será de grande alegria celebrar esse momento juntos.'
                  : 'Sabemos que a data é um pouco complicada devido às festividades, mas agradecemos o tempo que dedicou para nos responder aqui.',
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 12),
            Text(
              attending
                  ? 'Fique à vontade para olhar nosso site e explorá-lo.'
                  : 'Sinta-se à vontade para apreciar o site, ver as fotos e, se quiser, visitar nossa área de presentes.',
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              AppNavigation.go(this.context, '/');
            },
            child: const Text('VER O SITE',
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w800)),
          ),
          if (!attending)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                AppNavigation.go(this.context, '/presentes');
              },
              child: const Text('VER PRESENTES', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800)),
            ),
        ],
      ),
    );
  }

  void _showGenericError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_attending == null) {
      _showGenericError('Por favor, selecione se você irá ao evento.');
      return;
    }
    if (_attending == true && _bringingChildren == null) {
      _showGenericError('Por favor, selecione se levarão crianças.');
      return;
    }
    if (!_acceptTerms) {
      _showGenericError('Você deve aceitar os termos de uso.');
      return;
    }

    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    try {
      await _repository.submitRsvp(
        RsvpData(
          identificacaoNoConvite: _identificacaoNoConvite,
          attending: _attending!,
          children: (_attending! && _bringingChildren == true) ? _children : 0,
          email: _email,
          phone: _phone,
          acceptTerms: _acceptTerms,
        ),
      );

      if (!mounted) return;
      _showSuccessModal(_attending!, _identificacaoNoConvite);
    } on ApiException catch (error) {
      if (!mounted) return;
      if (error.code == 'INVITATION_NOT_FOUND') {
        _showErrorModal(_identificacaoNoConvite);
      } else if (error.code == 'INVITATION_ALREADY_RESPONDED') {
        _showGenericError('Já existe uma resposta para esta identificação.');
      } else {
        _showGenericError(
            error.message ?? 'Confira os dados e tente novamente.');
      }
    } catch (_) {
      if (mounted) _showGenericError('Erro de conexão. Tente novamente.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _eventCard(IconData icon, String label, String title, String detail) {
    return SizedBox(
      width: 290,
      child: Card(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            Icon(icon, color: AppColors.primary, size: 30),
            const SizedBox(height: 12),
            Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    letterSpacing: 1.5,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: 'Playfair Display',
                    fontSize: 20,
                    color: AppColors.dark)),
            const SizedBox(height: 4),
            Text(detail,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w500)),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: InkWell(
          onTap: () => AppNavigation.go(context, '/'),
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text(
              'K&L',
              style: AppTextStyles.serif.copyWith(
                fontSize: 24,
                letterSpacing: 4.0,
                color: AppColors.dark,
              ),
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.dark),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
              child: Column(children: [
                const Text('R.S.V.P. • CONFIRMAÇÃO DE PRESENÇA',
                    style: TextStyle(
                        fontSize: 12,
                        letterSpacing: 2,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                const Text('Celebre Este Dia Conosco',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: 'Playfair Display',
                        fontSize: 36,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary)),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: const Text(
                    'Sua presença é muito especial para nós. Confirme até 01 de novembro de 2026 para que possamos preparar cada detalhe.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurfaceVariant),
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 16,
                    runSpacing: 12,
                    children: [
                      _eventCard(
                          Icons.calendar_today_outlined,
                          'DATA E HORÁRIO',
                          '26 de dezembro de 2026',
                          'Às 15h00'),
                      _eventCard(Icons.location_on_outlined, 'LOCAL',
                          'Casa da Mangueira Eventos', 'Feira de Santana • BA'),
                    ]),
              ]),
            ),
            TexturedBackground(
              textureAssetPath: 'assets/images/texture_3x3.png',
              textureFit: BoxFit.none,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 48.0, horizontal: 24.0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 768),
                    child: Container(
                      padding: EdgeInsets.all(
                          MediaQuery.of(context).size.width >= 768
                              ? 64.0
                              : 32.0),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: AppColors.primary.withAlpha(25)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(50),
                            blurRadius: 8,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Confirme sua presença',
                              style: AppTextStyles.cursive.copyWith(
                                fontSize:
                                    MediaQuery.of(context).size.width >= 768
                                        ? 76
                                        : 44,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'POR FAVOR, CONFIRME ATÉ O DIA 01/11/2026',
                              style: AppTextStyles.sans.copyWith(
                                fontSize: 12,
                                letterSpacing: 2.0,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.8),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 48),
                            TextFormField(
                              focusNode: _identificationFocus,
                              maxLength: 200,
                              decoration: const InputDecoration(
                                labelText: 'Identificação como está no convite',
                                hintText: 'Ex: Jorge e Amanda',
                              ),
                              style: AppTextStyles.sans.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              validator: (value) =>
                                  value == null || value.trim().isEmpty
                                      ? 'Campo obrigatório'
                                      : null,
                              onSaved: (value) =>
                                  _identificacaoNoConvite = value!.trim(),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'VOCÊ IRÁ AO EVENTO?',
                              style: AppTextStyles.sans.copyWith(
                                fontSize: 11,
                                letterSpacing: 1.8,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              children: [
                                ChoiceChip(
                                  label: const Text('Sim, confirmo presença'),
                                  selected: _attending == true,
                                  onSelected: (_) =>
                                      setState(() => _attending = true),
                                ),
                                ChoiceChip(
                                  label: const Text('Não poderei ir'),
                                  selected: _attending == false,
                                  onSelected: (_) => setState(() {
                                    _attending = false;
                                    _bringingChildren = null;
                                  }),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            if (_attending == true) ...[
                              Text(
                                'LEVARÃO CRIANÇAS?',
                                style: AppTextStyles.sans.copyWith(
                                  fontSize: 11,
                                  letterSpacing: 1.8,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: SegmentedButton<bool>(
                                  emptySelectionAllowed: true,
                                  segments: const [
                                    ButtonSegment(value: true, label: Text('Sim')),
                                    ButtonSegment(value: false, label: Text('Não')),
                                  ],
                                  selected: _bringingChildren == null
                                      ? {}
                                      : {_bringingChildren!},
                                  onSelectionChanged: (values) => setState(
                                      () => _bringingChildren =
                                          values.isEmpty ? null : values.first),
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (_bringingChildren == true)
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: SizedBox(
                                    width: 180,
                                    child: DropdownButtonFormField<int>(
                                      decoration: const InputDecoration(
                                        labelText: 'QTD. DE CRIANÇAS',
                                      ),
                                      initialValue: _children,
                                      items: List.generate(5, (index) => index + 1)
                                          .map((e) => DropdownMenuItem(
                                              value: e, child: Text(e.toString())))
                                          .toList(),
                                      onChanged: (value) =>
                                          setState(() => _children = value!),
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 24),
                            ],
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'E-MAIL',
                              ),
                              style: AppTextStyles.sans.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Campo obrigatório';
                                }
                                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                    .hasMatch(value.trim())) {
                                  return 'E-mail inválido';
                                }
                                return null;
                              },
                              onSaved: (value) => _email = value!.trim(),
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'TELEFONE / WHATSAPP',
                              ),
                              style: AppTextStyles.sans.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Campo obrigatório';
                                }
                                if (!RegExp(
                                        r'^\(?\d{2}\)?[\s\-]?\d{4,5}[\s\-]?\d{4}$')
                                    .hasMatch(value.trim())) {
                                  return 'Telefone inválido';
                                }
                                return null;
                              },
                              onSaved: (value) => _phone = value!.trim(),
                            ),
                            const SizedBox(height: 32),
                            Material(
                                color: Colors.transparent,
                                child: CheckboxListTile(
                                  value: _acceptTerms,
                                  onChanged: (value) => setState(
                                      () => _acceptTerms = value ?? false),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Li e aceito a política de privacidade (LGPD).',
                                          style: AppTextStyles.sans.copyWith(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.info_outline, size: 20),
                                        color: AppColors.primary,
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text('Política de Privacidade', style: TextStyle(color: AppColors.primary)),
                                              content: const SingleChildScrollView(
                                                child: Text(
                                                  'Em conformidade com a Lei Geral de Proteção de Dados (LGPD - Lei nº 13.709/2018), informamos que os dados pessoais coletados neste formulário (identificação, e-mail, telefone e informações sobre acompanhantes) serão utilizados exclusivamente para a organização e gestão da lista de convidados do evento.\n\nAo confirmar sua presença, você consente com o tratamento desses dados para este fim. As informações não serão compartilhadas com terceiros não envolvidos na organização e serão descartadas após o evento.',
                                                  style: TextStyle(height: 1.5, fontSize: 14),
                                                ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.of(context).pop(),
                                                  child: const Text('FECHAR', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  activeColor: AppColors.primary,
                                  contentPadding: EdgeInsets.zero,
                                )),
                            const SizedBox(height: 48),
                            Center(
                              child: FractionallySizedBox(
                                widthFactor: 0.5,
                                child: SizedBox(
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _submit,
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const CircularProgressIndicator(
                                            color: AppColors.white)
                                        : const Text('CONFIRMAR PRESENÇA'),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
              child: Column(children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 768),
                  child: Card(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(children: const [
                        Icon(Icons.support_agent, color: AppColors.primary),
                        SizedBox(width: 16),
                        Expanded(
                            child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Precisa de ajuda com o seu convite?',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary)),
                            SizedBox(height: 4),
                            Text(
                                'Entre em contato com os noivos para esclarecer qualquer dúvida.',
                                style: TextStyle(fontWeight: FontWeight.w500)),
                          ],
                        )),
                      ]),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  '“O amor não se mede pelo que se tem, mas pelo que se compartilha com quem se ama.”',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: 'Bodoni Moda',
                      fontSize: 20,
                      fontStyle: FontStyle.italic,
                      color: AppColors.primary),
                ),
                const SizedBox(height: 8),
                const Text('KLEYON & LIANDRA • 26.12.2026',
                    style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary)),
              ]),
            ),
            const WeddingFooter(),
          ],
        ),
      ),
    );
  }
}
