import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../infraestrutura/abrir_link.dart';
import '../infraestrutura/api_baralho.dart';
import '../infraestrutura/sessoes_locais.dart';
import '../tema/tema_baralho.dart';
import 'selfie.dart';
import 'visual.dart';

/// Círculo grande da selfie: convida a tirar e mostra como ficou.
class _BotaoDaSelfie extends StatelessWidget {
  const _BotaoDaSelfie({required this.foto, required this.aoTocar});

  final Uint8List? foto;
  final VoidCallback? aoTocar;

  @override
  Widget build(BuildContext context) {
    final foto = this.foto;
    return Semantics(
      button: true,
      label: foto == null ? 'Tirar selfie' : 'Trocar selfie',
      child: GestureDetector(
        key: const Key('botao-selfie'),
        onTap: aoTocar,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 128,
                  height: 128,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: CoresBaralho.superficieElevada,
                    border: Border.all(color: CoresBaralho.ambar, width: 3),
                  ),
                  child: ClipOval(
                    child: foto == null
                        ? const Center(child: Text('🤳', style: TextStyle(fontSize: 52)))
                        : Image.memory(foto, fit: BoxFit.cover, width: 128, height: 128),
                  ),
                ),
                Positioned(
                  right: -2,
                  bottom: 2,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: CoresBaralho.ambar, shape: BoxShape.circle),
                    child: Icon(foto == null ? Icons.photo_camera_rounded : Icons.refresh_rounded,
                        size: 20, color: CoresBaralho.fundo),
                  ),
                ),
              ],
            ),
            const SizedBox(height: EspacoBaralho.pequeno),
            Text(
              foto == null ? 'Tire uma selfie com careta' : 'Ficou ótima! Toque para trocar',
              style: const TextStyle(color: CoresBaralho.textoSecundario),
            ),
          ],
        ),
      ),
    );
  }
}

class Inicio extends StatefulWidget {
  const Inicio({super.key, required this.api, required this.sessoes, this.codigoInicial});

  final ApiBaralho api;
  final SessoesLocais sessoes;

  /// Veio pelo link ou QR Code de uma sala: já mostra o campo preenchido.
  final String? codigoInicial;

  @override
  State<Inicio> createState() => _InicioState();
}

class _InicioState extends State<Inicio> {
  final _nome = TextEditingController();
  final _codigo = TextEditingController();
  bool _semAlcool = false;
  bool _enviando = false;
  Uint8List? _selfie;
  bool _jaInsistiuNaSelfie = false;

  bool get _veioPeloLink => widget.codigoInicial != null;

  /// O servidor pode estar dormindo: depois de uns segundos, explica a demora.
  static const _paciencia = Duration(seconds: 3);
  Timer? _relogioDaDemora;
  bool _demorando = false;

  @override
  void initState() {
    super.initState();
    widget.api.acordar();
    _codigo.text = widget.codigoInicial?.toUpperCase() ?? '';
    widget.sessoes.preferencias().then((preferencias) {
      if (!mounted) return;
      setState(() {
        if (_nome.text.isEmpty) _nome.text = preferencias.nome;
        _semAlcool = preferencias.semAlcool;
      });
    });
  }

  @override
  void dispose() {
    _relogioDaDemora?.cancel();
    _nome.dispose();
    _codigo.dispose();
    super.dispose();
  }

  Future<void> _ir({required bool criar}) async {
    final nome = _nome.text.trim();
    if (nome.isEmpty) {
      avisar(context, 'Conta pra gente o seu nome.');
      return;
    }
    if (!criar && _codigo.text.trim().length != 4) {
      avisar(context, 'O código da sala tem 4 letras.');
      return;
    }
    if (_selfie == null && !_jaInsistiuNaSelfie) {
      _jaInsistiuNaSelfie = true;
      final tirar = await _insistirNaSelfie();
      if (!mounted || tirar == null) return;
      if (tirar) {
        await _tirarSelfie();
        if (!mounted || _selfie == null) return;
      }
    }
    setState(() => _enviando = true);
    _relogioDaDemora = Timer(_paciencia, () {
      if (mounted) setState(() => _demorando = true);
    });
    try {
      final entrada = criar
          ? await widget.api.criarSala(nome, semAlcool: _semAlcool)
          : await widget.api.entrar(_codigo.text, nome, semAlcool: _semAlcool);
      await widget.sessoes.guardar(entrada.codigo, entrada.token);
      await widget.sessoes.lembrar(nome: nome, semAlcool: _semAlcool);
      final selfie = _selfie;
      if (selfie != null) {
        try {
          await widget.api.enviarFoto(entrada.codigo, entrada.token, selfie);
        } on FalhaNaApi {
          // Já está na sala: sem a foto, dá para tirar outra na sala de espera.
        }
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/sala/${entrada.codigo}');
    } catch (erro) {
      if (mounted) avisar(context, erro);
    } finally {
      _relogioDaDemora?.cancel();
      if (mounted) {
        setState(() {
          _enviando = false;
          _demorando = false;
        });
      }
    }
  }

  Future<void> _tirarSelfie() async {
    final foto = await tirarSelfie(context);
    if (foto != null && mounted) setState(() => _selfie = foto);
  }

  /// Uma única vez: sem selfie a graça cai pela metade, mas não é obrigatório.
  Future<bool?> _insistirNaSelfie() => showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Sem selfie? 🤨'),
          content: const Text('A graça é ver a cara da turma em cada carta. Bora tirar uma com careta?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Entrar sem foto')),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Tirar selfie'),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -1.1),
            radius: 1.3,
            colors: [Color(0xFF3A2410), CoresBaralho.fundo],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(EspacoBaralho.grande),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('🃏 Baralho da Resenha', textAlign: TextAlign.center, style: texto.headlineMedium),
                    Text(
                      'O jogo da turma. Cada um no seu celular.',
                      textAlign: TextAlign.center,
                      style: texto.bodyMedium?.copyWith(color: CoresBaralho.textoSecundario),
                    ),
                    const SizedBox(height: EspacoBaralho.grande),
                    Center(child: _BotaoDaSelfie(foto: _selfie, aoTocar: _enviando ? null : _tirarSelfie)),
                    const SizedBox(height: EspacoBaralho.grande),
                    TextField(
                      controller: _nome,
                      textCapitalization: TextCapitalization.words,
                      maxLength: 20,
                      decoration: const InputDecoration(labelText: 'Seu nome', counterText: ''),
                    ),
                    const SizedBox(height: EspacoBaralho.pequeno),
                    SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: EspacoBaralho.mini),
                      value: _semAlcool,
                      onChanged: (valor) => setState(() => _semAlcool = valor),
                      title: const Text('Vou jogar sem álcool 🥤'),
                      subtitle: const Text('No lugar de goles, você conta pontos.',
                          style: TextStyle(color: CoresBaralho.textoApagado)),
                    ),
                    const SizedBox(height: EspacoBaralho.base),
                    if (!_veioPeloLink) ...[
                      FilledButton(
                        onPressed: _enviando ? null : () => _ir(criar: true),
                        child: const Text('Criar uma sala'),
                      ),
                      const SizedBox(height: EspacoBaralho.grande),
                      Row(children: [
                        const Expanded(child: Divider(color: CoresBaralho.borda)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: EspacoBaralho.medio),
                          child: Text('ou entre com o código',
                              style: texto.bodyMedium?.copyWith(color: CoresBaralho.textoApagado)),
                        ),
                        const Expanded(child: Divider(color: CoresBaralho.borda)),
                      ]),
                      const SizedBox(height: EspacoBaralho.base),
                    ],
                    TextField(
                      key: const Key('campo-codigo'),
                      controller: _codigo,
                      textAlign: TextAlign.center,
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 4,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp('[a-zA-Z]')),
                        TextInputFormatter.withFunction(
                            (_, novo) => novo.copyWith(text: novo.text.toUpperCase())),
                      ],
                      style: const TextStyle(fontSize: 28, letterSpacing: 12, fontWeight: FontWeight.w600),
                      decoration: const InputDecoration(hintText: 'ABCD', counterText: ''),
                    ),
                    const SizedBox(height: EspacoBaralho.medio),
                    if (_veioPeloLink)
                      FilledButton(
                        onPressed: _enviando ? null : () => _ir(criar: false),
                        child: const Text('Entrar na sala'),
                      )
                    else
                      OutlinedButton(
                        onPressed: _enviando ? null : () => _ir(criar: false),
                        child: const Text('Entrar na sala'),
                      ),
                    if (_veioPeloLink)
                      TextButton(
                        onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
                        child: const Text('Criar outra sala'),
                      ),
                    if (_demorando)
                      const Padding(
                        padding: EdgeInsets.only(top: EspacoBaralho.medio),
                        child: Column(
                          key: Key('carregando'),
                          children: [
                            SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(strokeWidth: 3, color: CoresBaralho.ambar),
                            ),
                            SizedBox(height: EspacoBaralho.pequeno),
                            Text(
                              'Carregando o aplicativo Baralho da Resenha, aguarde…',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: CoresBaralho.ambar),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: EspacoBaralho.base),
                    TextButton(
                      onPressed: () => abrirLink(widget.api.enderecoDoComoJogar),
                      child: const Text('📖 Como jogar?'),
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
