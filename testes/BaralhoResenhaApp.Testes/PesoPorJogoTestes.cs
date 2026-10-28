using BaralhoResenhaApp.Api.Dominio;

namespace BaralhoResenhaApp.Testes;

/// <summary>"Mais Tribunal, menos Beba se": cada jogo ligado sai Pouco (metade), Normal ou Muito (o dobro).</summary>
public sealed class PesoPorJogoTestes
{
    private static readonly Baralho Monte = new(
        [
            .. Enumerable.Range(1, 20).Select(i => new Carta($"en-{i}", ModoDeJogo.EuNunca, NivelDaCarta.Leve, $"Eu nunca {i}")),
            .. Enumerable.Range(1, 20).Select(i => new Carta($"bs-{i}", ModoDeJogo.BebaSe, NivelDaCarta.Leve, $"Beba se {i}")),
            .. Enumerable.Range(1, 20).Select(i => new Carta($"rr-{i}", ModoDeJogo.RegraRelampago, NivelDaCarta.Leve, $"Regra {i}")),
        ]);

    private static double ParteDe(ModoDeJogo modo, ConfiguracaoDoJogo configuracao)
    {
        var sorteio = new Random(21);
        var modos = Enumerable.Range(0, 4000)
            .Select(_ => Monte.Sortear(configuracao, new HashSet<string>(), 5, false, sorteio)!.Modo)
            .ToList();
        return modos.Count(m => m == modo) / (double)modos.Count;
    }

    private static ConfiguracaoDoJogo EuNuncaEBebaSe(
        IReadOnlyList<ModoDeJogo>? muito = null, IReadOnlyList<ModoDeJogo>? pouco = null) =>
        new(NivelDaCarta.Leve, [ModoDeJogo.EuNunca, ModoDeJogo.BebaSe], ZonaSegura: true, Muito: muito, Pouco: pouco);

    [Fact]
    public void SemMexerFicaOPesoDeSempre()
    {
        // Eu Nunca pesa 4, Beba se pesa 2: um terço é Beba se.
        Assert.InRange(ParteDe(ModoDeJogo.BebaSe, EuNuncaEBebaSe()), 0.30, 0.37);
    }

    [Fact]
    public void MuitoDobraAChanceDoJogo()
    {
        // Beba se no dobro: 4 contra 4.
        Assert.InRange(ParteDe(ModoDeJogo.BebaSe, EuNuncaEBebaSe(muito: [ModoDeJogo.BebaSe])), 0.46, 0.54);
    }

    [Fact]
    public void PoucoCortaAChancePelaMetade()
    {
        // Beba se pela metade: 1 contra 4.
        Assert.InRange(ParteDe(ModoDeJogo.BebaSe, EuNuncaEBebaSe(pouco: [ModoDeJogo.BebaSe])), 0.17, 0.23);
    }

    [Fact]
    public void MaisTribunalMenosBebaSeValeParaOsDoisLados()
    {
        // Eu Nunca pela metade (2) e Beba se no dobro (4): dois terços é Beba se.
        var parte = ParteDe(ModoDeJogo.BebaSe, EuNuncaEBebaSe(muito: [ModoDeJogo.BebaSe], pouco: [ModoDeJogo.EuNunca]));
        Assert.InRange(parte, 0.63, 0.70);
    }

    [Theory]
    [InlineData(null, 0.11, 0.17)]
    [InlineData("muito", 0.25, 0.32)]
    [InlineData("pouco", 0.05, 0.09)]
    public void RegraRelampagoTambemTemPeso(string? peso, double minimo, double maximo)
    {
        IReadOnlyList<ModoDeJogo> regra = [ModoDeJogo.RegraRelampago];
        var configuracao = new ConfiguracaoDoJogo(
            NivelDaCarta.Leve, [ModoDeJogo.EuNunca, ModoDeJogo.RegraRelampago], ZonaSegura: true,
            Muito: peso == "muito" ? regra : null, Pouco: peso == "pouco" ? regra : null);

        Assert.InRange(ParteDe(ModoDeJogo.RegraRelampago, configuracao), minimo, maximo);
    }

    [Fact]
    public void UmJogoNaoFicaEmPoucoEMuitoAoMesmoTempo()
    {
        var sala = new Sala("ABCD", Monte);
        var ana = sala.Entrar("Ana", false);

        var erro = Assert.Throws<AcaoNaoPermitidaException>(() => sala.Configurar(ana.Token,
            EuNuncaEBebaSe(muito: [ModoDeJogo.BebaSe], pouco: [ModoDeJogo.BebaSe])));

        Assert.Equal("Um jogo não fica em Pouco e Muito ao mesmo tempo.", erro.Message);
    }
}
