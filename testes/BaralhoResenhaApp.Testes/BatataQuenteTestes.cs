using BaralhoResenhaApp.Api.Dominio;
using BaralhoResenhaApp.Api.Infraestrutura;
using Microsoft.Extensions.Time.Testing;

namespace BaralhoResenhaApp.Testes;

/// <summary>
/// 🥔 Batata quente: a carta dá a categoria ("marcas de cerveja") e a batata
/// começa com o {jogador}. Quem está com ela fala uma coisa da categoria e
/// toca em "Falei!": a batata passa para o próximo. O pavio é segredo do
/// servidor; quando estoura, quem está com a batata leva ponto.
/// </summary>
public sealed class BatataQuenteTestes
{
    private static readonly Carta Cervejas =
        new("bq-1", ModoDeJogo.BatataQuente, NivelDaCarta.Leve, "Marcas de cerveja");

    private sealed record Mesa(Sala Sala, Jogador[] Todos, FakeTimeProvider Relogio)
    {
        public int Rodada => Sala.Rodada!.Numero;
        public Jogador ComABatata => Todos.Single(j => j.Id == Sala.Rodada!.ComABatata);
        public RodadaVisivel Visao(Jogador jogador) => Sala.Visao(jogador.Token).Rodada!;
        public void Falei(Jogador jogador) => Sala.PassarABatata(jogador.Token, Rodada);

        /// <summary>O tempo passa com todo mundo de celular na mão (ninguém cai).</summary>
        public void Esperar(double segundos)
        {
            Relogio.Advance(TimeSpan.FromSeconds(segundos));
            foreach (var jogador in Todos) Sala.Visao(jogador.Token);
        }
    }

    private static Mesa Montar(int? pavio = 30)
    {
        var relogio = new FakeTimeProvider(DateTimeOffset.UtcNow);
        var sala = new Sala("ABCD", new Baralho([Cervejas]), new Random(8), relogio);
        if (pavio is { } segundos) sala.SegundosDoPavio = (segundos, segundos);
        var todos = new[] { "Ana", "Beto", "Caio", "Duda" }.Select(n => sala.Entrar(n, false)).ToArray();
        sala.Configurar(todos[0].Token, new ConfiguracaoDoJogo(NivelDaCarta.Leve, [ModoDeJogo.BatataQuente], ZonaSegura: true,
            Ritmo: RitmoDaBebida.Raiz));
        sala.Comecar(todos[0].Token);
        return new Mesa(sala, todos, relogio);
    }

    [Fact]
    public void ABatataComecaComOPrimeiroDaFilaETodoMundoEstaNaRoda()
    {
        var mesa = Montar();

        var rodada = mesa.Sala.Rodada!;
        Assert.Equal(rodada.Fila[0], rodada.ComABatata);
        Assert.Equal(mesa.Todos.Select(j => j.Id).Order(), rodada.Fila.Order());
        Assert.Equal(rodada.ComABatata, mesa.Visao(mesa.Todos[0]).ComABatata);
        Assert.Equal(FaseDaSala.Carta, mesa.Sala.Fase);
    }

    [Fact]
    public void SoQuemEstaComABatataPassa()
    {
        var mesa = Montar();
        var outro = mesa.Todos.First(j => j.Id != mesa.ComABatata.Id);

        var erro = Assert.Throws<AcaoNaoPermitidaException>(() => mesa.Falei(outro));
        Assert.Equal($"A batata está com {mesa.ComABatata.Nome}.", erro.Message);
    }

    [Fact]
    public void FaleiPassaParaOProximoDaFilaEDaAVolta()
    {
        var mesa = Montar();
        var fila = mesa.Sala.Rodada!.Fila;

        for (var vez = 1; vez <= fila.Count; vez++)
        {
            mesa.Falei(mesa.ComABatata);
            Assert.Equal(fila[vez % fila.Count], mesa.Sala.Rodada!.ComABatata);
        }
    }

    [Fact]
    public void ABatataPulaQuemCaiuDaSala()
    {
        var mesa = Montar(pavio: 40);
        var caiu = mesa.Todos[3];
        // Mais de um minuto sem notícia do celular da Duda; a carta seguinte sai com ela fora do ar.
        mesa.Relogio.Advance(TimeSpan.FromSeconds(61));
        foreach (var jogador in mesa.Todos.Where(j => j != caiu)) mesa.Sala.Visao(jogador.Token);
        mesa.Sala.Proxima(mesa.Todos[0].Token, mesa.Rodada);
        Assert.False(mesa.Sala.Conectado(caiu));
        Assert.Contains(caiu.Id, mesa.Sala.Rodada!.Fila);

        for (var vez = 0; vez < mesa.Todos.Length; vez++)
        {
            Assert.NotEqual(caiu.Id, mesa.Sala.Rodada!.ComABatata);
            mesa.Falei(mesa.ComABatata);
        }
    }

    [Fact]
    public void QuandoOPavioAcabaEstouraNaMaoDeQuemEstaComABatata()
    {
        var mesa = Montar(pavio: 30);
        mesa.Falei(mesa.ComABatata);
        var comABatata = mesa.ComABatata;

        mesa.Esperar(29);
        Assert.False(mesa.Sala.ConferirBatata());
        Assert.Equal(FaseDaSala.Carta, mesa.Sala.Fase);

        mesa.Esperar(1);
        Assert.True(mesa.Sala.ConferirBatata());

        Assert.Equal(FaseDaSala.Revelada, mesa.Sala.Fase);
        var revelacao = mesa.Visao(mesa.Todos[0]).Revelacao!;
        Assert.Equal([comABatata.Id], revelacao.Perderam);
        Assert.Equal(1, comABatata.Pontos);
        Assert.All(mesa.Todos.Where(j => j != comABatata), j => Assert.Equal(0, j.Pontos));
        // Estourou uma vez só.
        Assert.False(mesa.Sala.ConferirBatata());
        Assert.Equal(1, comABatata.Pontos);
    }

    [Fact]
    public void FaleiDepoisDoEstouroNaoSalvaNinguem()
    {
        var mesa = Montar(pavio: 30);
        var comABatata = mesa.ComABatata;

        mesa.Esperar(31);
        mesa.Falei(comABatata);

        Assert.Equal(FaseDaSala.Revelada, mesa.Sala.Fase);
        Assert.Equal([comABatata.Id], mesa.Visao(comABatata).Revelacao!.Perderam);
    }

    [Fact]
    public void OPavioDuraDe20A45SegundosESoOServidorSabe()
    {
        Assert.Equal((20, 45), new Sala("ABCD", new Baralho([Cervejas])).SegundosDoPavio);
        Assert.DoesNotContain(typeof(RodadaVisivel).GetProperties(),
            p => p.Name.Contains("Estoura") || p.Name.Contains("Pavio"));

        var mesa = Montar(pavio: null);
        mesa.Esperar(19.9);
        Assert.False(mesa.Sala.ConferirBatata());
        mesa.Esperar(25.1);
        Assert.True(mesa.Sala.ConferirBatata());
    }

    [Fact]
    public void OServidorConfereOPavioDeTodasAsSalas()
    {
        var relogio = new FakeTimeProvider(DateTimeOffset.UtcNow);
        var salas = new SalasEmMemoria(new Baralho([Cervejas]), relogio);
        var sala = salas.Criar();
        var ana = sala.Entrar("Ana", false);
        sala.Entrar("Beto", false);
        sala.Configurar(ana.Token, new ConfiguracaoDoJogo(NivelDaCarta.Leve, [ModoDeJogo.BatataQuente], true));
        sala.Comecar(ana.Token);

        Assert.Empty(salas.ConferirBatatas());
        relogio.Advance(TimeSpan.FromSeconds(46));

        Assert.Equal([sala.Codigo], salas.ConferirBatatas());
        Assert.Empty(salas.ConferirBatatas());
    }

    [Fact]
    public void BancoTemCategoriasDaBatataQuente()
    {
        var cartas = CatalogoDeCartas.Carregar().Cartas.Where(c => c.Modo == ModoDeJogo.BatataQuente).ToList();

        Assert.True(cartas.Count >= 25, $"só {cartas.Count} cartas");
        Assert.All(cartas, c => Assert.StartsWith("bq-", c.Id));
    }
}
