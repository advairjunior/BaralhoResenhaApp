using BaralhoResenhaApp.Api.Dominio;
using BaralhoResenhaApp.Api.Infraestrutura;

namespace BaralhoResenhaApp.Testes;

/// <summary>
/// 🚫 Palavra proibida: como a mímica, só que falando. Quem explica vê a palavra e
/// as proibidas; o time adivinha em 60 segundos. Os times seguem o Imagem e Ação.
/// </summary>
public sealed class PalavraProibidaTestes
{
    private static readonly Carta Praia = new("pp-1", ModoDeJogo.PalavraProibida, NivelDaCarta.Leve, "Praia",
        Proibidas: ["Areia", "Mar", "Sol", "Verão"]);

    private sealed record Mesa(Sala Sala, Jogador[] Todos)
    {
        public int Rodada => Sala.Rodada!.Numero;
        public IReadOnlyList<TimeDaMimica> Times => Sala.Rodada!.Times;
        public RodadaVisivel Visao(Jogador jogador) => Sala.Visao(jogador.Token).Rodada!;
        public Jogador Pelo(Guid id) => Todos.Single(j => j.Id == id);
    }

    private static Mesa Montar(int pessoas)
    {
        var sala = new Sala("ABCD", new Baralho([Praia]), new Random(6));
        var todos = Enumerable.Range(1, pessoas).Select(i => sala.Entrar($"P{i}", false)).ToArray();
        sala.Configurar(todos[0].Token, new ConfiguracaoDoJogo(NivelDaCarta.Leve, [ModoDeJogo.PalavraProibida], ZonaSegura: true,
            Ritmo: RitmoDaBebida.Raiz));
        sala.Comecar(todos[0].Token);
        return new Mesa(sala, todos);
    }

    [Fact]
    public void SoQuemExplicaVeAPalavraEAsProibidas()
    {
        var mesa = Montar(4);
        var explica = mesa.Pelo(mesa.Times.Single().Mimico);
        var adivinha = mesa.Todos.First(j => j.Id != explica.Id);

        Assert.Equal("Praia", mesa.Visao(explica).Texto);
        Assert.Equal(["Areia", "Mar", "Sol", "Verão"], mesa.Visao(explica).Proibidas);
        Assert.Equal("🚫 Adivinhe a palavra!", mesa.Visao(adivinha).Texto);
        Assert.Empty(mesa.Visao(adivinha).Proibidas);
        Assert.Equal(60, mesa.Visao(adivinha).CronometroSegundos);
    }

    [Fact]
    public void ComSeisPessoasSaoDoisTimesComAMesmaPalavra()
    {
        var mesa = Montar(6);

        Assert.Equal(2, mesa.Times.Count);
        Assert.All(mesa.Times, t => Assert.Equal("Praia", mesa.Visao(mesa.Pelo(t.Mimico)).Texto));
    }

    [Fact]
    public void NinguemAcertouQuemExplicouLevaPontoENaRevelacaoTodoMundoVe()
    {
        var mesa = Montar(4);
        var explica = mesa.Pelo(mesa.Times.Single().Mimico);
        var adivinha = mesa.Todos.First(j => j.Id != explica.Id);

        mesa.Sala.ResultadoDaMimica(mesa.Todos[0].Token, mesa.Rodada, null);

        var rodada = mesa.Visao(adivinha);
        Assert.Equal([explica.Id], rodada.Revelacao!.Perderam);
        Assert.Equal("Praia", rodada.Texto);
        Assert.Equal(4, rodada.Proibidas.Count);
        Assert.Equal(1, explica.Pontos);
    }

    [Fact]
    public void AcertarNaoContaComoMimicaNosPremios()
    {
        var mesa = Montar(4);
        var explica = mesa.Pelo(mesa.Times.Single().Mimico);

        mesa.Sala.ResultadoDaMimica(mesa.Todos[0].Token, mesa.Rodada, 0);

        Assert.Equal(0, explica.Estatisticas.MimicasAcertadas);
        Assert.Contains(explica.Id, mesa.Sala.Rodada!.Ganharam);
    }

    [Fact]
    public void BancoTemPalavrasComQuatroProibidas()
    {
        var cartas = CatalogoDeCartas.Carregar().Cartas.Where(c => c.Modo == ModoDeJogo.PalavraProibida).ToList();

        Assert.True(cartas.Count >= 50, $"só {cartas.Count} cartas");
        Assert.All(cartas, c =>
        {
            Assert.StartsWith("pp-", c.Id);
            Assert.Equal(4, c.Proibidas?.Count);
            Assert.DoesNotContain(c.Texto, c.Proibidas!, StringComparer.OrdinalIgnoreCase);
        });
    }
}
