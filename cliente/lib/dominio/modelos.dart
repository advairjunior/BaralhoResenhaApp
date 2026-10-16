enum ModoDeJogo { euNunca, maisProvavel, bebaSe, regraRelampago, casaisEmJogo, tribunal, elogios, correio, imagemEAcao }

enum NivelDaCarta { leve, resenha, picante, original }

enum FaseDaSala { lobby, carta, revelada, fim }

/// Quantos pontos (vezes que a carta pegou) valem um gole de verdade.
enum RitmoDaBebida { devagar, normal, raiz }

/// O servidor fala em PascalCase ("EuNunca"); o app em camelCase.
T _enum<T extends Enum>(List<T> valores, Object? texto) {
  final procurado = (texto as String).toLowerCase();
  return valores.firstWhere((valor) => valor.name.toLowerCase() == procurado);
}

String paraServidor(Enum valor) => valor.name[0].toUpperCase() + valor.name.substring(1);

class Entrada {
  const Entrada({required this.codigo, required this.token});

  factory Entrada.deJson(Map<String, dynamic> json) =>
      Entrada(codigo: json['codigo'] as String, token: json['token'] as String);

  final String codigo;
  final String token;
}

/// Cartas por nível no Esquenta sozinho (igual ao servidor).
const cartasPorNivel = 8;

class ConfiguracaoDoJogo {
  const ConfiguracaoDoJogo({
    required this.nivel,
    required this.modos,
    required this.zonaSegura,
    this.esquentar = false,
    this.ritmo = RitmoDaBebida.devagar,
  });

  factory ConfiguracaoDoJogo.deJson(Map<String, dynamic> json) => ConfiguracaoDoJogo(
        nivel: _enum(NivelDaCarta.values, json['nivel']),
        modos: (json['modos'] as List).map((m) => _enum(ModoDeJogo.values, m)).toSet(),
        zonaSegura: json['zonaSegura'] as bool,
        esquentar: json['esquentar'] as bool? ?? false,
        ritmo: json['ritmo'] == null ? RitmoDaBebida.devagar : _enum(RitmoDaBebida.values, json['ritmo']),
      );

  /// Com [esquentar], é até onde a noite pode chegar.
  final NivelDaCarta nivel;
  final Set<ModoDeJogo> modos;
  final bool zonaSegura;

  /// Começa no Leve e sobe um nível a cada [cartasPorNivel] cartas.
  final bool esquentar;

  /// Cofrinho de goles: quantos pontos valem um gole.
  final RitmoDaBebida ritmo;

  int get pontosPorGole => switch (ritmo) {
        RitmoDaBebida.devagar => 3,
        RitmoDaBebida.normal => 2,
        RitmoDaBebida.raiz => 1,
      };

  ConfiguracaoDoJogo copiar({
    NivelDaCarta? nivel,
    Set<ModoDeJogo>? modos,
    bool? zonaSegura,
    bool? esquentar,
    RitmoDaBebida? ritmo,
  }) =>
      ConfiguracaoDoJogo(
        nivel: nivel ?? this.nivel,
        modos: modos ?? this.modos,
        zonaSegura: zonaSegura ?? this.zonaSegura,
        esquentar: esquentar ?? this.esquentar,
        ritmo: ritmo ?? this.ritmo,
      );

  Map<String, dynamic> paraJson() => {
        'nivel': paraServidor(nivel),
        'modos': [for (final modo in ModoDeJogo.values) if (modos.contains(modo)) paraServidor(modo)],
        'zonaSegura': zonaSegura,
        'esquentar': esquentar,
        'ritmo': paraServidor(ritmo),
      };
}

/// Esquenta sozinho durante o jogo.
class Esquenta {
  const Esquenta({required this.agora, required this.ate, required this.sobeEm, required this.subiuAgora});

  factory Esquenta.deJson(Map<String, dynamic> json) => Esquenta(
        agora: _enum(NivelDaCarta.values, json['agora']),
        ate: _enum(NivelDaCarta.values, json['ate']),
        sobeEm: json['sobeEm'] as int?,
        subiuAgora: json['subiuAgora'] as bool,
      );

  final NivelDaCarta agora;
  final NivelDaCarta ate;

  /// Cartas até subir; nulo quando já chegou ao limite.
  final int? sobeEm;

  /// Primeira carta do nível novo.
  final bool subiuAgora;
}

class Jogador {
  const Jogador({
    required this.id,
    required this.nome,
    required this.anfitriao,
    required this.semAlcool,
    required this.goles,
    required this.respondeu,
    this.pontos = 0,
    this.cofrinho = 0,
    this.foto,
    this.parId,
  });

  /// [enderecoBase] completa o caminho da selfie, que vem relativo da API.
  factory Jogador.deJson(Map<String, dynamic> json, {String enderecoBase = ''}) => Jogador(
        id: json['id'] as String,
        nome: json['nome'] as String,
        anfitriao: json['anfitriao'] as bool,
        semAlcool: json['semAlcool'] as bool,
        goles: json['goles'] as int,
        pontos: json['pontos'] as int? ?? 0,
        cofrinho: json['cofrinho'] as int? ?? 0,
        respondeu: json['respondeu'] as bool,
        foto: json['foto'] == null ? null : '$enderecoBase${json['foto']}',
        parId: json['parId'] as String?,
      );

  final String id;
  final String nome;
  final bool anfitriao;
  final bool semAlcool;
  /// Goles de verdade: um a cada cofrinho cheio.
  final int goles;

  /// Vezes que a carta pegou a pessoa.
  final int pontos;

  /// Pontos guardados até virar gole.
  final int cofrinho;
  final bool respondeu;

  /// Endereço da selfie; nulo para quem entrou sem foto.
  final String? foto;

  /// Par do casal na sala.
  final String? parId;

  /// Placar: quem joga sem álcool conta pontos; os outros, goles de verdade.
  String get placar => semAlcool
      ? (pontos == 1 ? '1 ponto' : '$pontos pontos')
      : (goles == 1 ? '1 gole' : '$goles goles');
}

class VotosRecebidos {
  const VotosRecebidos(this.jogadorId, this.votos);

  final String jogadorId;
  final int votos;
}

class Revelacao {
  const Revelacao({
    required this.jaFizeram,
    required this.nuncaFizeram,
    required this.votos,
    required this.perderam,
    required this.contaAHistoria,
    this.respostaDoAlvo,
    this.palpiteDoPar,
    this.elogio = false,
    this.escolhidos = const [],
    this.bilhetes = const [],
    this.timeVencedor,
  });

  factory Revelacao.deJson(Map<String, dynamic> json) => Revelacao(
        jaFizeram: List<String>.from(json['jaFizeram'] as List),
        nuncaFizeram: List<String>.from(json['nuncaFizeram'] as List),
        votos: [
          for (final voto in json['votos'] as List)
            VotosRecebidos(voto['jogadorId'] as String, voto['votos'] as int),
        ],
        perderam: List<String>.from(json['perderam'] as List),
        contaAHistoria: json['contaAHistoria'] as String?,
        respostaDoAlvo: json['respostaDoAlvo'] as String?,
        palpiteDoPar: json['palpiteDoPar'] as String?,
        elogio: json['elogio'] as bool? ?? false,
        escolhidos: List<String>.from((json['escolhidos'] as List?) ?? const []),
        bilhetes: List<String>.from((json['bilhetes'] as List?) ?? const []),
        timeVencedor: json['timeVencedor'] as int?,
      );

  final List<String> jaFizeram;
  final List<String> nuncaFizeram;
  final List<VotosRecebidos> votos;
  final List<String> perderam;
  final String? contaAHistoria;

  /// Casais em Jogo: a verdade de quem foi perguntado e o chute do par.
  final String? respostaDoAlvo;
  final String? palpiteDoPar;

  /// Carta de elogio: quem a turma escolhe não bebe, distribui goles.
  final bool elogio;

  /// Quem a turma escolheu (mais votado ou réu condenado), bebendo ou não.
  final List<String> escolhidos;

  /// Correio da Resenha: os bilhetes, embaralhados e sem autor.
  final List<String> bilhetes;

  /// Imagem e Ação: o time que acertou; nulo quando ninguém acertou.
  final int? timeVencedor;
}

/// Imagem e Ação: quem faz a mímica e quem adivinha (o mímico está junto).
class TimeDaMimica {
  const TimeDaMimica({required this.mimico, required this.jogadores});

  factory TimeDaMimica.deJson(Map<String, dynamic> json) =>
      TimeDaMimica(mimico: json['mimico'] as String, jogadores: List<String>.from(json['jogadores'] as List));

  final String mimico;
  final List<String> jogadores;
}

class Rodada {
  const Rodada({
    required this.numero,
    required this.modo,
    required this.nivel,
    required this.texto,
    required this.pedeResposta,
    required this.minhaResposta,
    required this.respostas,
    required this.euBebi,
    required this.beberam,
    required this.revelacao,
    this.palpiteiro,
    this.alvo,
    this.acertou,
    this.votacao = false,
    this.elogio = false,
    this.favorito,
    this.bebemAgora = const [],
    this.vacilaram = const [],
    this.duelistas = const [],
    this.times = const [],
    this.dica,
  });

  factory Rodada.deJson(Map<String, dynamic> json) => Rodada(
        numero: json['numero'] as int,
        modo: _enum(ModoDeJogo.values, json['modo']),
        nivel: _enum(NivelDaCarta.values, json['nivel']),
        texto: json['texto'] as String,
        pedeResposta: json['pedeResposta'] as bool,
        minhaResposta: json['minhaResposta'] as String?,
        respostas: json['respostas'] as int,
        euBebi: json['euBebi'] as bool,
        beberam: List<String>.from(json['beberam'] as List),
        revelacao: json['revelacao'] == null
            ? null
            : Revelacao.deJson(json['revelacao'] as Map<String, dynamic>),
        palpiteiro: json['palpiteiro'] as String?,
        alvo: json['alvo'] as String?,
        acertou: json['acertou'] as bool?,
        votacao: json['votacao'] as bool? ?? false,
        elogio: json['elogio'] as bool? ?? false,
        favorito: json['favorito'] as int?,
        bebemAgora: List<String>.from((json['bebemAgora'] as List?) ?? const []),
        vacilaram: List<String>.from((json['vacilaram'] as List?) ?? const []),
        duelistas: List<String>.from((json['duelistas'] as List?) ?? const []),
        times: [
          for (final time in (json['times'] as List?) ?? const [])
            TimeDaMimica.deJson(time as Map<String, dynamic>),
        ],
        dica: json['dica'] as String?,
      );

  final int numero;
  final ModoDeJogo modo;
  final NivelDaCarta nivel;
  final String texto;
  final bool pedeResposta;
  final String? minhaResposta;
  final int respostas;
  final bool euBebi;
  final List<String> beberam;
  final Revelacao? revelacao;

  /// Casais em Jogo: quem chuta e de quem é a pergunta.
  final String? palpiteiro;
  final String? alvo;

  /// Casais em Jogo: o que o alvo julgou; nulo enquanto não julga.
  final bool? acertou;

  /// Quem é mais provável: votação no celular ou, sem ela, apontar no 3.
  final bool votacao;

  /// Carta de elogio (votação ou tribunal).
  final bool elogio;

  /// Correio: o bilhete de que quem está na foto mais gostou.
  final int? favorito;

  /// Quem encheu o cofrinho nesta carta: bebe agora.
  final List<String> bebemAgora;

  /// Quem quebrou a regra-relâmpago nesta carta.
  final List<String> vacilaram;

  /// Duelo: os dois da carta. Eles se apresentam e a turma vota.
  final List<String> duelistas;

  bool get duelo => duelistas.isNotEmpty;

  /// Imagem e Ação: os times (um só quando uma pessoa faz para todos).
  final List<TimeDaMimica> times;

  /// Imagem e Ação: o que o mímico pode dizer.
  final String? dica;
}

class Momento {
  const Momento({
    required this.id,
    required this.jogadorId,
    required this.nome,
    required this.rodada,
    required this.texto,
    required this.foto,
  });

  factory Momento.deJson(Map<String, dynamic> json, {String enderecoBase = ''}) => Momento(
        id: json['id'] as String,
        jogadorId: json['jogadorId'] as String,
        nome: json['nome'] as String,
        rodada: json['rodada'] as int,
        texto: json['texto'] as String,
        foto: '$enderecoBase${json['foto']}',
      );

  final String id;
  final String jogadorId;
  final String nome;
  final int rodada;
  final String texto;
  final String foto;
}

class Premio {
  const Premio({required this.emoji, required this.titulo, required this.descricao, required this.jogadores});

  factory Premio.deJson(Map<String, dynamic> json) => Premio(
        emoji: json['emoji'] as String,
        titulo: json['titulo'] as String,
        descricao: json['descricao'] as String,
        jogadores: List<String>.from(json['jogadores'] as List),
      );

  final String emoji;
  final String titulo;
  final String descricao;
  final List<String> jogadores;
}

class ResumoDaNoite {
  const ResumoDaNoite({required this.cartas, required this.minutos, required this.goles, required this.pontos});

  factory ResumoDaNoite.deJson(Map<String, dynamic> json) => ResumoDaNoite(
        cartas: json['cartas'] as int,
        minutos: json['minutos'] as int,
        goles: json['goles'] as int,
        pontos: json['pontos'] as int,
      );

  final int cartas;
  final int minutos;
  final int goles;
  final int pontos;
}

/// Como o jogo faz a regra-relâmpago acontecer a cada carta.
enum IscaDaRegra { nenhuma, entrevista, conversa, risada, mestre, piada }

/// A isca da carta: quem faz, para quem e o quê.
class DesafioDaRegra {
  const DesafioDaRegra({required this.tipo, required this.quem, required this.para, required this.textos});

  factory DesafioDaRegra.deJson(Map<String, dynamic> json) => DesafioDaRegra(
        tipo: _enum(IscaDaRegra.values, json['tipo']),
        quem: json['quem'] as String?,
        para: json['para'] as String?,
        textos: List<String>.from(json['textos'] as List),
      );

  final IscaDaRegra tipo;
  final String? quem;
  final String? para;
  final List<String> textos;
}

class RegraAtiva {
  const RegraAtiva(this.texto, this.rodadasRestantes, {this.alvo, this.desafio});

  factory RegraAtiva.deJson(Map<String, dynamic> json) => RegraAtiva(
        json['texto'] as String,
        json['rodadasRestantes'] as int,
        alvo: json['alvo'] as String?,
        desafio: json['desafio'] == null
            ? null
            : DesafioDaRegra.deJson(json['desafio'] as Map<String, dynamic>),
      );

  /// O {jogador} da regra, se ela é sobre alguém.
  final String? alvo;

  /// A isca desta carta.
  final DesafioDaRegra? desafio;

  final String texto;
  final int rodadasRestantes;
}

class VisaoDaSala {
  const VisaoDaSala({
    required this.codigo,
    required this.fase,
    required this.euId,
    required this.souAnfitriao,
    required this.configuracao,
    required this.jogadores,
    required this.rodada,
    required this.regra,
    this.momentos = const [],
    this.premios,
    this.resumo,
    this.esquenta,
    this.cartaTiradaPor,
  });

  factory VisaoDaSala.deJson(Map<String, dynamic> json, {String enderecoBase = ''}) => VisaoDaSala(
        codigo: json['codigo'] as String,
        fase: _enum(FaseDaSala.values, json['fase']),
        euId: json['euId'] as String,
        souAnfitriao: json['souAnfitriao'] as bool,
        configuracao: ConfiguracaoDoJogo.deJson(json['configuracao'] as Map<String, dynamic>),
        jogadores: [
          for (final jogador in json['jogadores'] as List) Jogador.deJson(jogador as Map<String, dynamic>, enderecoBase: enderecoBase),
        ],
        rodada: json['rodada'] == null ? null : Rodada.deJson(json['rodada'] as Map<String, dynamic>),
        regra: json['regra'] == null
            ? null
            : RegraAtiva.deJson(json['regra'] as Map<String, dynamic>),
        momentos: [
          for (final momento in (json['momentos'] as List?) ?? const [])
            Momento.deJson(momento as Map<String, dynamic>, enderecoBase: enderecoBase),
        ],
        premios: json['premios'] == null
            ? null
            : [for (final premio in json['premios'] as List) Premio.deJson(premio as Map<String, dynamic>)],
        resumo: json['resumo'] == null ? null : ResumoDaNoite.deJson(json['resumo'] as Map<String, dynamic>),
        esquenta: json['esquenta'] == null ? null : Esquenta.deJson(json['esquenta'] as Map<String, dynamic>),
        cartaTiradaPor: json['cartaTiradaPor'] as String?,
      );

  final String codigo;
  final FaseDaSala fase;
  final String euId;
  final bool souAnfitriao;
  final ConfiguracaoDoJogo configuracao;
  final List<Jogador> jogadores;
  final Rodada? rodada;
  final RegraAtiva? regra;
  final List<Momento> momentos;
  final List<Premio>? premios;
  final ResumoDaNoite? resumo;
  final Esquenta? esquenta;

  /// Quem tirou a carta anterior com o "Tira essa".
  final String? cartaTiradaPor;

  Jogador? jogador(String id) {
    for (final jogador in jogadores) {
      if (jogador.id == id) return jogador;
    }
    return null;
  }

  Jogador get eu => jogador(euId)!;

  Jogador? get anfitriao {
    for (final jogador in jogadores) {
      if (jogador.anfitriao) return jogador;
    }
    return null;
  }
}
