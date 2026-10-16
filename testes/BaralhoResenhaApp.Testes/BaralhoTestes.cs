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

    private static List<ModoDeJogo> NoiteMisturada(ConfiguracaoDoJogo configuracao, int cartas, int casais = 1)
    {
        var baralho = CatalogoDeCartas.Carregar();
        var usadas = new HashSet<string>();
        var anteriores = new List<ModoDeJogo>();
        var sorteio = new Random(11);
        var modos = new List<ModoDeJogo>();
        var regraAte = 0;
        for (var i = 0; i < cartas; i++)
        {
            var carta = baralho.Sortear(configuracao, usadas, 4, regraAte > i, sorteio, casais, anteriores)!;
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
    public void NaMisturaCasaisEmJogoEhTemperoEOsRapidosDominam()
    {
        var modos = NoiteMisturada(TudoLigado, 1000);
        double Parte(ModoDeJogo modo) => modos.Count(m => m == modo) / (double)modos.Count;

        Assert.InRange(Parte(ModoDeJogo.CasaisEmJogo), 0.03, 0.15);
        Assert.InRange(Parte(ModoDeJogo.RegraRelampago), 0.04, 0.20);
        Assert.True(Parte(ModoDeJogo.EuNunca) > Parte(ModoDeJogo.CasaisEmJogo) * 2);
        Assert.True(Parte(ModoDeJogo.MaisProvavel) > 0.12);
        // Beba se cedeu espaço para votação, desafios e mímica, mas segue na mesa.
        Assert.True(Parte(ModoDeJogo.BebaSe) > 0.06);
    }

    [Fact]
    public void UmJogoSoTambemFunciona()
    {
        var modos = NoiteMisturada(new ConfiguracaoDoJogo(NivelDaCarta.Leve, [ModoDeJogo.EuNunca], true), 50);

        Assert.All(modos, modo => Assert.Equal(ModoDeJogo.EuNunca, modo));
    }

    [Fact]
    public void CasaisEmJogoComecaDesligado()
    {
        Assert.DoesNotContain(ModoDeJogo.CasaisEmJogo, ConfiguracaoDoJogo.Padrao.Modos);
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
            .Select(_ => baralho.Sortear(configuracao, new HashSet<string>(), 5, false, sorteio, casais: 2)!)
            .ToList();

        var deVoto = cartas.Count(c => c.Modo is ModoDeJogo.MaisProvavel or ModoDeJogo.Tribunal) / 3000.0;
        var desafios = cartas.Count(c => c.Duelo) / 3000.0;
        Assert.True(deVoto >= 0.35, $"votação e tribunal: {deVoto:P0}");
        Assert.True(desafios >= 0.07, $"duelos: {desafios:P0}");
        var mimica = cartas.Count(c => c.Modo == ModoDeJogo.ImagemEAcao) / 3000.0;
        Assert.True(mimica >= 0.11, $"imagem e ação: {mimica:P0}");
    }
}
