import 'package:flutter/material.dart';
import 'evaluations_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  String? _emailValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Ingresa tu correo';
    if (!v.contains('@')) return 'El correo debe incluir @';
    return null;
  }

  String? _passValidator(String? v) {
    if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
    if (v.length < 6) return 'Mínimo 6 caracteres';
    return null;
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;
    setState(() => _submitting = true);
    await Future.delayed(const Duration(milliseconds: 400)); // simulación
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const EvaluationsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Verde principal y más oscuro para el botón
    const Color darkGreen = Color(0xFF3E6F24); // <- más oscuro que #5B9E35

    return Scaffold(
      // permite que el contenido se ajuste al teclado
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: const Text('Inicio de sesión')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(16),
              // scroll para evitar overflow con teclado
              child: SingleChildScrollView(
                // empuja el contenido lo mismo que mide el teclado
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: AutofillGroup(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo + título
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            children: [
                              Image.asset(
                                'assets/images/laspalmeras_logo.png',
                                height: 120,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Junta de Vecinos Las Palmeras',
                                style: Theme.of(context).textTheme.titleMedium,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),

                        // Correo
                        TextFormField(
                          controller: _emailCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Correo',
                            hintText: 'tucorreo@dominio.com',
                          ),
                          validator: _emailValidator,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.username],
                        ),
                        const SizedBox(height: 12),

                        // Contraseña
                        TextFormField(
                          controller: _passCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Contraseña',
                          ),
                          obscureText: true,
                          validator: _passValidator,
                          autofillHints: const [AutofillHints.password],
                        ),
                        const SizedBox(height: 16),

                        // Botón Ingresar (verde oscuro)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: darkGreen, // 👈 más oscuro
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: const StadiumBorder(),
                              elevation: 0,
                            ),
                            onPressed: _submitting ? null : _submit,
                            icon: const Icon(Icons.login),
                            label: _submitting
                                ? const Text('Ingresando...')
                                : const Text('Ingresar'),
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
      ),
    );
  }
}



