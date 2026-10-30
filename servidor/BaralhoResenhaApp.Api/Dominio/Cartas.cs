namespace BaralhoResenhaApp.Api.Dominio;

public enum ModoDeJogo
{
    EuNunca,
    MaisProvavel,
    BebaSe,
    RegraRelampago,

    /// <summary>A turma julga uma pessoa: "{jogador} tem cara de…?", sim ou não.</summary>
    Tribunal,

    /// <summary>Dinâmicas de elogio: ninguém bebe, todo mundo sai se achando.</summary>
    Elogios,

    /// <summary>
    /// Correio da Resenha: a turma escreve bilhetes curtos e anônimos sobre
    /// quem está na foto; no fim, todos os celulares mostram tudo.
    /// </summary>
    Correio,

    /// <summary>Imagem e Ação: mímica da palavra da carta; só o mímico vê a palavra.</summary>
    ImagemEAcao,

    /// <summary>Jurados: o app elege uma pessoa e o resto dá nota de 1 a 5 estrelas, em segredo.</summary>
    Jurados,

    /// <summary>Roda de Música: a carta dá o tema e cada um canta na sua vez, na ordem sorteada.</summary>
    Musica,

    /// <summary>
    /// Impostor: todo mundo recebe a mesma palavra, menos um, que só sabe o tema.
    /// Cada um fala uma pista e a turma vota em quem é o impostor.
    /// </summary>
    Impostor,

    /// <summary>
    /// Termine a frase: a carta dá o começo, cada um completa em segredo e a
    /// turma vota na melhor sem saber de quem é. Só a vencedora revela o autor.
    /// </summary>
    TermineAFrase,

    /// <summary>
    /// Duas verdades e uma mentira: a pessoa da vez escreve três frases sobre si
    /// e a turma vota em segredo em qual é a mentira.
    /// </summary>
    DuasVerdades,

    /// <summary>
    /// Chuta aí: pergunta com resposta em número; cada um chuta em segredo. Quem
    /// chutou mais longe leva ponto e quem chegou mais perto distribui goles.
    /// </summary>
    ChutaAi,

    /// <summary>
    /// Batata quente: a carta dá a categoria e a batata passa de celular em celular:
    /// cada um fala uma coisa e toca em "Falei!". O pavio é segredo; quando estoura,
    /// quem está com a batata leva ponto.
    /// </summary>
    BatataQuente
}

/// <summary>
/// Como o jogo faz a regra-relâmpago acontecer. Regra de fala sem ninguém
/// falando é regra desperdiçada: a cada carta sai uma isca.
/// </summary>
public enum IscaDaRegra
{
    Nenhuma,

    /// <summary>O {jogador} da regra é entrevistado: alguém faz as perguntas do app.</summary>
    Entrevista,

    /// <summary>Regra da mesa: a cada carta, uma pergunta para alguém responder.</summary>
    Conversa,

    /// <summary>Alguém recebe uma missão para fazer o {jogador} rir.</summary>
    Risada,

    /// <summary>O {jogador} recebe perguntas para fazer à turma.</summary>
    Mestre,

    /// <summary>O {jogador} lê uma piada ruim do app.</summary>
    Piada
}

/// <summary>Quanto mais alto, mais apimentada a carta.</summary>
public enum NivelDaCarta
{
    Leve = 1,
    Resenha = 2,
    Picante = 3,
    Original = 4
}

/// <param name="Jokenpo">Duelo de pedra, papel e tesoura: os dois escolhem no celular, sem votação.</param>
/// <param name="Goles">"Bebe 2": quem a carta pega bebe isso de verdade, fora do cofrinho.</param>
/// <param name="Destaque">Das melhores do nível: só elas aparecem quando a noite está num nível acima.</param>
/// <param name="Categoria">
/// Imagem e Ação: a dica que o mímico pode dizer (Ação, Objeto, Filme…).
/// Impostor: o tema da palavra, a única coisa que o impostor sabe.
/// </param>
/// <param name="Duelo">Quem é mais provável: {jogador} contra {jogador2}, a turma vota em quem mandou melhor.</param>
/// <param name="Isca">Regra-relâmpago: o que o jogo gera a cada carta para a regra acontecer.</param>
/// <param name="Iscas">Perguntas feitas para esta regra (ex.: sobre trabalho, na regra que proíbe falar de trabalho).</param>
/// <param name="Conta">Eu Nunca "conta essa": na revelação, cada um que já fez conta a sua, um de cada vez.</param>
/// <param name="Resposta">Chuta aí: o número certo, que só aparece na revelação.</param>
/// <param name="Sensivel">
/// Assunto que pode virar DR de verdade entre casais (ex, ciúme, traição).
/// Fica fora do baralho quando a Zona Segura está ligada.
/// </param>
public sealed record Carta(
    string Id,
    ModoDeJogo Modo,
    NivelDaCarta Nivel,
    string Texto,
    bool Sensivel = false,
    bool Elogio = false,
    IscaDaRegra Isca = IscaDaRegra.Nenhuma,
    IReadOnlyList<string>? Iscas = null,
    bool Duelo = false,
    string? Categoria = null,
    bool Destaque = false,
    bool Jokenpo = false,
    int? Goles = null,
    bool Conta = false,
    decimal? Resposta = null);

/// <summary>De onde saem as iscas das regras-relâmpago.</summary>
/// <param name="Perguntas">Perguntas abertas, para a pessoa ter que falar bastante.</param>
/// <param name="Risadas">Missões para fazer alguém rir.</param>
/// <param name="Piadas">Piadas ruins, de tio no churrasco.</param>
public sealed record Iscas(IReadOnlyList<string> Perguntas, IReadOnlyList<string> Risadas, IReadOnlyList<string> Piadas)
{
    public static Iscas Vazias { get; } = new(["Conta uma história boa da sua semana."],
        ["Conte a pior piada que você sabe."], ["Qual é o doce preferido do pedreiro? Pé de moleque."]);
}

/// <summary>
/// Sala sem álcool: no lugar do gole, uma prenda (desafio rápido), separada por nível
/// como as cartas. Os micos são para o fim da noite, mais caprichados.
/// </summary>
public sealed record Prendas(
    IReadOnlyList<string> Leve, IReadOnlyList<string> Resenha, IReadOnlyList<string> Picante, IReadOnlyList<string> Micos)
{
    public static Prendas Vazias { get; } = new(["Imite alguém da mesa até a turma adivinhar quem é."],
        ["Mostre a última foto da sua galeria."], ["Conte o seu crush mais vergonhoso."],
        ["Cante o refrão de uma música escolhida pela turma.", "Dance sem música por 20 segundos.",
            "Faça um discurso de agradecimento de Oscar para a turma."]);

    /// <summary>As prendas que valem até <paramref name="nivel"/>: o Leve nunca vê as de cima.</summary>
    public IReadOnlyList<string> Ate(NivelDaCarta nivel) => nivel switch
    {
        NivelDaCarta.Leve => Leve,
        NivelDaCarta.Resenha => [.. Leve, .. Resenha],
        _ => [.. Leve, .. Resenha, .. Picante]
    };
}

/// <summary>Quantos pontos (vezes que a carta pegou) valem um gole de verdade.</summary>
public enum RitmoDaBebida
{
    /// <summary>Um gole a cada 7 pontos: dá para jogar a noite inteira.</summary>
    Devagar,

    /// <summary>Um gole a cada 2 pontos.</summary>
    Normal,

    /// <summary>Todo ponto é gole, como nos baralhos de loja.</summary>
    Raiz
}

/// <param name="Nivel">Com <paramref name="Esquentar"/>, é até onde a noite pode chegar.</param>
/// <param name="Esquentar">Começa no Leve e sobe um nível a cada <see cref="CartasPorNivel"/> cartas.</param>
/// <param name="SemAlcool">A sala toda sem álcool: o cofrinho cheio vira prenda e carta de bebida não sai.</param>
public sealed record ConfiguracaoDoJogo(
    NivelDaCarta Nivel,
    IReadOnlyList<ModoDeJogo> Modos,
    bool ZonaSegura,
    bool Esquentar = false,
    RitmoDaBebida Ritmo = RitmoDaBebida.Devagar,
    bool CartasNaManga = true,
    bool PassarSozinho = true,
    int? Cofrinho = null,
    IReadOnlyList<ModoDeJogo>? Muito = null,
    IReadOnlyList<ModoDeJogo>? Pouco = null,
    bool SemAlcool = false)
{
    public const int CartasPorNivel = 8;

    /// <summary>"Mais Tribunal, menos Beba se": Muito sai o dobro, Pouco sai a metade.</summary>
    public double PesoDo(ModoDeJogo modo) =>
        Muito?.Contains(modo) == true ? 2 : Pouco?.Contains(modo) == true ? 0.5 : 1;
    public const int CofrinhoMaximo = 20;

    /// <summary>Tamanho do cofrinho: o escolhido na mão ou o do ritmo.</summary>
    public int PontosPorGole => Cofrinho ?? Ritmo switch
    {
        RitmoDaBebida.Raiz => 1,
        RitmoDaBebida.Normal => 2,
        _ => 7
    };

    /// <summary>Nível da carta de número <paramref name="indice"/> (a primeira é 0).</summary>
    public NivelDaCarta NivelNaCarta(int indice) =>
        Esquentar
            ? (NivelDaCarta)Math.Min((int)Nivel, (int)NivelDaCarta.Leve + indice / CartasPorNivel)
            : Nivel;

    public static ConfiguracaoDoJogo Padrao { get; } = new(
        NivelDaCarta.Resenha,
        [ModoDeJogo.EuNunca, ModoDeJogo.MaisProvavel, ModoDeJogo.BebaSe, ModoDeJogo.RegraRelampago,
            ModoDeJogo.Tribunal, ModoDeJogo.Elogios, ModoDeJogo.ImagemEAcao, ModoDeJogo.Jurados,
            ModoDeJogo.Musica, ModoDeJogo.Impostor, ModoDeJogo.TermineAFrase, ModoDeJogo.DuasVerdades,
            ModoDeJogo.ChutaAi, ModoDeJogo.BatataQuente],
        ZonaSegura: true);
}
