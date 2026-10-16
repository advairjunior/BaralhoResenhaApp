namespace BaralhoResenhaApp.Api.Dominio;

public enum ModoDeJogo
{
    EuNunca,
    MaisProvavel,
    BebaSe,
    RegraRelampago,
    CasaisEmJogo,

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
    ImagemEAcao
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
/// <param name="Categoria">Imagem e Ação: a dica que o mímico pode dizer (Ação, Objeto, Filme…).</param>
/// <param name="Duelo">Quem é mais provável: {jogador} contra {jogador2}, a turma vota em quem mandou melhor.</param>
/// <param name="Isca">Regra-relâmpago: o que o jogo gera a cada carta para a regra acontecer.</param>
/// <param name="Iscas">Perguntas feitas para esta regra (ex.: sobre trabalho, na regra que proíbe falar de trabalho).</param>
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
    int? Goles = null);

/// <summary>De onde saem as iscas das regras-relâmpago.</summary>
/// <param name="Perguntas">Perguntas abertas, para a pessoa ter que falar bastante.</param>
/// <param name="Risadas">Missões para fazer alguém rir.</param>
/// <param name="Piadas">Piadas ruins, de tio no churrasco.</param>
public sealed record Iscas(IReadOnlyList<string> Perguntas, IReadOnlyList<string> Risadas, IReadOnlyList<string> Piadas)
{
    public static Iscas Vazias { get; } = new(["Conta uma história boa da sua semana."],
        ["Conte a pior piada que você sabe."], ["Qual é o doce preferido do pedreiro? Pé de moleque."]);
}

/// <summary>Quantos pontos (vezes que a carta pegou) valem um gole de verdade.</summary>
public enum RitmoDaBebida
{
    /// <summary>Um gole a cada 3 pontos: dá para jogar a noite inteira.</summary>
    Devagar,

    /// <summary>Um gole a cada 2 pontos.</summary>
    Normal,

    /// <summary>Todo ponto é gole, como nos baralhos de loja.</summary>
    Raiz
}

/// <param name="Nivel">Com <paramref name="Esquentar"/>, é até onde a noite pode chegar.</param>
/// <param name="Esquentar">Começa no Leve e sobe um nível a cada <see cref="CartasPorNivel"/> cartas.</param>
public sealed record ConfiguracaoDoJogo(
    NivelDaCarta Nivel,
    IReadOnlyList<ModoDeJogo> Modos,
    bool ZonaSegura,
    bool Esquentar = false,
    RitmoDaBebida Ritmo = RitmoDaBebida.Devagar,
    bool CartasNaManga = true)
{
    public const int CartasPorNivel = 8;

    public int PontosPorGole => Ritmo switch
    {
        RitmoDaBebida.Raiz => 1,
        RitmoDaBebida.Normal => 2,
        _ => 3
    };

    /// <summary>Nível da carta de número <paramref name="indice"/> (a primeira é 0).</summary>
    public NivelDaCarta NivelNaCarta(int indice) =>
        Esquentar
            ? (NivelDaCarta)Math.Min((int)Nivel, (int)NivelDaCarta.Leve + indice / CartasPorNivel)
            : Nivel;

    public static ConfiguracaoDoJogo Padrao { get; } = new(
        NivelDaCarta.Resenha,
        // Casais em Jogo começa desligado: quem quiser, liga.
        [ModoDeJogo.EuNunca, ModoDeJogo.MaisProvavel, ModoDeJogo.BebaSe, ModoDeJogo.RegraRelampago,
            ModoDeJogo.Tribunal, ModoDeJogo.Elogios, ModoDeJogo.ImagemEAcao],
        ZonaSegura: true);
}
