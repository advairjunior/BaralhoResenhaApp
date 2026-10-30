using System.Globalization;
using System.Security.Cryptography;
using System.Text.RegularExpressions;

namespace BaralhoResenhaApp.Api.Dominio;

public enum FaseDaSala
{
    Lobby,
    Carta,
    Revelada,

    /// <summary>Noite encerrada: prêmios e mural na tela.</summary>
    Fim
}

public sealed class Jogador
{
    public required Guid Id { get; init; }
    /// <summary>Troca quando a pessoa cai da sala e volta com o mesmo nome.</summary>
    public required string Token { get; set; }
    public required string Nome { get; init; }
    public bool SemAlcool { get; init; }
    public bool Anfitriao { get; set; }

    /// <summary>Última vez que o celular falou com a sala (ver <see cref="Sala.TempoSemSinal"/>).</summary>
    public DateTimeOffset VistoEm { get; set; }
    /// <summary>Vezes que a carta pegou a pessoa (o placar da noite).</summary>
    public int Pontos { get; set; }

    /// <summary>Pontos guardados até virar gole (ver <see cref="ConfiguracaoDoJogo.PontosPorGole"/>).</summary>
    public int Cofrinho { get; set; }

    /// <summary>Goles de verdade: um a cada cofrinho cheio.</summary>
    public int Goles { get; set; }
    public FotoDoJogador? Foto { get; set; }

    /// <summary>Cartas na manga, estilo Uno (até 3). Só o dono vê quais são.</summary>
    public List<CartaNaManga> Mao { get; } = [];

    /// <summary>Vezes que a carta chamou a pessoa pelo nome (rodízio do {jogador}).</summary>
    public int Chamadas { get; set; }

    /// <summary>Rodada em que ganhou a última carta na manga (rodízio do presente).</summary>
    public int UltimaCartaEm { get; set; }

    public EstatisticasDoJogador Estatisticas { get; } = new();
}

/// <summary>O que a noite rendeu para cada um; vira os Prêmios da Noite.</summary>
public sealed class EstatisticasDoJogador
{
    public int VotosRecebidos { get; set; }
    public int Historias { get; set; }
    public int JaFiz { get; set; }
    public int NuncaFiz { get; set; }

    /// <summary>Cartas que tirou do baralho com o "Tira essa".</summary>
    public int Tiradas { get; set; }

    /// <summary>Votos recebidos nas cartas de elogio.</summary>
    public int Elogios { get; set; }

    public int DuelosVencidos { get; set; }

    /// <summary>Imagem e Ação: vezes que fez a mímica (rodízio) e que o time acertou.</summary>
    public int Mimicas { get; set; }
    public int MimicasAcertadas { get; set; }

    public int CartasUsadas { get; set; }

    /// <summary>Vezes que quebrou uma regra-relâmpago.</summary>
    public int Vacilos { get; set; }

    /// <summary>Vezes que foi o impostor e a turma não pegou.</summary>
    public int Disfarces { get; set; }

    /// <summary>Duas verdades e uma mentira: vezes que ninguém achou a mentira.</summary>
    public int MentirasPerfeitas { get; set; }
}

public sealed class Rodada
{
    public required int Numero { get; init; }
    public required Carta Carta { get; init; }
    public required string Texto { get; init; }

    /// <summary>
    /// A "vez da regra": carta que só traz a pergunta da entrevista (ou a missão,
    /// a piada…) da regra-relâmpago valendo, intercalada com as cartas comuns.
    /// </summary>
    public bool VezDaRegra { get; init; }

    public Dictionary<Guid, string> Respostas { get; } = [];
    public HashSet<Guid> Beberam { get; } = [];

    /// <summary>Quem quebrou a regra-relâmpago nesta carta.</summary>
    public HashSet<Guid> Vacilaram { get; } = [];

    /// <summary>Pedra, papel e tesoura: as jogadas que empataram, na ordem.</summary>
    public List<string> Empates { get; } = [];

    /// <summary>Quando acaba o cronômetro da carta; nulo antes do "valendo".</summary>
    public DateTimeOffset? CronometroAte { get; set; }

    /// <summary>Mímica tem 60 s; outras cartas, o tempo que o texto pede ("em 5 segundos").</summary>
    public int? SegundosDoCronometro => Carta.Modo switch
    {
        ModoDeJogo.ImagemEAcao => 60,
        // Aponta no 3: a contagem é uma só, em todos os celulares.
        ModoDeJogo.MaisProvavel when !Votacao => 3,
        _ => Regex.Match(Texto, @"(\d+) segundos") is { Success: true } achado ? int.Parse(achado.Groups[1].Value) : null
    };

    /// <summary>O que esta carta fez com cada um; as cartas na manga mexem aqui.</summary>
    public Dictionary<Guid, ContaDaCarta> Contas { get; } = [];

    /// <summary>Quem encheu o cofrinho nesta carta.</summary>
    public HashSet<Guid> EncheuCofrinho { get; } = [];

    /// <summary>Quem bebe agora: encheu o cofrinho ou levou dose de verdade.</summary>
    public IReadOnlyList<Guid> BebemAgora => EncheuCofrinho
        .Union(Contas.Where(c => c.Value.Goles > 0 && !c.Value.SemAlcool).Select(c => c.Key))
        .ToList();

    /// <summary>Cartas na manga usadas nesta carta, na ordem.</summary>
    public List<UsoDeCarta> Usos { get; } = [];

    /// <summary>Quem já respondeu ou marcou "Pronto" (passar a carta sozinho).</summary>
    public HashSet<Guid> Prontos { get; } = [];

    /// <summary>Quem confirmou a pendência (bebi, contei, distribuí, li).</summary>
    public HashSet<Guid> Confirmaram { get; } = [];

    /// <summary>Quando a carta passa sozinha; nulo sem contagem.</summary>
    public DateTimeOffset? PassaEm { get; set; }

    /// <summary>Quem tocou em "Segura aí"; aí só quem criou a sala passa.</summary>
    public string? SeguradaPor { get; set; }

    /// <summary>Quem ganhou carta na manga nesta carta.</summary>
    public List<Guid> Ganharam { get; } = [];
    public Revelacao? Revelacao { get; set; }

    /// <summary>De quem é a carta: o réu do Tribunal, quem está na foto do Correio, a pessoa da vez.</summary>
    public Guid? Alvo { get; init; }

    /// <summary>Correio: o bilhete que quem está na foto mais curtiu.</summary>
    public int? Favorito { get; set; }

    /// <summary>
    /// Quem é mais provável: votação no celular (com suspense) ou, sem ela,
    /// a turma aponta no 3. Sorteado a cada carta, não preso à carta.
    /// </summary>
    public bool Votacao { get; init; }

    /// <summary>Imagem e Ação: os times da carta (um só quando uma pessoa faz para todos).</summary>
    public IReadOnlyList<TimeDaMimica> Times { get; init; } = [];

    /// <summary>
    /// Imagem e Ação: o que o mímico pode dizer, ex.: "Ação · 3 palavras".
    /// Impostor: o tema, que até o impostor sabe.
    /// </summary>
    public string? Dica
    {
        get
        {
            if (Carta.Categoria is not { } categoria) return null;
            if (Carta.Modo == ModoDeJogo.Impostor) return $"Tema: {categoria}";
            var palavras = Carta.Texto.Split(' ', StringSplitOptions.RemoveEmptyEntries).Length;
            return $"{categoria} · {palavras} {(palavras == 1 ? "palavra" : "palavras")}";
        }
    }

    /// <summary>Impostor: quem não recebe a palavra. Segredo até a revelação.</summary>
    public Guid? Impostor { get; init; }

    /// <summary>
    /// Na mímica, a palavra é segredo de quem faz até a revelação; no Impostor,
    /// só o impostor fica sem ela.
    /// </summary>
    public string TextoPara(Guid jogadorId, bool revelada)
    {
        if (Impostor == jogadorId && !revelada) return "🕵️ Você é o impostor!";
        return Times.Count == 0 || revelada || Times.Any(t => t.Mimico == jogadorId)
            ? Texto
            : "🎭 Adivinhe a mímica!";
    }

    /// <summary>Duelo: os dois da carta. Eles se apresentam e a turma vota.</summary>
    public IReadOnlyList<Guid> Duelistas { get; init; } = [];

    /// <summary>Roda de Música: a ordem em que cada um canta; o primeiro é o {jogador} da carta.</summary>
    public IReadOnlyList<Guid> Fila { get; init; } = [];

    /// <summary>Roda de Música: quem travou na sua vez (e levou o ponto).</summary>
    public HashSet<Guid> Travaram { get; } = [];

    /// <summary>A reação de cada um nesta carta (😂 🔥 💀 😱).</summary>
    public Dictionary<Guid, string> Reacoes { get; } = [];

    /// <summary>Termine a frase: o que cada um escreveu. O autor só sai se a frase vencer.</summary>
    public Dictionary<Guid, string> Frases { get; } = [];

    /// <summary>Termine a frase: de quem é cada frase, na ordem da votação; nulo enquanto escrevem.</summary>
    public List<Guid>? OrdemDasFrases { get; set; }

    public bool Escrevendo => Carta.Modo == ModoDeJogo.TermineAFrase && OrdemDasFrases is null;

    /// <summary>Duas verdades e uma mentira: as três frases da pessoa da vez; vazio até ela escrever.</summary>
    public IReadOnlyList<string> Afirmacoes { get; set; } = [];

    /// <summary>Duas verdades e uma mentira: qual das três é a mentira. Segredo até a revelação.</summary>
    public int? Mentira { get; set; }

    /// <summary>Batata quente: quem está com a batata agora.</summary>
    public Guid? ComABatata { get; set; }

    /// <summary>Batata quente: quando o pavio acaba. Segredo do servidor: nenhum celular recebe.</summary>
    public DateTimeOffset? EstouraEm { get; init; }

    /// <summary>Sala sem álcool: a prenda de cada um que encheu o cofrinho (ou levou dose).</summary>
    public Dictionary<Guid, List<string>> Prendas { get; } = [];

    /// <summary>Sala sem álcool: a prenda que quem a turma elogiou passa para alguém.</summary>
    public string? PrendaDoElogio { get; set; }

    public bool PedeResposta =>
        Carta.Modo is ModoDeJogo.EuNunca or ModoDeJogo.Tribunal or ModoDeJogo.Correio
            or ModoDeJogo.Jurados or ModoDeJogo.Impostor or ModoDeJogo.TermineAFrase or ModoDeJogo.DuasVerdades
            or ModoDeJogo.ChutaAi ||
        (Carta.Modo == ModoDeJogo.MaisProvavel && Votacao);
}

public sealed record VotosRecebidos(Guid JogadorId, int Votos);

/// <param name="Perderam">Quem bebe (ou ganha ponto, para quem joga sem álcool).</param>
/// <param name="ContaAHistoria">Só uma pessoa já fez: ela conta a história.</param>
public sealed record Revelacao(
    IReadOnlyList<Guid> JaFizeram,
    IReadOnlyList<Guid> NuncaFizeram,
    IReadOnlyList<VotosRecebidos> Votos,
    IReadOnlyList<Guid> Perderam,
    Guid? ContaAHistoria,
    bool Elogio = false)
{
    /// <summary>Quem é mais provável: os mais votados, bebam (normal) ou não (elogio).</summary>
    public IReadOnlyList<Guid> Escolhidos { get; init; } = [];

    /// <summary>Eu Nunca: a maioria já fez, então quem leva é quem nunca fez.</summary>
    public bool MinoriaLeva { get; init; }

    /// <summary>"Conta essa": quem já fez, na ordem em que cada um conta a sua.</summary>
    public IReadOnlyList<Guid> Contadores { get; init; } = [];

    /// <summary>Imagem e Ação: o time que acertou; nulo quando ninguém acertou.</summary>
    public int? TimeVencedor { get; init; }

    /// <summary>Pedra, papel e tesoura: o que cada um dos dois jogou.</summary>
    public IReadOnlyDictionary<Guid, string> Jogadas { get; init; } = new Dictionary<Guid, string>();

    /// <summary>Correio: os bilhetes, embaralhados e sem autor.</summary>
    public IReadOnlyList<string> Bilhetes { get; init; } = [];

    /// <summary>Jurados: a média das estrelas, com uma casa.</summary>
    public double? Media { get; init; }

    /// <summary>Jurados: as notas, em ordem e sem dizer quem deu qual.</summary>
    public IReadOnlyList<int> Notas { get; init; } = [];

    /// <summary>Impostor: quem era, e se a turma pegou (sozinho no topo dos votos).</summary>
    public Guid? Impostor { get; init; }
    public bool Pegaram { get; init; }

    /// <summary>Termine a frase: as frases, da mais votada para a menos; autor só nas vencedoras.</summary>
    public IReadOnlyList<FraseRevelada> Frases { get; init; } = [];

    /// <summary>Duas verdades e uma mentira: qual era, quantos votos cada frase teve e quem achou.</summary>
    public int? Mentira { get; init; }
    public IReadOnlyList<int> VotosNasAfirmacoes { get; init; } = [];
    public IReadOnlyList<Guid> Acertaram { get; init; } = [];

    /// <summary>Chuta aí: o número certo e os chutes, do mais perto para o mais longe.</summary>
    public decimal? RespostaCerta { get; init; }
    public IReadOnlyList<ChuteRevelado> Chutes { get; init; } = [];
}

public sealed record FraseRevelada(string Texto, int Votos, Guid? Autor);

public sealed record ChuteRevelado(Guid JogadorId, decimal Valor);

/// <param name="Quem">Quem faz: entrevista, missão, pergunta ou piada.</param>
/// <param name="Para">Para quem: quem responde ou tem que segurar a risada.</param>
public sealed record DesafioDaRegra(IscaDaRegra Tipo, Guid? Quem, Guid? Para, IReadOnlyList<string> Textos);

public sealed record RegraAtiva(string Texto, int RodadasRestantes)
{
    /// <summary>O {jogador} da regra, se ela é sobre alguém.</summary>
    public Guid? Alvo { get; init; }

    /// <summary>Entrevista: quem faz as perguntas, o mesmo do começo ao fim.</summary>
    public Guid? Entrevistador { get; init; }
    public IscaDaRegra Isca { get; init; }

    /// <summary>A isca desta carta; muda a cada carta enquanto a regra vale.</summary>
    public DesafioDaRegra? Desafio { get; init; }

    /// <summary>Quem pode ser marcado como vacilão: na regra de uma pessoa, só ela.</summary>
    public IReadOnlyList<Guid> PodemVacilar { get; init; } = [];
}

/// <summary>
/// Uma noite de jogo. Todo acesso passa pelo trinco da própria sala, porque
/// vários celulares respondem ao mesmo tempo.
/// </summary>
public sealed partial class Sala
{
    public const string RespostaJa = "ja";
    public const string RespostaNunca = "nunca";
    public const string RespostaSim = "sim";
    public const string RespostaNao = "nao";
    internal const int RodadasDaRegra = 3;
    internal const int TamanhoMaximoDoNome = 20;

    /// <summary>
    /// Sem notícia do celular por esse tempo, quem entra com o mesmo nome volta a ser aquela
    /// pessoa. O celular consulta a sala a cada 6 s, então quem está jogando nunca passa disso.
    /// </summary>
    public static readonly TimeSpan TempoParaVoltar = TimeSpan.FromSeconds(20);

    /// <summary>
    /// Sem notícia do celular por esse tempo, a pessoa caiu: a mesa para de esperar por ela.
    /// É mais que o <see cref="TempoParaVoltar"/> porque tela bloqueada por um minutinho é normal.
    /// </summary>
    public static readonly TimeSpan TempoParaCair = TimeSpan.FromSeconds(60);

    public const string MensagemDeNomeEmUso =
        "Já tem alguém com esse nome jogando agora. Se for você em outro celular, feche lá e tente de novo em 20 segundos.";

    /// <summary>Parte das cartas de Quem é mais provável jogadas com votação no celular.</summary>
    internal double ChanceDeVotacao { get; set; } = 0.6;

    private readonly object _trinco = new();
    private readonly Baralho _baralho;
    private readonly Random _sorteio;
    private readonly List<Jogador> _jogadores = [];
    private readonly HashSet<string> _usadas = [];
    private readonly List<ModoDeJogo> _ultimosModos = [];
    private readonly TimeProvider _relogio;

    public Sala(string codigo, Baralho baralho, Random? sorteio = null, TimeProvider? relogio = null)
    {
        Codigo = codigo;
        _baralho = baralho;
        _sorteio = sorteio ?? Random.Shared;
        _relogio = relogio ?? TimeProvider.System;
        UltimaAtividade = _relogio.GetUtcNow();
    }

    public string Codigo { get; }
    public FaseDaSala Fase { get; private set; } = FaseDaSala.Lobby;
    public ConfiguracaoDoJogo Configuracao { get; private set; } = ConfiguracaoDoJogo.Padrao;
    public Rodada? Rodada { get; private set; }
    public RegraAtiva? Regra { get; private set; }
    public DateTimeOffset? ComecouEm { get; private set; }
    public DateTimeOffset? TerminouEm { get; private set; }
    public DateTimeOffset UltimaAtividade { get; private set; }
    public IReadOnlyList<Jogador> Jogadores
    {
        get { lock (_trinco) return _jogadores.ToList(); }
    }

    public Jogador Entrar(string nome, bool semAlcool)
    {
        var nomeLimpo = (nome ?? string.Empty).Trim();
        if (nomeLimpo.Length == 0)
            throw new AcaoNaoPermitidaException("Informe seu nome.");
        if (nomeLimpo.Length > TamanhoMaximoDoNome)
            throw new AcaoNaoPermitidaException($"Use um nome de até {TamanhoMaximoDoNome} letras.");

        lock (_trinco)
        {
            var agora = _relogio.GetUtcNow();
            var mesmoNome = _jogadores.FirstOrDefault(j => MesmoNome(j.Nome, nomeLimpo));
            if (mesmoNome is not null)
            {
                if (agora - mesmoNome.VistoEm < TempoParaVoltar)
                    throw new AcaoNaoPermitidaException(MensagemDeNomeEmUso);
                // Caiu da sala e voltou: segue a mesma pessoa, e o celular antigo deixa de valer.
                mesmoNome.Token = NovoToken();
                mesmoNome.VistoEm = agora;
                Tocar();
                return mesmoNome;
            }
            var jogador = new Jogador
            {
                Id = Guid.NewGuid(),
                Token = NovoToken(),
                Nome = nomeLimpo,
                SemAlcool = semAlcool,
                Anfitriao = _jogadores.Count == 0,
                VistoEm = agora,
                // Quem chega no meio entra na volta atual, sem ser chamado várias vezes para compensar.
                Chamadas = _jogadores.Count == 0 ? 0 : _jogadores.Min(j => j.Chamadas)
            };
            _jogadores.Add(jogador);
            Tocar();
            return jogador;
        }
    }

    public void Sair(string token)
    {
        lock (_trinco) Remover(Reconhecer(token));
    }

    /// <summary>Quem foi embora de vez: só quem criou a sala tira, e só quem já caiu.</summary>
    public void TirarDaSala(string token, Guid jogadorId)
    {
        lock (_trinco)
        {
            ExigirAnfitriao(token, "Só quem criou a sala tira alguém da sala.");
            var jogador = _jogadores.FirstOrDefault(j => j.Id == jogadorId)
                ?? throw new AcaoNaoPermitidaException("Essa pessoa já saiu da sala.");
            if (Conectado(jogador))
                throw new AcaoNaoPermitidaException($"{jogador.Nome} ainda está conectado(a).");
            Remover(jogador);
        }
    }

    private void Remover(Jogador jogador)
    {
        _jogadores.Remove(jogador);
        Rodada?.Respostas.Remove(jogador.Id);
        if (jogador.Anfitriao && _jogadores.Count > 0)
            _jogadores[0].Anfitriao = true;
        RevelarSeTodosResponderam();
        Tocar();
    }

    /// <summary>Quem a mesa não espera mais: está sem sinal há <see cref="TempoParaCair"/>.</summary>
    private readonly HashSet<Guid> _caidos = [];

    internal bool Conectado(Jogador jogador) => _relogio.GetUtcNow() - jogador.VistoEm < TempoParaCair;

    /// <summary>Quem a carta espera: quem está conectado.</summary>
    private IEnumerable<Jogador> NaMesa => _jogadores.Where(Conectado);

    /// <summary>
    /// Chamado a cada consulta dos celulares: se alguém caiu ou voltou, a carta é
    /// conferida de novo (pode revelar ou passar sem essa pessoa). Verdadeiro quando
    /// mudou alguma coisa e a sala precisa avisar a turma.
    /// </summary>
    public bool ConferirQuemCaiu()
    {
        lock (_trinco)
        {
            var caidos = _jogadores.Where(j => !Conectado(j)).Select(j => j.Id).ToHashSet();
            if (caidos.SetEquals(_caidos)) return false;
            _caidos.Clear();
            _caidos.UnionWith(caidos);
            RevelarSeTodosResponderam();
            Tocar();
            return true;
        }
    }

    public bool Vazia
    {
        get { lock (_trinco) return _jogadores.Count == 0; }
    }

    public void Configurar(string token, ConfiguracaoDoJogo configuracao)
    {
        lock (_trinco)
        {
            ExigirAnfitriao(token);
            if (configuracao.Modos.Count == 0)
                throw new AcaoNaoPermitidaException("Escolha pelo menos um modo de jogo.");
            if (!Enum.IsDefined(configuracao.Nivel))
                throw new AcaoNaoPermitidaException("Nível de cartas desconhecido.");
            if (configuracao.Cofrinho is < 1 or > ConfiguracaoDoJogo.CofrinhoMaximo)
                throw new AcaoNaoPermitidaException($"O cofrinho vai de 1 a {ConfiguracaoDoJogo.CofrinhoMaximo} pontos.");
            if (configuracao.Muito?.Intersect(configuracao.Pouco ?? []).Any() == true)
                throw new AcaoNaoPermitidaException("Um jogo não fica em Pouco e Muito ao mesmo tempo.");
            Configuracao = configuracao with
            {
                Modos = configuracao.Modos.Distinct().ToList(),
                Muito = configuracao.Muito?.Distinct().ToList() ?? [],
                Pouco = configuracao.Pouco?.Distinct().ToList() ?? []
            };
            Tocar();
        }
    }

    /// <param name="vistas">
    /// Cartas que já saíram nas noites anteriores (o celular de quem criou a sala
    /// lembra): vão para o fim do monte, e a noite não começa sempre pelas mesmas.
    /// </param>
    public void Comecar(string token, IEnumerable<string>? vistas = null)
    {
        lock (_trinco)
        {
            ExigirAnfitriao(token);
            if (Fase != FaseDaSala.Lobby) return;
            if (_jogadores.Count < 2)
                throw new AcaoNaoPermitidaException("Chame pelo menos mais uma pessoa para começar.");
            LembrarVistasDaTurma(vistas);
            ComecouEm = _relogio.GetUtcNow();
            foreach (var jogador in _jogadores) DarCarta(jogador);
            Distribuir();
            Tocar();
        }
    }

    /// <summary>
    /// Cada celular que entra manda as cartas que já viu em outras noites: se
    /// qualquer um da turma já viu, a carta vai para o fim do monte, mesmo que
    /// outra pessoa crie a sala. Depois de começar, não muda mais nada.
    /// </summary>
    public void LembrarVistas(string token, IEnumerable<string>? vistas)
    {
        lock (_trinco)
        {
            Reconhecer(token);
            if (Fase != FaseDaSala.Lobby) return;
            LembrarVistasDaTurma(vistas);
        }
    }

    private void LembrarVistasDaTurma(IEnumerable<string>? vistas)
    {
        var existentes = _baralho.Cartas.Select(carta => carta.Id).ToHashSet();
        _usadas.UnionWith((vistas ?? []).Where(existentes.Contains));
    }

    public void Responder(string token, int numeroDaRodada, string resposta)
    {
        lock (_trinco)
        {
            var jogador = Reconhecer(token);
            if (!RodadaEmAndamento(numeroDaRodada) || Fase != FaseDaSala.Carta) return;
            var rodada = Rodada!;
            if (!rodada.PedeResposta)
                throw new AcaoNaoPermitidaException("Esta carta não pede resposta.");
            if (rodada.Carta.Modo == ModoDeJogo.Tribunal)
            {
                if (jogador.Id == rodada.Alvo)
                    throw new AcaoNaoPermitidaException("Essa é sobre você: espera o veredito da turma.");
                if (resposta is not (RespostaSim or RespostaNao))
                    throw new AcaoNaoPermitidaException("Vote sim ou não.");
            }

            if (rodada.Carta.Modo == ModoDeJogo.Jurados)
            {
                if (jogador.Id == rodada.Alvo)
                    throw new AcaoNaoPermitidaException("Essa é sobre você: espera a nota dos jurados.");
                if (resposta is not ("1" or "2" or "3" or "4" or "5"))
                    throw new AcaoNaoPermitidaException("Dê uma nota de 1 a 5 estrelas.");
            }

            if (rodada.Carta.Modo == ModoDeJogo.Correio) resposta = ValidarBilhete(rodada, jogador, resposta);
            if (rodada.Escrevendo)
            {
                EscreverFrase(rodada, jogador, resposta);
                Tocar();
                return;
            }
            if (rodada.Carta.Modo == ModoDeJogo.TermineAFrase) ValidarVotoNaFrase(rodada, jogador, resposta);
            if (rodada.Carta.Modo == ModoDeJogo.DuasVerdades) ValidarVotoNaMentira(rodada, jogador, resposta);
            if (rodada.Carta.Modo == ModoDeJogo.Impostor) ValidarVotoNoImpostor(jogador, resposta);
            if (rodada.Carta.Modo == ModoDeJogo.ChutaAi) resposta = ValidarChute(resposta);

            if (rodada.Carta.Modo == ModoDeJogo.EuNunca && resposta is not (RespostaJa or RespostaNunca))
                throw new AcaoNaoPermitidaException("Responda se já fez ou se nunca fez.");
            if (rodada.Carta.Jokenpo) resposta = ValidarJogada(rodada, jogador, resposta);
            else if (rodada.Duelistas.Count > 0)
            {
                if (rodada.Duelistas.Contains(jogador.Id))
                    throw new AcaoNaoPermitidaException("Você está no duelo: quem decide é a turma.");
                if (!(Guid.TryParse(resposta, out var duelista) && rodada.Duelistas.Contains(duelista)))
                    throw new AcaoNaoPermitidaException("Vote em um dos dois do duelo.");
            }
            if (rodada.Carta.Modo == ModoDeJogo.MaisProvavel && !rodada.Carta.Jokenpo &&
                !(Guid.TryParse(resposta, out var votado) && _jogadores.Any(j => j.Id == votado)))
                throw new AcaoNaoPermitidaException("Vote em alguém da sala.");

            rodada.Respostas[jogador.Id] = resposta;
            RevelarSeTodosResponderam();
            Tocar();
        }
    }

    /// <summary>Revela sem esperar quem largou o celular na mesa.</summary>
    public void Revelar(string token, int numeroDaRodada)
    {
        lock (_trinco)
        {
            ExigirAnfitriao(token, SoQuemCriouPuxaCarta);
            if (!RodadaEmAndamento(numeroDaRodada) || Fase != FaseDaSala.Carta || !Rodada!.PedeResposta)
                return;
            if (Rodada.Carta.Jokenpo)
                throw new AcaoNaoPermitidaException("Os dois do duelo precisam jogar.");
            if (Rodada.Carta.Modo == ModoDeJogo.DuasVerdades) ExigirAfirmacoes(Rodada);
            // Termine a frase: "revelar" durante a escrita passa para a votação.
            if (Rodada.Escrevendo)
            {
                if (Rodada.Frases.Count < 2)
                    throw new AcaoNaoPermitidaException(
                        "Espere pelo menos 2 frases: com uma só, todo mundo sabe quem escreveu.");
                ComecarVotacaoDasFrases(Rodada);
                Tocar();
                return;
            }
            if (Rodada.Respostas.Count == 0)
                throw new AcaoNaoPermitidaException("Ninguém respondeu ainda.");
            if (Rodada.Carta.Modo == ModoDeJogo.Correio && Rodada.Respostas.Count < 2)
                throw new AcaoNaoPermitidaException(
                    "Espere pelo menos 2 bilhetes: com um só, todo mundo sabe quem escreveu.");
            AplicarRevelacao();
            Tocar();
        }
    }

    /// <summary>Vale para seguir depois da revelação e para pular uma carta.</summary>
    public void Proxima(string token, int numeroDaRodada)
    {
        lock (_trinco)
        {
            ExigirAnfitriao(token, SoQuemCriouPuxaCarta);
            if (Fase is FaseDaSala.Lobby or FaseDaSala.Fim || !RodadaEmAndamento(numeroDaRodada)) return;
            AvancarCarta();
            Tocar();
        }
    }

    /// <summary>"Me pegou!" nas cartas de Beba se: marca e desmarca o próprio gole.</summary>
    public void AlternarBebi(string token, int numeroDaRodada)
    {
        lock (_trinco)
        {
            var jogador = Reconhecer(token);
            if (!RodadaEmAndamento(numeroDaRodada)) return;
            if (Rodada!.Carta.Modo != ModoDeJogo.BebaSe)
                throw new AcaoNaoPermitidaException("Só vale nas cartas de Beba se.");
            if (Rodada.Beberam.Remove(jogador.Id)) Perdoar(jogador);
            else
            {
                Rodada.Beberam.Add(jogador.Id);
                Punir(jogador);
            }
            // Respondeu (pegou ou desmarcou): conta para passar sozinho.
            Rodada.Prontos.Add(jogador.Id);
            Tocar();
        }
    }

    /// <summary>
    /// Apontar no 3: quem criou a sala toca em quem a turma apontou (empate,
    /// toca em mais de um). Tocar de novo desfaz.
    /// </summary>
    public void MarcarApontado(string token, int numeroDaRodada, Guid apontadoId)
    {
        lock (_trinco)
        {
            ExigirAnfitriao(token, "Quem marca o apontado é quem criou a sala.");
            if (!RodadaEmAndamento(numeroDaRodada)) return;
            if (Rodada!.Carta.Modo != ModoDeJogo.MaisProvavel || Rodada.Votacao)
                throw new AcaoNaoPermitidaException("Só vale quando a turma aponta no 3.");
            var apontado = _jogadores.FirstOrDefault(j => j.Id == apontadoId)
                ?? throw new AcaoNaoPermitidaException("Essa pessoa não está na sala.");
            if (Rodada.Beberam.Remove(apontado.Id))
            {
                Despegar(apontado);
                apontado.Estatisticas.VotosRecebidos--;
            }
            else
            {
                Rodada.Beberam.Add(apontado.Id);
                Pegar(apontado);
                apontado.Estatisticas.VotosRecebidos++;
            }
            Tocar();
        }
    }

    public void DefinirFoto(string token, byte[] conteudo)
    {
        var foto = FotoDoJogador.Criar(conteudo);
        lock (_trinco)
        {
            Reconhecer(token).Foto = foto;
            Tocar();
        }
    }

    /// <summary>Selfie ou foto do mural pelo id, que só quem está na sala recebe.</summary>
    public FotoDoJogador? Foto(string fotoId)
    {
        lock (_trinco)
            return _jogadores.Select(j => j.Foto)
                .Concat(_momentos.Select(m => m.Foto))
                .FirstOrDefault(f => f?.Id == fotoId);
    }

    public VisaoDaSala Visao(string token)
    {
        lock (_trinco)
        {
            var eu = Reconhecer(token);
            return VisaoDaSala.Montar(this, eu, _jogadores);
        }
    }

    internal Jogador Reconhecer(string token)
    {
        lock (_trinco)
        {
            var jogador = _jogadores.FirstOrDefault(j => j.Token == token)
                ?? throw new JogadorNaoReconhecidoException();
            // Toda consulta e toda ação contam como "estou aqui".
            jogador.VistoEm = _relogio.GetUtcNow();
            return jogador;
        }
    }

    private static string NovoToken() =>
        Convert.ToBase64String(RandomNumberGenerator.GetBytes(24)).Replace('+', '-').Replace('/', '_');

    /// <summary>"Fabrício" e "fabricio" são a mesma pessoa: o corretor do celular não cria outra.</summary>
    private static bool MesmoNome(string um, string outro) =>
        string.Compare(um, outro, CultureInfo.InvariantCulture,
            CompareOptions.IgnoreCase | CompareOptions.IgnoreNonSpace) == 0;

    private Jogador ExigirAnfitriao(string token, string mensagem = "Só quem criou a sala pode fazer isso.")
    {
        var jogador = Reconhecer(token);
        if (!jogador.Anfitriao) throw new AcaoNaoPermitidaException(mensagem);
        return jogador;
    }

    /// <summary>Passar carta é com quem criou a sala: com todo mundo podendo, vira bagunça.</summary>
    internal const string SoQuemCriouPuxaCarta = "Só quem criou a sala puxa a próxima carta.";

    /// <summary>
    /// A regra-relâmpago vale por algumas cartas. Com isca, conta as vezes da
    /// regra (pergunta, missão…); sem isca, cada carta comum que passa gasta uma.
    /// Chamada ao sair da carta atual.
    /// </summary>
    private void GastarUmaCartaDaRegra()
    {
        if (Regra is null || Rodada is null) return;
        var gasta = TemVez(Regra) ? Rodada.VezDaRegra : Rodada.Carta.Modo != ModoDeJogo.RegraRelampago;
        if (!gasta) return;
        Regra = Regra.RodadasRestantes <= 1 ? null : Regra with { RodadasRestantes = Regra.RodadasRestantes - 1 };
    }

    private bool RodadaEmAndamento(int numero) => Rodada is not null && Rodada.Numero == numero;

    private void Distribuir()
    {
        if (DistribuirVezDaRegra()) return;
        // Esquenta sozinho: o nível desta carta depende de quantas já saíram.
        var indice = Rodada?.Numero ?? 0;
        var configuracao = Configuracao with { Nivel = Configuracao.NivelNaCarta(indice) };
        CartaTiradaPor = null;
        var carta = _baralho.Sortear(
                configuracao, _usadas, _jogadores.Count, Regra is not null, _sorteio,
                _ultimosModos, _tiradas)
            ?? throw new AcaoNaoPermitidaException("Nenhuma carta combina com essa configuração.");
        _usadas.Add(carta.Id);
        _ultimosModos.Add(carta.Modo);
        if (_ultimosModos.Count > Baralho.MaximoSeguidas) _ultimosModos.RemoveAt(0);
        // Duelos usam duas pessoas diferentes: {jogador} e {jogador2}. Rodízio: sai quem
        // foi chamado menos vezes, e a sorte só desempata; ninguém fica esquecido na noite.
        // Quem caiu não é chamado (a carta ficaria esperando por ele) até voltar.
        var naMesa = NaMesa.ToList();
        var sorteados = (naMesa.Count > 0 ? naMesa : _jogadores)
            .OrderBy(j => j.Chamadas).ThenBy(_ => _sorteio.Next()).Take(2).ToList();
        if (carta.Texto.Contains("{jogador}") ||
            carta.Modo is ModoDeJogo.Tribunal or ModoDeJogo.Correio or ModoDeJogo.Jurados or ModoDeJogo.Musica
                or ModoDeJogo.DuasVerdades or ModoDeJogo.BatataQuente)
            sorteados[0].Chamadas++;
        if (carta.Texto.Contains("{jogador2}") && sorteados.Count == 2) sorteados[1].Chamadas++;
        var texto = carta.Texto
            .Replace("{jogador2}", sorteados[^1].Nome)
            .Replace("{jogador}", sorteados[0].Nome);
        if (Configuracao.SemAlcool) texto = Baralho.SemBebida(texto);
        var impostor = carta.Modo == ModoDeJogo.Impostor ? _jogadores[_sorteio.Next(_jogadores.Count)] : null;
        Rodada = new Rodada
        {
            Numero = (Rodada?.Numero ?? 0) + 1,
            Carta = carta,
            Texto = texto,
            // No tribunal, o réu é o {jogador} da carta; no correio, quem está na foto.
            Alvo = carta.Modo is ModoDeJogo.Tribunal or ModoDeJogo.Correio or ModoDeJogo.Jurados or ModoDeJogo.DuasVerdades
                ? sorteados[0].Id
                : null,
            // Elogio e duelo são sempre no celular: a graça é a foto de quem a turma escolheu.
            Votacao = carta.Modo == ModoDeJogo.MaisProvavel &&
                (carta.Elogio || carta.Duelo || _sorteio.NextDouble() < ChanceDeVotacao),
            Duelistas = carta.Duelo && sorteados.Count == 2 ? [sorteados[0].Id, sorteados[1].Id] : [],
            Times = carta.Modo == ModoDeJogo.ImagemEAcao ? MontarTimes() : [],
            Fila = carta.Modo switch
            {
                // Batata quente: a mesma roda, começando por quem a carta chamou.
                ModoDeJogo.Musica or ModoDeJogo.BatataQuente =>
                    [sorteados[0].Id, .. _jogadores.Where(j => j.Id != sorteados[0].Id).OrderBy(_ => _sorteio.Next()).Select(j => j.Id)],
                ModoDeJogo.Impostor => FilaDasPistas(impostor!),
                _ => []
            },
            Impostor = impostor?.Id,
            ComABatata = carta.Modo == ModoDeJogo.BatataQuente ? sorteados[0].Id : null,
            EstouraEm = carta.Modo == ModoDeJogo.BatataQuente ? AcenderOPavio() : null
        };
        PresenteDaRodada();
        if (carta.Modo == ModoDeJogo.RegraRelampago)
            ComecarRegra(carta, texto, carta.Texto.Contains("{jogador}") ? sorteados[0] : null);
        // Nas cartas comuns a regra só lembra; a pergunta vem na vez da regra.
        else if (Regra is not null)
            Regra = Regra with { Desafio = null };
        Fase = FaseDaSala.Carta;
    }

    private void RevelarSeTodosResponderam()
    {
        if (Fase != FaseDaSala.Carta || Rodada is not { PedeResposta: true } rodada) return;
        if (rodada.Escrevendo)
        {
            ComecarVotacaoSeTodosEscreveram(rodada);
            return;
        }
        if (rodada.Carta.Jokenpo)
        {
            ResolverJokenpo(rodada);
            return;
        }
        var todosResponderam = rodada.Carta.Modo switch
        {
            ModoDeJogo.Tribunal or ModoDeJogo.Correio or ModoDeJogo.Jurados or ModoDeJogo.DuasVerdades =>
                rodada.Respostas.Count > 0 &&
                NaMesa.Where(j => j.Id != rodada.Alvo).All(j => rodada.Respostas.ContainsKey(j.Id)),
            ModoDeJogo.MaisProvavel when rodada.Duelistas.Count > 0 => rodada.Respostas.Count > 0 &&
                NaMesa.Where(j => !rodada.Duelistas.Contains(j.Id)).All(j => rodada.Respostas.ContainsKey(j.Id)),
            _ => rodada.Respostas.Count > 0 && NaMesa.All(j => rodada.Respostas.ContainsKey(j.Id))
        };
        if (todosResponderam) AplicarRevelacao();
    }

    private void AplicarRevelacao()
    {
        var rodada = Rodada!;
        var presentes = _jogadores.Select(j => j.Id).ToHashSet();
        var respostas = rodada.Respostas.Where(r => presentes.Contains(r.Key)).ToList();
        Revelacao revelacao;

        if (rodada.Duelistas.Count > 0)
        {
            revelacao = RevelarDuelo(rodada, respostas);
        }
        else if (rodada.Carta.Modo == ModoDeJogo.Correio)
        {
            revelacao = RevelarBilhetes(rodada, respostas);
        }
        else if (rodada.Carta.Modo == ModoDeJogo.Jurados)
        {
            revelacao = RevelarJurados(rodada, respostas);
        }
        else if (rodada.Carta.Modo == ModoDeJogo.Impostor)
        {
            revelacao = RevelarImpostor(rodada, respostas);
        }
        else if (rodada.Carta.Modo == ModoDeJogo.TermineAFrase)
        {
            revelacao = RevelarFrases(rodada, respostas);
        }
        else if (rodada.Carta.Modo == ModoDeJogo.DuasVerdades)
        {
            revelacao = RevelarMentira(rodada, respostas);
        }
        else if (rodada.Carta.Modo == ModoDeJogo.ChutaAi)
        {
            revelacao = RevelarChutes(rodada, respostas);
        }
        else if (rodada.Carta.Modo == ModoDeJogo.BatataQuente)
        {
            // Estourou: quem estava com a batata leva (se ainda está na sala).
            revelacao = new Revelacao([], [], [],
                _jogadores.Where(j => j.Id == rodada.ComABatata).Select(j => j.Id).ToList(), null);
        }
        else if (rodada.Carta.Modo == ModoDeJogo.Tribunal)
        {
            // O "sim" vence no empate: na zoeira, condena (a turma não salva ninguém
            // em cima do muro); no elogio, elogia. Na carta de elogio, a resposta
            // ruim é o "não": maioria não condena o réu.
            var sim = respostas.Where(r => r.Value == RespostaSim).Select(r => r.Key).ToList();
            var nao = respostas.Where(r => r.Value == RespostaNao).Select(r => r.Key).ToList();
            var reu = _jogadores.FirstOrDefault(j => j.Id == rodada.Alvo);
            var simVence = reu is not null && sim.Count > 0 && sim.Count >= nao.Count;
            var elogio = rodada.Carta.Elogio;
            var condenado = elogio ? reu is not null && nao.Count > sim.Count : simVence;
            revelacao = new Revelacao(sim, nao, [], condenado ? [reu!.Id] : [], null, Elogio: elogio)
            {
                Escolhidos = simVence ? [reu!.Id] : []
            };
            if (reu is not null && simVence && elogio) DarCarta(reu);
            if (reu is not null)
            {
                if (elogio) reu.Estatisticas.Elogios += sim.Count;
                if (condenado) reu.Estatisticas.VotosRecebidos += elogio ? nao.Count : sim.Count;
            }
        }
        else if (rodada.Carta.Modo == ModoDeJogo.EuNunca)
        {
            var ja = respostas.Where(r => r.Value == RespostaJa).Select(r => r.Key).ToList();
            var nunca = respostas.Where(r => r.Value == RespostaNunca).Select(r => r.Key).ToList();
            // Virada: todo mundo já fez, ninguém leva; a maioria já fez, leva quem nunca fez.
            var minoriaLeva = nunca.Count > 0 && ja.Count > nunca.Count;
            IReadOnlyList<Guid> perderam = nunca.Count == 0 ? [] : minoriaLeva ? nunca : ja;
            // "Conta essa": todo mundo que já fez conta a sua, numa ordem sorteada.
            var contaEssa = rodada.Carta.Conta;
            revelacao = new Revelacao(ja, nunca, [], perderam,
                !contaEssa && ja.Count == 1 && respostas.Count >= 2 ? ja[0] : null)
            {
                MinoriaLeva = minoriaLeva,
                Contadores = contaEssa ? ja.OrderBy(_ => _sorteio.Next()).ToList() : [],
            };
            foreach (var jogador in _jogadores)
            {
                if (ja.Contains(jogador.Id)) jogador.Estatisticas.JaFiz++;
                if (nunca.Contains(jogador.Id)) jogador.Estatisticas.NuncaFiz++;
                if (revelacao.ContaAHistoria == jogador.Id || revelacao.Contadores.Contains(jogador.Id))
                    jogador.Estatisticas.Historias++;
            }
        }
        else
        {
            var votos = respostas
                .GroupBy(r => Guid.Parse(r.Value))
                .Where(grupo => presentes.Contains(grupo.Key))
                .Select(grupo => new VotosRecebidos(grupo.Key, grupo.Count()))
                .OrderByDescending(v => v.Votos)
                .ToList();
            var maximo = votos.Count > 0 ? votos[0].Votos : 0;
            var maisVotados = votos.Where(v => v.Votos == maximo).Select(v => v.JogadorId).ToList();
            // No elogio, o mais votado não bebe: ganha um brinde e distribui goles.
            var elogio = rodada.Carta.Elogio;
            revelacao = new Revelacao([], [], votos, elogio ? [] : maisVotados, null, Elogio: elogio)
            {
                Escolhidos = maisVotados
            };
            if (elogio)
                foreach (var escolhido in _jogadores.Where(j => maisVotados.Contains(j.Id))) DarCarta(escolhido);
            foreach (var voto in votos)
            {
                var estatisticas = _jogadores.First(j => j.Id == voto.JogadorId).Estatisticas;
                if (elogio) estatisticas.Elogios += voto.Votos;
                else estatisticas.VotosRecebidos += voto.Votos;
            }
        }

        foreach (var jogador in _jogadores.Where(j => revelacao.Perderam.Contains(j.Id)))
            Punir(jogador);
        rodada.Revelacao = revelacao;
        Fase = FaseDaSala.Revelada;
    }

    private void Tocar()
    {
        ConferirProntos();
        UltimaAtividade = _relogio.GetUtcNow();
    }
}
