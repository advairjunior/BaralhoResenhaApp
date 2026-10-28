import 'package:shared_preferences/shared_preferences.dart';

/// Guarda no aparelho em qual sala a pessoa está, para recarregar a página
/// (ou o celular bloquear) e voltar direto para o jogo.
class SessoesLocais {
  static const _prefixoSala = 'sala_';
  static const _chaveNome = 'ultimo_nome';
  static const _chaveSemAlcool = 'sem_alcool';
  static const _chaveCartasVistas = 'cartas_vistas';
  static const _chaveSom = 'som_ligado';
  static const _chaveVoz = 'voz_ligada';

  /// Cartas guardadas: o bastante para lembrar várias noites sem pesar no aparelho.
  static const _limiteDeCartasVistas = 600;

  Future<String?> token(String codigo) async =>
      (await SharedPreferences.getInstance()).getString('$_prefixoSala${codigo.toUpperCase()}');

  Future<void> guardar(String codigo, String token) async =>
      (await SharedPreferences.getInstance()).setString('$_prefixoSala${codigo.toUpperCase()}', token);

  Future<void> esquecer(String codigo) async =>
      (await SharedPreferences.getInstance()).remove('$_prefixoSala${codigo.toUpperCase()}');

  Future<({String nome, bool semAlcool})> preferencias() async {
    final preferencias = await SharedPreferences.getInstance();
    return (
      nome: preferencias.getString(_chaveNome) ?? '',
      semAlcool: preferencias.getBool(_chaveSemAlcool) ?? false,
    );
  }

  /// Cartas que já saíram neste aparelho, da mais antiga à mais nova.
  Future<List<String>> cartasVistas() async =>
      (await SharedPreferences.getInstance()).getStringList(_chaveCartasVistas) ?? const [];

  /// Lembra a carta para a próxima noite não começar pelas mesmas.
  Future<void> marcarVista(String cartaId) async {
    final preferencias = await SharedPreferences.getInstance();
    final vistas = [...?preferencias.getStringList(_chaveCartasVistas)]
      ..remove(cartaId)
      ..add(cartaId);
    final excesso = vistas.length - _limiteDeCartasVistas;
    await preferencias.setStringList(_chaveCartasVistas, excesso > 0 ? vistas.sublist(excesso) : vistas);
  }

  /// Som e vibração: ligados até a pessoa desligar.
  Future<bool> somLigado() async => (await SharedPreferences.getInstance()).getBool(_chaveSom) ?? true;

  Future<void> guardarSom(bool ligado) async => (await SharedPreferences.getInstance()).setBool(_chaveSom, ligado);

  /// Voz das cartas (só fala no celular de quem comanda): ligada até a pessoa desligar.
  Future<bool> vozLigada() async => (await SharedPreferences.getInstance()).getBool(_chaveVoz) ?? true;

  Future<void> guardarVoz(bool ligada) async => (await SharedPreferences.getInstance()).setBool(_chaveVoz, ligada);

  Future<void> lembrar({required String nome, required bool semAlcool}) async {
    final preferencias = await SharedPreferences.getInstance();
    await preferencias.setString(_chaveNome, nome);
    await preferencias.setBool(_chaveSemAlcool, semAlcool);
  }
}
