import 'package:shared_preferences/shared_preferences.dart';

/// Guarda no aparelho em qual sala a pessoa está, para recarregar a página
/// (ou o celular bloquear) e voltar direto para o jogo.
class SessoesLocais {
  static const _prefixoSala = 'sala_';
  static const _chaveNome = 'ultimo_nome';
  static const _chaveSemAlcool = 'sem_alcool';

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

  Future<void> lembrar({required String nome, required bool semAlcool}) async {
    final preferencias = await SharedPreferences.getInstance();
    await preferencias.setString(_chaveNome, nome);
    await preferencias.setBool(_chaveSemAlcool, semAlcool);
  }
}
