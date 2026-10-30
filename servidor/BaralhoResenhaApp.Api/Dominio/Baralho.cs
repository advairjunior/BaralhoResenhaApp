using System.Text.RegularExpressions;

namespace BaralhoResenhaApp.Api.Dominio;

public sealed partial class Baralho(IReadOnlyList<Carta> cartas, Iscas? iscas = null, Prendas? prendas = null)
{
    public Iscas Iscas { get; } = iscas ?? Iscas.Vazias;
    public Prendas Prendas { get; } = prendas ?? Prendas.Vazias;

    /// <summary>Na regra-relâmpago sem álcool, quem vacila leva ponto: "Escorregou, bebeu." vira "leva ponto".</summary>
    [GeneratedRegex(@"\bbebeu\b|\bbebe\b(?=[.,;!])")]
    private static partial Regex Bebeu();

    /// <summary>O que sobrar falando de bebida não sai na sala sem álcool.</summary>
    [GeneratedRegex(@"beb|cerveja|cachaça|\bdoses?\b|drink|bêbad|garrafa|brinde", RegexOptions.IgnoreCase)]
    private static partial Regex FalaDeBebida();

    public static string SemBebida(string texto) => Bebeu().Replace(texto, "leva ponto");

    private static bool ServeSemAlcool(Carta carta) => !FalaDeBebida().IsMatch(SemBebida(carta.Texto));

    /// <summary>Uma em cada tantas cartas vira regra-relâmpago.</summary>
    internal const int ChanceDeRelampago = 7;

    /// <summary>
    /// Roda de Música: surpresa de vez em quando (uma em cada tantas cartas), fora
    /// da mistura, para não tirar espaço das outras brincadeiras.
    /// </summary>
    internal const int ChanceDeMusica = 20;

    /// <summary>
    /// Parte das cartas que sai do nível escolhido; o restante vem dos níveis
    /// abaixo, para a noite não ficar só no extremo. Pouco: quem escolheu
    /// Resenha quer Resenha, e carta leve demais esfria a mesa.
    /// </summary>
    internal const double PesoDoNivelEscolhido = 0.85;

    /// <summary>No Esquenta sozinho, a noite tem que sentir que esquentou.</summary>
    internal const double PesoDoNivelAoEsquentar = 0.85;

    /// <summary>
    /// Peso de cada jogo na mistura. Votação, desafios e Tribunal são o coração da noite; Correio, Impostor
    /// e os jogos que demoram são tempero.
    /// A regra-relâmpago tem chance própria (<see cref="ChanceDeRelampago"/>).
    /// </summary>
    internal static readonly IReadOnlyDictionary<ModoDeJogo, int> Pesos = new Dictionary<ModoDeJogo, int>
    {
        [ModoDeJogo.EuNunca] = 4,
        [ModoDeJogo.MaisProvavel] = 5,
        [ModoDeJogo.BebaSe] = 2,
        [ModoDeJogo.Tribunal] = 4,
        [ModoDeJogo.Jurados] = 2,
        [ModoDeJogo.Elogios] = 1,
        // Demora mais que uma carta comum: tempero, não prato principal.
        [ModoDeJogo.Correio] = 1,
        [ModoDeJogo.ImagemEAcao] = 4,
        // Uma roda de pistas e uma votação: rende, mas demora, como o Correio.
        [ModoDeJogo.Impostor] = 1,
        // Escrever e votar demora, como o Correio. Quem quiser mais, põe no Muito.
        [ModoDeJogo.TermineAFrase] = 1,
        // A pessoa da vez escreve três frases antes de a turma votar: demora, como o Correio.
        [ModoDeJogo.DuasVerdades] = 1,
        // Um chute e a revelação: rápido, mas é tempero, como os outros jogos novos.
        [ModoDeJogo.ChutaAi] = 1,
        // Rápida e barulhenta, mas cada uma toma meio minuto da mesa inteira.
        [ModoDeJogo.BatataQuente] = 1,
        // Um toque e a revelação: rápido como o Eu Nunca, mas com menos cartas.
        [ModoDeJogo.IssoOuAquilo] = 2,
        // Um minuto e meio de perguntas com a mesa inteira olhando: dos mais pedidos.
        [ModoDeJogo.QuemSouEu] = 2,
        // A mímica falada: rende como a mímica, mas é mais rápida de entender.
        [ModoDeJogo.PalavraProibida] = 2,
    };

    /// <summary>
    /// Parte das cartas de Quem é mais provável que é duelo (inclui pedra, papel e
    /// tesoura). São poucas cartas no meio de muitas: sem isso, quase não saem.
    /// </summary>
    internal const double ChanceDeDuelo = 0.4;

    /// <summary>Ritmo: o mesmo jogo não vem mais que isso seguido.</summary>
    internal const int MaximoSeguidas = 2;

    public IReadOnlyList<Carta> Cartas { get; } = cartas;

    /// <param name="anteriores">Jogos das últimas cartas, da mais antiga à mais nova.</param>
    public Carta? Sortear(
        ConfiguracaoDoJogo configuracao,
        ISet<string> usadas,
        int quantidadeDeJogadores,
        bool regraEmAndamento,
        Random sorteio,
        IReadOnlyList<ModoDeJogo>? anteriores = null,
        IReadOnlySet<string>? tiradas = null)
    {
        tiradas ??= new HashSet<string>();
        var modos = configuracao.Modos
            .Distinct()
            // Votação e tribunal precisam de gente para votar.
            .Where(modo => modo is not (ModoDeJogo.MaisProvavel or ModoDeJogo.Tribunal or ModoDeJogo.ImagemEAcao or ModoDeJogo.PalavraProibida
                    or ModoDeJogo.Jurados or ModoDeJogo.TermineAFrase or ModoDeJogo.DuasVerdades
                    or ModoDeJogo.IssoOuAquilo) ||
                quantidadeDeJogadores >= 3)
            // Com menos de três escrevendo, todo mundo adivinha quem escreveu.
            .Where(modo => modo != ModoDeJogo.Correio || quantidadeDeJogadores >= 4)
            // Com três, dois inocentes e um impostor: o primeiro voto já entrega.
            .Where(modo => modo != ModoDeJogo.Impostor || quantidadeDeJogadores >= 4)
            .Where(modo => modo != ModoDeJogo.RegraRelampago || !regraEmAndamento)
            .ToList();

        if (modos.Remove(ModoDeJogo.Musica) &&
            (modos.Count == 0 || Saiu(ChanceDeMusica, configuracao.PesoDo(ModoDeJogo.Musica), sorteio)) &&
            SortearDoModo(ModoDeJogo.Musica, configuracao, usadas, tiradas, sorteio) is { } musica)
            return musica;

        if (modos.Remove(ModoDeJogo.RegraRelampago) &&
            (modos.Count == 0 || Saiu(ChanceDeRelampago, configuracao.PesoDo(ModoDeJogo.RegraRelampago), sorteio)) &&
            SortearDoModo(ModoDeJogo.RegraRelampago, configuracao, usadas, tiradas, sorteio) is { } regra)
            return regra;

        // Três "Eu Nunca" seguidos cansam: com outro jogo ligado, troca.
        if (anteriores is { Count: >= MaximoSeguidas } && modos.Count > 1)
        {
            var repetido = anteriores[^1];
            if (anteriores.TakeLast(MaximoSeguidas).All(modo => modo == repetido))
                modos.Remove(repetido);
        }

        while (modos.Count > 0)
        {
            var modo = SortearComPeso(modos, configuracao, sorteio);
            var carta = SortearDoModo(modo, configuracao, usadas, tiradas, sorteio);
            if (carta is not null) return carta;
            modos.Remove(modo);
        }
        return null;
    }

    /// <summary>Uma em cada <paramref name="chance"/> cartas; Muito dobra, Pouco corta pela metade.</summary>
    private static bool Saiu(int chance, double peso, Random sorteio) => peso switch
    {
        > 1 => sorteio.Next(chance) < 2,
        < 1 => sorteio.Next(chance * 2) == 0,
        _ => sorteio.Next(chance) == 0
    };

    private static ModoDeJogo SortearComPeso(List<ModoDeJogo> modos, ConfiguracaoDoJogo configuracao, Random sorteio)
    {
        // Em meios pontos, para o Pouco caber num número inteiro.
        int Peso(ModoDeJogo modo) => (int)(Pesos.GetValueOrDefault(modo, 1) * 2 * configuracao.PesoDo(modo));
        var total = modos.Sum(Peso);
        var ponto = sorteio.Next(total);
        foreach (var modo in modos)
        {
            ponto -= Peso(modo);
            if (ponto < 0) return modo;
        }
        return modos[^1];
    }

    private Carta? SortearDoModo(
        ModoDeJogo modo, ConfiguracaoDoJogo configuracao, ISet<string> usadas,
        IReadOnlySet<string> tiradas, Random sorteio)
    {
        var permitidas = Cartas
            .Where(carta => carta.Modo == modo)
            .Where(carta => !tiradas.Contains(carta.Id))
            .Where(carta => carta.Nivel <= configuracao.Nivel)
            .Where(carta => !(configuracao.ZonaSegura && carta.Sensivel))
            .Where(carta => !configuracao.SemAlcool || ServeSemAlcool(carta))
            .ToList();
        if (permitidas.Count == 0) return null;

        if (modo == ModoDeJogo.MaisProvavel)
        {
            var querDuelo = sorteio.NextDouble() < ChanceDeDuelo;
            var doJeito = permitidas.Where(carta => carta.Duelo == querDuelo).ToList();
            if (doJeito.Count > 0) permitidas = doJeito;
        }

        var disponiveis = permitidas.Where(carta => !usadas.Contains(carta.Id)).ToList();
        if (disponiveis.Count == 0)
        {
            // Acabaram as cartas deste modo: embaralha de novo só este monte.
            foreach (var carta in permitidas) usadas.Remove(carta.Id);
            disponiveis = permitidas;
        }

        var doNivel = disponiveis.Where(carta => carta.Nivel == configuracao.Nivel).ToList();
        var abaixo = disponiveis.Where(carta => carta.Nivel < configuracao.Nivel).ToList();
        var peso = PesoDoNivelEscolhido;
        if (configuracao.Esquentar)
        {
            // Esquentando, a noite não volta para o começo: além do nível de
            // agora, só o imediatamente abaixo.
            peso = PesoDoNivelAoEsquentar;
            var logoAbaixo = abaixo.Where(carta => carta.Nivel == configuracao.Nivel - 1).ToList();
            if (logoAbaixo.Count > 0) abaixo = logoAbaixo;
        }
        // De um nível abaixo, só vêm as melhores (quando o jogo tem destaque
        // nesse nível). Acabaram as melhores? Fica no nível escolhido; se o
        // jogo nem tem carta nele, vale qualquer uma de baixo.
        if (permitidas.Any(carta => carta.Nivel < configuracao.Nivel && carta.Destaque))
        {
            var melhores = abaixo.Where(carta => carta.Destaque).ToList();
            if (melhores.Count > 0 || doNivel.Count > 0) abaixo = melhores;
        }
        var monte = doNivel.Count > 0 && (abaixo.Count == 0 || sorteio.NextDouble() < peso)
            ? doNivel
            : abaixo;
        return monte[sorteio.Next(monte.Count)];
    }
}
