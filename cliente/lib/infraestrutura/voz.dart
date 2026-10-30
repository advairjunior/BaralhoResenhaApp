import '../dominio/modelos.dart';
import '../telas/visual.dart';
import 'falador.dart';

/// Quem lê a carta. A voz é a do celular; o personagem vem do tom e da velocidade.
enum Personagem {
  locutor(chamada: 'Atenção, turma!', tom: 0.6, velocidade: 0.95),
  esquilo(chamada: 'Ihhh, olha essa!', tom: 2.0, velocidade: 1.25),
  peao(chamada: 'Segura, peão!', tom: 0.9, velocidade: 0.8),
  robo(chamada: 'Processando a próxima carta.', tom: 0.1, velocidade: 1.0),
  vo(chamada: 'Ai, meus filhos, escutem essa.', tom: 1.5, velocidade: 0.85);

  const Personagem({required this.chamada, required this.tom, required this.velocidade});

  final String chamada;

  /// Tom de 0 a 2 (1 é o normal) e velocidade (1 é a normal), como o navegador entende.
  final double tom;
  final double velocidade;
}

/// Cada carta com um personagem, em rodízio: a mesa não ouve o mesmo duas vezes seguidas.
Personagem personagemDa(int numeroDaCarta) => Personagem.values[numeroDaCarta % Personagem.values.length];

/// A voz lê as cartas no celular de quem está no comando; quem não quer, desliga pelo menu.
bool vozLigada = true;

/// Emoji a voz leria pelo nome ("rosto chorando de rir"): sai antes de falar.
final _emojis = RegExp(r'[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{2B00}-\u{2BFF}\u{FE0F}\u{200D}]', unicode: true);

/// O "(a)" de "expulso(a)" a voz leria como "expulso a": fica só o masculino.
final _generoEntreParenteses = RegExp(r'\((a|as|o|os)\)');

String _semEmoji(String texto) => texto.replaceAll(_emojis, '').replaceAll(_generoEntreParenteses, '').replaceAll(RegExp(r'\s+'), ' ').replaceAll(' .', '.').trim();

/// O que a mesa ouve. Carta com segredo (a palavra da mímica, a do Impostor, a
/// pergunta do Correio) só é anunciada: o segredo continua só na tela de quem pode ver.
String falaDaCarta(VisaoDaSala visao) {
  final rodada = visao.rodada!;
  String nome(String? id) => visao.jogador(id ?? '')?.nome ?? 'alguém';
  final carta = switch (rodada.modo) {
    ModoDeJogo.imagemEAcao =>
      '${rodada.times.map((time) => nome(time.mimico)).join(' e ')} faz${rodada.times.length > 1 ? 'em' : ''} a mímica.',
    ModoDeJogo.impostor => '${rodada.dica ?? ''}. Cada um olha o seu celular.',
    ModoDeJogo.correio => 'A pergunta está no celular da turma.',
    ModoDeJogo.batataQuente => '${rodada.texto}. Começa com ${nome(rodada.comABatata)}!',
    _ => rodada.texto,
  };
  final titulo = switch (rodada) {
    Rodada(jokenpo: true) => 'Pedra, papel e tesoura!',
    Rodada(duelo: true) => 'Duelo!',
    Rodada(modo: ModoDeJogo.correio) => '${rodada.modo.titulo} para ${nome(rodada.alvo)}!',
    _ => '${rodada.modo.titulo}!',
  };
  return _semEmoji('${personagemDa(rodada.numero).chamada} $titulo $carta');
}

/// Lê a carta, se a voz deste celular estiver ligada.
void falarCarta(VisaoDaSala visao) {
  if (vozLigada) falar(falaDaCarta(visao), personagemDa(visao.rodada!.numero));
}
