using BaralhoResenhaApp.Api.Dominio;
using BaralhoResenhaApp.Api.Infraestrutura;

namespace BaralhoResenhaApp.Testes;

/// <summary>
/// 🙈 Quem sou eu?: a carta é um segredo (um objeto, um bicho, um famoso…) que
/// todo mundo vê, menos a pessoa da vez. Ela faz perguntas de sim ou não em voz
/// alta até acertar, contra o cronômetro. Acertou, ganha carta na manga; o
/// tempo acabou, leva ponto.
/// </summary>
public sealed class QuemSouEuTestes
{
    private static readonly Carta Geladeira = new("qs-1", ModoDeJogo.QuemSouEu, NivelDaCarta.Leve, "Geladeira",
        Categoria: "Objeto");

    private sealed record Mesa(Sala Sala, Jogador[] Todos)
    {
        public int Rodada => Sala.Rodada!.Numero;
        public Jogador DaVez => Todos.Single(j => j.Id == Sala.Rodada!.Alvo);
        public Jogador Outro => Todos.First(j => j.Id != Sala.Rodada!.Alvo);
        public RodadaVisivel Visao(Jogador jogador) => Sala.Visao(jogador.Token).Rodada!;
    }

    private static Mesa Montar()
    {
        var sala = new Sala("ABCD", new Baralho([Geladeira]), new Random(4));
        var todos = new[] { "Ana", "Beto", "Caio" }.Select(n => sala.Entrar(n, false)).ToArray();
        sala.Configurar(todos[0].Token, new ConfiguracaoDoJogo(NivelDaCarta.Leve, [ModoDeJogo.QuemSouEu], ZonaSegura: true,
            Ritmo: RitmoDaBebida.Raiz));
        sala.Comecar(todos[0].Token);
        return new Mesa(sala, todos);
    }

    [Fact]
    public void TodoMundoVeOSegredoMenosAPessoaDaVez()
    {
        var mesa = Montar();

        Assert.Equal("Geladeira", mesa.Visao(mesa.Outro).Texto);
        Assert.Equal("🙈 Quem é você?", mesa.Visao(mesa.DaVez).Texto);
        // A categoria é a primeira pista, e todo mundo vê.
        Assert.Equal("Objeto", mesa.Visao(mesa.DaVez).Dica);
        Assert.Equal(90, mesa.Visao(mesa.DaVez).CronometroSegundos);
    }

    [Fact]
    public void APessoaDaVezSegueORodizio()
    {
        var mesa = Montar();
        var daVez = new List<Guid>();

        for (var i = 0; i < 3; i++)
        {
            daVez.Add(mesa.DaVez.Id);
            mesa.Sala.Proxima(mesa.Todos[0].Token, mesa.Rodada);
        }

        Assert.Equal(3, daVez.Distinct().Count());
    }

    [Fact]
    public void AcertouGanhaCartaNaMangaENaoLevaPonto()
    {
        var mesa = Montar();
        var daVez = mesa.DaVez;
        var mao = daVez.Mao.Count;

        mesa.Sala.ResultadoDoQuemSouEu(mesa.Todos[0].Token, mesa.Rodada, acertou: true);

        var rodada = mesa.Visao(daVez);
        Assert.Equal(FaseDaSala.Revelada, mesa.Sala.Fase);
        Assert.Equal("Geladeira", rodada.Texto);
        Assert.Equal([daVez.Id], rodada.Revelacao!.Escolhidos);
        Assert.Empty(rodada.Revelacao.Perderam);
        Assert.Equal(mao + 1, daVez.Mao.Count);
        Assert.Equal(0, daVez.Pontos);
    }

    [Fact]
    public void OTempoAcabouLevaPonto()
    {
        var mesa = Montar();
        var daVez = mesa.DaVez;

        mesa.Sala.ResultadoDoQuemSouEu(mesa.Todos[0].Token, mesa.Rodada, acertou: false);

        Assert.Equal([daVez.Id], mesa.Visao(daVez).Revelacao!.Perderam);
        Assert.Equal(1, daVez.Pontos);
    }

    [Fact]
    public void SoQuemCriouASalaMarcaOResultado()
    {
        var mesa = Montar();
        var convidado = mesa.Todos[1];

        var erro = Assert.Throws<AcaoNaoPermitidaException>(
            () => mesa.Sala.ResultadoDoQuemSouEu(convidado.Token, mesa.Rodada, acertou: true));
        Assert.Equal("Quem marca o resultado é quem criou a sala.", erro.Message);
    }

    [Fact]
    public void BancoTemDeTudoUmPoucoNoQuemSouEu()
    {
        var cartas = CatalogoDeCartas.Carregar().Cartas.Where(c => c.Modo == ModoDeJogo.QuemSouEu).ToList();

        Assert.True(cartas.Count >= 80, $"só {cartas.Count} cartas");
        Assert.All(cartas, c =>
        {
            Assert.StartsWith("qs-", c.Id);
            Assert.False(string.IsNullOrWhiteSpace(c.Categoria));
        });
        // Não é só famoso: a graça é ser qualquer coisa.
        var categorias = cartas.GroupBy(c => c.Categoria).ToDictionary(g => g.Key!, g => g.Count());
        Assert.True(categorias.Count >= 8, string.Join(", ", categorias.Keys));
        Assert.True(categorias.Values.Max() <= cartas.Count / 4, "uma categoria domina o baralho");
    }
}
