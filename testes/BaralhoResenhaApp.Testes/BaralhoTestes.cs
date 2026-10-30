using System.Text.RegularExpressions;
using BaralhoResenhaApp.Api.Dominio;
using BaralhoResenhaApp.Api.Infraestrutura;

namespace BaralhoResenhaApp.Testes;

public sealed class BaralhoTestes
{
    private static readonly IReadOnlyList<Carta> Cartas =
    [
        new("leve", ModoDeJogo.EuNunca, NivelDaCarta.Leve, "Leve"),
        new("resenha", ModoDeJogo.EuNunca, NivelDaCarta.Resenha, "Resenha"),
        new("picante", ModoDeJogo.EuNunca, NivelDaCarta.Picante, "Picante"),
        new("sensivel", ModoDeJogo.EuNunca, NivelDaCarta.Leve, "Ex", Sensivel: true),
        new("mp", ModoDeJogo.MaisProvavel, NivelDaCarta.Leve, "Quem"),
    ];

    private static List<Carta> SortearVarias(ConfiguracaoDoJogo configuracao, int jogadores = 4)
    {
        var baralho = new Baralho(Cartas);
        var sorteio = new Random(7);
        return Enumerable.Range(0, 200)
            .Select(_ => baralho.Sortear(configuracao, new HashSet<string>(), jogadores, false, sorteio)!)
            .ToList();
    }

    [Fact]
    public void NuncaPassaDoNivelEscolhido()
    {
        var cartas = SortearVarias(new(NivelDaCarta.Resenha, [ModoDeJogo.EuNunca], ZonaSegura: false));

        Assert.DoesNotContain(cartas, c => c.Nivel > NivelDaCarta.Resenha);
        Assert.Contains(cartas, c => c.Id == "resenha");
        Assert.Contains(cartas, c => c.Id == "leve");
    }

    [Fact]
    public void NoNivelEscolhidoQuaseTudoEhDoNivelEOQueVemDeBaixoEhDestaque()
    {
        var baralho = new Baralho([
            new("r1", ModoDeJogo.EuNunca, NivelDaCarta.Resenha, "Resenha 1"),
            new("r2", ModoDeJogo.EuNunca, NivelDaCarta.Resenha, "Resenha 2"),
            new("l-chata", ModoDeJogo.EuNunca, NivelDaCarta.Leve, "Leve chata"),
            new("l-boa", ModoDeJogo.EuNunca, NivelDaCarta.Leve, "Leve boa", Destaque: true),
        ]);
        var sorteio = new Random(7);
        var configuracao = new ConfiguracaoDoJogo(NivelDaCarta.Resenha, [ModoDeJogo.EuNunca], true);

        var cartas = Enumerable.Range(0, 1000)
            .Select(_ => baralho.Sortear(configuracao, new HashSet<string>(), 4, false, sorteio)!)
            .ToList();

        Assert.InRange(cartas.Count(c => c.Nivel == NivelDaCarta.Resenha) / 1000.0, 0.8, 0.9);
        Assert.Contains(cartas, c => c.Id == "l-boa");
        Assert.DoesNotContain(cartas, c => c.Id == "l-chata");
    }

    [Fact]
    public void NoProprioNivelLeveTodasAsLevesEntram()
    {
        var baralho = new Baralho([
            new("l-chata", ModoDeJogo.EuNunca, NivelDaCarta.Leve, "Leve chata"),
            new("l-boa", ModoDeJogo.EuNunca, NivelDaCarta.Leve, "Leve boa", Destaque: true),
        ]);
        var sorteio = new Random(3);
        var configuracao = new ConfiguracaoDoJogo(NivelDaCarta.Leve, [ModoDeJogo.EuNunca], true);

        var ids = Enumerable.Range(0, 50)
            .Select(_ => baralho.Sortear(configuracao, new HashSet<string>(), 4, false, sorteio)!.Id)
            .ToHashSet();

        Assert.Contains("l-chata", ids);
    }

    [Fact]
    public void ZonaSeguraTiraAsCartasSensiveis()
    {
        Assert.DoesNotContain(
            SortearVarias(new(NivelDaCarta.Leve, [ModoDeJogo.EuNunca], ZonaSegura: true)),
            c => c.Sensivel);
        Assert.Contains(
            SortearVarias(new(NivelDaCarta.Leve, [ModoDeJogo.EuNunca], ZonaSegura: false)),
            c => c.Sensivel);
    }

    [Fact]
    public void QuemEhMaisProvavelPrecisaDeTresPessoas()
    {
        var configuracao = new ConfiguracaoDoJogo(
            NivelDaCarta.Leve, [ModoDeJogo.EuNunca, ModoDeJogo.MaisProvavel], true);

        Assert.DoesNotContain(SortearVarias(configuracao, jogadores: 2), c => c.Modo == ModoDeJogo.MaisProvavel);
        Assert.Contains(SortearVarias(configuracao, jogadores: 3), c => c.Modo == ModoDeJogo.MaisProvavel);
    }

    [Fact]
    public void NaoRepeteCartaAteAcabarOMonte()
    {
        var baralho = new Baralho(Cartas);
        var usadas = new HashSet<string>();
        var configuracao = new ConfiguracaoDoJogo(NivelDaCarta.Picante, [ModoDeJogo.EuNunca], true);
        var sorteio = new Random(3);

        var sorteadas = Enumerable.Range(0, 3).Select(_ =>
        {
            var carta = baralho.Sortear(configuracao, usadas, 4, false, sorteio)!;
            usadas.Add(carta.Id);
            return carta.Id;
        }).ToList();

        Assert.Equal(3, sorteadas.Distinct().Count());
        Assert.NotNull(baralho.Sortear(configuracao, usadas, 4, false, sorteio));
    }

    private static List<ModoDeJogo> NoiteMisturada(ConfiguracaoDoJogo configuracao, int cartas)
    {
        var baralho = CatalogoDeCartas.Carregar();
        var usadas = new HashSet<string>();
        var anteriores = new List<ModoDeJogo>();
        var sorteio = new Random(11);
        var modos = new List<ModoDeJogo>();
        var regraAte = 0;
        for (var i = 0; i < cartas; i++)
        {
            var carta = baralho.Sortear(configuracao, usadas, 4, regraAte > i, sorteio, anteriores)!;
            usadas.Add(carta.Id);
            if (carta.Modo == ModoDeJogo.RegraRelampago) regraAte = i + 4;
            anteriores.Add(carta.Modo);
            if (anteriores.Count > Baralho.MaximoSeguidas) anteriores.RemoveAt(0);
            modos.Add(carta.Modo);
        }
        return modos;
    }

    private static readonly ConfiguracaoDoJogo TudoLigado = new(
        NivelDaCarta.Resenha, Enum.GetValues<ModoDeJogo>(), ZonaSegura: true);

    [Fact]
    public void MisturaNuncaRepeteOMesmoJogoTresVezesSeguidas()
    {
        var modos = NoiteMisturada(TudoLigado, 600);

        for (var i = 2; i < modos.Count; i++)
            Assert.False(modos[i] == modos[i - 1] && modos[i] == modos[i - 2], $"três {modos[i]} seguidos na carta {i}");
    }

    [Fact]
    public void NaMisturaARegraEhTemperoEOsRapidosDominam()
    {
        var modos = NoiteMisturada(TudoLigado, 1000);
        double Parte(ModoDeJogo modo) => modos.Count(m => m == modo) / (double)modos.Count;

        Assert.InRange(Parte(ModoDeJogo.RegraRelampago), 0.04, 0.20);
        Assert.True(Parte(ModoDeJogo.EuNunca) > Parte(ModoDeJogo.Correio) * 2);
        // A votação é o coração da noite: segue sendo o jogo que mais sai, por mais jogos que entrem.
        Assert.All(Enum.GetValues<ModoDeJogo>().Where(m => m != ModoDeJogo.MaisProvavel),
            m => Assert.True(Parte(ModoDeJogo.MaisProvavel) > Parte(m), $"{m} saiu mais que a votação"));
        // Beba se cedeu espaço para votação, desafios, mímica e os jogos novos, mas segue na mesa
        // (uns 5%; cada jogo novo dilui um pouco).
        Assert.True(Parte(ModoDeJogo.BebaSe) > 0.04);
    }

    [Fact]
    public void UmJogoSoTambemFunciona()
    {
        var modos = NoiteMisturada(new ConfiguracaoDoJogo(NivelDaCarta.Leve, [ModoDeJogo.EuNunca], true), 50);

        Assert.All(modos, modo => Assert.Equal(ModoDeJogo.EuNunca, modo));
    }

    [Fact]
    public void NenhumaCartaDependeDeTerCasalNaMesa()
    {
        // Casais em Jogo saiu do app: a turma joga como amigos, ninguém marca par.
        var cartas = CatalogoDeCartas.Carregar().Cartas;

        Assert.DoesNotContain(cartas, c => c.Id.StartsWith("cs-"));
        Assert.DoesNotContain(cartas, c => Regex.IsMatch(c.Texto, @"\bcasa(l|is)\b|\{par\}", RegexOptions.IgnoreCase));
    }

    [Fact]
    public void BaralhoOficialCarregaSemIdRepetidoETodoJogoTemCartaLeve()
    {
        var baralho = CatalogoDeCartas.Carregar();

        Assert.True(baralho.Cartas.Count >= 250);
        // Todo jogo tem cartas leves (qualquer nível já tem o que sortear) e
        // todo nível tem cartas próprias.
        foreach (var modo in Enum.GetValues<ModoDeJogo>())
            Assert.Contains(baralho.Cartas, c => c.Modo == modo && c.Nivel == NivelDaCarta.Leve);
        foreach (var nivel in Enum.GetValues<NivelDaCarta>())
            Assert.Contains(baralho.Cartas, c => c.Nivel == nivel);
        Assert.All(baralho.Cartas, c => Assert.False(string.IsNullOrWhiteSpace(c.Texto)));
    }

    [Fact]
    public void ComTudoLigadoVotacaoTribunalDesafiosEMimicaSaemBastante()
    {
        var baralho = CatalogoDeCartas.Carregar();
        var configuracao = new ConfiguracaoDoJogo(NivelDaCarta.Resenha, Enum.GetValues<ModoDeJogo>(), true);
        var sorteio = new Random(11);

        var cartas = Enumerable.Range(0, 3000)
            .Select(_ => baralho.Sortear(configuracao, new HashSet<string>(), 5, false, sorteio)!)
            .ToList();

        // A Roda de Música é surpresa de vez em quando: não mexe na mistura das outras.
        var outras = cartas.Where(c => c.Modo != ModoDeJogo.Musica).ToList();
        double Parte(Func<Carta, bool> filtro) => outras.Count(filtro) / (double)outras.Count;
        var deVoto = Parte(c => c.Modo is ModoDeJogo.MaisProvavel or ModoDeJogo.Tribunal or ModoDeJogo.Jurados
            or ModoDeJogo.Impostor or ModoDeJogo.IssoOuAquilo);
        var desafios = Parte(c => c.Duelo);
        // Adivinhar em time: a mímica e a palavra proibida, que usa os mesmos times.
        var mimica = Parte(c => c.Modo is ModoDeJogo.ImagemEAcao or ModoDeJogo.PalavraProibida);
        Assert.True(deVoto >= 0.35, $"votação, tribunal, jurados, impostor e isso ou aquilo: {deVoto:P0}");
        // Esperado: uns 6,5% (Quem é mais provável pesa 5 de 31, e 40% dele é duelo); cada jogo novo dilui um pouco.
        Assert.True(desafios >= 0.05, $"duelos: {desafios:P0}");
        // Uma em cada 8 cartas (12,5%), com folga para cada jogo novo que entra na mistura.
        Assert.True(mimica >= 0.11, $"imagem e ação e palavra proibida: {mimica:P0}");
    }

    [Fact]
    public void RodaDeMusicaSaiDeVezEmQuando()
    {
        var baralho = CatalogoDeCartas.Carregar();
        var configuracao = new ConfiguracaoDoJogo(NivelDaCarta.Resenha, Enum.GetValues<ModoDeJogo>(), true);
        var sorteio = new Random(12);

        var musicas = Enumerable.Range(0, 3000)
            .Count(_ => baralho.Sortear(configuracao, new HashSet<string>(), 5, false, sorteio)!.Modo == ModoDeJogo.Musica);

        Assert.InRange(musicas / 3000.0, 0.03, 0.07);
    }

    [Theory]
    [InlineData("lugar público")]
    [InlineData("vídeo íntimo")]
    [InlineData("swing")]
    [InlineData("brinquedo erótico")]
    [InlineData("sex shop")]
    [InlineData("strip-tease")]
    [InlineData("no flagra")]
    [InlineData("banheiro de uma festa")]
    [InlineData("dor de cabeça")]
    [InlineData("sofá depois de uma briga")]
    [InlineData("falando sozinho(a)")]
    [InlineData("perfil fake")]
    [InlineData("barrado")]
    [InlineData("por causa do caminho")]
    [InlineData("olhar mais sedutor")]
    [InlineData("sorriso mais bonito")]
    [InlineData("levanta qualquer festa")]
    [InlineData("olhares quando passa")]
    [InlineData("sucesso na balada")]
    public void OMesmoAssuntoNaoApareceEmDuasCartas(string assunto)
    {
        var cartas = CatalogoDeCartas.Carregar().Cartas
            .Where(c => c.Texto.Contains(assunto, StringComparison.OrdinalIgnoreCase))
            .Select(c => c.Id)
            .ToList();

        // Eu Nunca e Beba se com a mesma pergunta saem uma atrás da outra no mesmo nível.
        Assert.True(cartas.Count <= 1, $"\"{assunto}\" aparece em {string.Join(", ", cartas)}");
    }

    [Theory]
    [InlineData(ModoDeJogo.EuNunca, 20)]
    [InlineData(ModoDeJogo.MaisProvavel, 20)]
    [InlineData(ModoDeJogo.Tribunal, 20)]
    [InlineData(ModoDeJogo.BebaSe, 15)]
    public void NoLeveCadaJogoPrincipalTemCartaParaUmaNoiteSemRepetir(ModoDeJogo modo, int minimo)
    {
        // Uma noite de 60 cartas com tudo ligado tira umas 15 de cada jogo principal
        // (o Beba se, que pesa menos na mistura, umas 5).
        var noLeve = CatalogoDeCartas.Carregar().Cartas.Count(c => c.Modo == modo && c.Nivel == NivelDaCarta.Leve);

        Assert.True(noLeve >= minimo, $"{modo} tem só {noLeve} cartas no Leve");
    }
}
