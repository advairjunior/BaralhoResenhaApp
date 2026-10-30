using BaralhoResenhaApp.Api.Dominio;
using BaralhoResenhaApp.Api.Infraestrutura;

namespace BaralhoResenhaApp.Testes;

/// <summary>
/// ⚖️ Isso ou aquilo: a carta dá duas opções e cada um escolhe em segredo.
/// Quem ficou na minoria leva ponto; empate ou todo mundo igual, ninguém leva.
/// </summary>
public sealed class IssoOuAquiloTestes
{
    private static readonly Carta PraiaOuMontanha = new("io-1", ModoDeJogo.IssoOuAquilo, NivelDaCarta.Leve,
        "Férias: praia ou montanha?", Opcoes: ["Praia", "Montanha"]);

    private sealed record Mesa(Sala Sala, Jogador[] Todos)
    {
        public int Rodada => Sala.Rodada!.Numero;
        public RodadaVisivel Visao(Jogador jogador) => Sala.Visao(jogador.Token).Rodada!;
        public void Escolher(Jogador jogador, string opcao) => Sala.Responder(jogador.Token, Rodada, opcao);
    }

    private static Mesa Montar(int pessoas = 4)
    {
        var sala = new Sala("ABCD", new Baralho([PraiaOuMontanha]), new Random(3));
        var todos = new[] { "Ana", "Beto", "Caio", "Duda", "Edu" }.Take(pessoas).Select(n => sala.Entrar(n, false)).ToArray();
        sala.Configurar(todos[0].Token, new ConfiguracaoDoJogo(NivelDaCarta.Leve, [ModoDeJogo.IssoOuAquilo], ZonaSegura: true,
            Ritmo: RitmoDaBebida.Raiz));
        sala.Comecar(todos[0].Token);
        return new Mesa(sala, todos);
    }

    [Fact]
    public void ACartaMostraAsDuasOpcoes()
    {
        var mesa = Montar();

        var rodada = mesa.Visao(mesa.Todos[1]);
        Assert.Equal(["Praia", "Montanha"], rodada.Opcoes);
        Assert.True(rodada.PedeResposta);
    }

    [Theory]
    [InlineData("2")]
    [InlineData("praia")]
    [InlineData("")]
    public void SoValeEscolherUmaDasDuas(string resposta)
    {
        var mesa = Montar();

        var erro = Assert.Throws<AcaoNaoPermitidaException>(() => mesa.Escolher(mesa.Todos[0], resposta));
        Assert.Equal("Escolha uma das duas.", erro.Message);
    }

    [Fact]
    public void QuemFicouNaMinoriaLevaPonto()
    {
        var mesa = Montar();
        var (ana, beto, caio, duda) = (mesa.Todos[0], mesa.Todos[1], mesa.Todos[2], mesa.Todos[3]);

        mesa.Escolher(ana, "0");
        mesa.Escolher(beto, "0");
        mesa.Escolher(caio, "0");
        Assert.Null(mesa.Visao(duda).Revelacao);
        mesa.Escolher(duda, "1");

        var revelacao = mesa.Visao(ana).Revelacao!;
        Assert.Equal([duda.Id], revelacao.Perderam);
        Assert.Equal(new[] { ana.Id, beto.Id, caio.Id }.Order(), revelacao.Lados[0].Order());
        Assert.Equal([duda.Id], revelacao.Lados[1]);
        Assert.Equal(1, duda.Pontos);
    }

    [Fact]
    public void EmpateNinguemLeva()
    {
        var mesa = Montar();

        mesa.Escolher(mesa.Todos[0], "0");
        mesa.Escolher(mesa.Todos[1], "1");
        mesa.Escolher(mesa.Todos[2], "0");
        mesa.Escolher(mesa.Todos[3], "1");

        Assert.Empty(mesa.Visao(mesa.Todos[0]).Revelacao!.Perderam);
        Assert.All(mesa.Todos, j => Assert.Equal(0, j.Pontos));
    }

    [Fact]
    public void TodoMundoIgualNinguemLeva()
    {
        var mesa = Montar();

        foreach (var jogador in mesa.Todos) mesa.Escolher(jogador, "1");

        var revelacao = mesa.Visao(mesa.Todos[0]).Revelacao!;
        Assert.Empty(revelacao.Perderam);
        Assert.Empty(revelacao.Lados[0]);
        Assert.Equal(4, revelacao.Lados[1].Count);
    }

    [Fact]
    public void PrecisaDeTresPessoasParaTerMinoria()
    {
        var baralho = new Baralho([PraiaOuMontanha]);
        var configuracao = new ConfiguracaoDoJogo(NivelDaCarta.Leve, [ModoDeJogo.IssoOuAquilo], true);

        Assert.Null(baralho.Sortear(configuracao, new HashSet<string>(), 2, false, new Random(1)));
        Assert.NotNull(baralho.Sortear(configuracao, new HashSet<string>(), 3, false, new Random(1)));
    }

    [Fact]
    public void BancoTemCartasDoIssoOuAquiloTodasComDuasOpcoes()
    {
        var cartas = CatalogoDeCartas.Carregar().Cartas.Where(c => c.Modo == ModoDeJogo.IssoOuAquilo).ToList();

        Assert.True(cartas.Count >= 30, $"só {cartas.Count} cartas");
        Assert.All(cartas, c =>
        {
            Assert.StartsWith("io-", c.Id);
            Assert.Equal(2, c.Opcoes?.Count);
            Assert.All(c.Opcoes!, o => Assert.InRange(o.Length, 1, 28));
        });
    }
}
