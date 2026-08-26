import 'package:flutter/material.dart';
import '../../data/models/rsvp_data.dart';
import '../../data/repositories/rsvp_repository.dart';
import 'textured_background.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class RsvpSection extends StatefulWidget {
  const RsvpSection({super.key});

  @override
  State<RsvpSection> createState() => _RsvpSectionState();
}

class _RsvpSectionState extends State<RsvpSection> {
  final _formKey = GlobalKey<FormState>();
  final _repository = RsvpRepository();

  bool _isLoading = false;
  String? _successMessage;
  String? _errorMessage;

  String _name = '';
  bool? _attending;
  int _adults = 1;
  int _children = 0;
  String _email = '';
  String _phone = '';
  String _message = '';
  bool _acceptTerms = false;
  bool _acceptUpdates = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_attending == null) {
      setState(() => _errorMessage = 'Por favor, selecione se você irá ao evento.');
      return;
    }
    if (!_acceptTerms) {
      setState(() => _errorMessage = 'Você deve aceitar os termos de uso.');
      return;
    }

    _formKey.currentState!.save();
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await _repository.submitRsvp(
        RsvpData(
          name: _name,
          attending: _attending!,
          adults: _attending! ? _adults : 0,
          children: _attending! ? _children : 0,
          email: _email,
          phone: _phone,
          message: _message,
          acceptTerms: _acceptTerms,
          acceptUpdates: _acceptUpdates,
        ),
      );
      setState(() {
        _successMessage = 'Sua presença foi confirmada com sucesso!';
      });
      _formKey.currentState!.reset();
      setState(() {
        _attending = null;
        _acceptTerms = false;
        _acceptUpdates = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Ocorreu um erro ao enviar. Tente novamente.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return TexturedBackground(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 96.0, horizontal: 24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 768),
            child: Container(
              padding: EdgeInsets.all(MediaQuery.of(context).size.width >= 768 ? 64.0 : 32.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withAlpha(25)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(50),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Text(
                      'Confirme sua presença',
                      style: AppTextStyles.cursive.copyWith(
                        fontSize: 48,
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
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(127),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),

                    if (_successMessage != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        color: Colors.green.withAlpha(25),
                        width: double.infinity,
                        child: Text(
                          _successMessage!,
                          style: const TextStyle(color: Colors.green),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        color: Colors.red.withAlpha(25),
                        width: double.infinity,
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    if (_successMessage != null || _errorMessage != null)
                      const SizedBox(height: 24),

                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'NOME COMPLETO',
                        labelStyle: TextStyle(fontSize: 10, letterSpacing: 2.0, fontWeight: FontWeight.bold),
                      ),
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      validator: (value) => value == null || value.isEmpty ? 'Campo obrigatório' : null,
                      onSaved: (value) => _name = value!,
                    ),
                    const SizedBox(height: 24),
                    
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('VOCÊ IRÁ AO EVENTO?', style: TextStyle(fontSize: 10, letterSpacing: 2.0, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 16,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Radio<bool>(
                                  value: true,
                                  groupValue: _attending,
                                  onChanged: (value) => setState(() => _attending = value),
                                  activeColor: AppColors.primary,
                                ),
                                const Text('Sim, confirmarei'),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Radio<bool>(
                                  value: false,
                                  groupValue: _attending,
                                  onChanged: (value) => setState(() => _attending = value),
                                  activeColor: AppColors.primary,
                                ),
                                const Text('Não poderei ir'),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            decoration: const InputDecoration(
                              labelText: 'ADULTOS',
                              labelStyle: TextStyle(fontSize: 10, letterSpacing: 2.0, fontWeight: FontWeight.bold),
                            ),
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                            dropdownColor: Theme.of(context).colorScheme.surface,
                            value: _adults,
                            items: [1, 2, 3, 4].map((e) => DropdownMenuItem(value: e, child: Text(e.toString()))).toList(),
                            onChanged: _attending == false ? null : (value) => setState(() => _adults = value!),
                          ),
                        ),
                        const SizedBox(width: 32),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            decoration: const InputDecoration(
                              labelText: 'CRIANÇAS (ATÉ 10 ANOS)',
                              labelStyle: TextStyle(fontSize: 10, letterSpacing: 2.0, fontWeight: FontWeight.bold),
                            ),
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                            dropdownColor: Theme.of(context).colorScheme.surface,
                            value: _children,
                            items: [0, 1, 2, 3].map((e) => DropdownMenuItem(value: e, child: Text(e.toString()))).toList(),
                            onChanged: _attending == false ? null : (value) => setState(() => _children = value!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'E-MAIL',
                        labelStyle: TextStyle(fontSize: 10, letterSpacing: 2.0, fontWeight: FontWeight.bold),
                      ),
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      keyboardType: TextInputType.emailAddress,
                      onSaved: (value) => _email = value ?? '',
                    ),
                    const SizedBox(height: 24),

                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'TELEFONE / WHATSAPP',
                        labelStyle: TextStyle(fontSize: 10, letterSpacing: 2.0, fontWeight: FontWeight.bold),
                      ),
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      keyboardType: TextInputType.phone,
                      onSaved: (value) => _phone = value ?? '',
                    ),
                    const SizedBox(height: 24),

                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'MENSAGEM / OBSERVAÇÕES',
                        labelStyle: TextStyle(fontSize: 10, letterSpacing: 2.0, fontWeight: FontWeight.bold),
                      ),
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      maxLines: 3,
                      onSaved: (value) => _message = value ?? '',
                    ),
                    const SizedBox(height: 32),

                    CheckboxListTile(
                      value: _acceptTerms,
                      onChanged: (value) => setState(() => _acceptTerms = value ?? false),
                      title: const Text('Li e aceito os termos de uso.', style: TextStyle(fontSize: 12)),
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: AppColors.primary,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: _acceptUpdates,
                      onChanged: (value) => setState(() => _acceptUpdates = value ?? false),
                      title: const Text('Desejo receber atualizações sobre o evento.', style: TextStyle(fontSize: 12)),
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: AppColors.primary,
                      contentPadding: EdgeInsets.zero,
                    ),
                    
                    const SizedBox(height: 48),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        child: _isLoading 
                            ? const CircularProgressIndicator(color: AppColors.white)
                            : const Text('CONFIRMAR PRESENÇA'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
