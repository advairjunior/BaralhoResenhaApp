using BaralhoResenhaApp.Api.Dominio;
using BaralhoResenhaApp.Api.Infraestrutura;

namespace BaralhoResenhaApp.Testes;

/// <summary>
/// Duelo: {jogador} contra {jogador2}, a turma vota no celular em quem mandou
/// melhor. Os dois do duelo não votam; quem perde leva o ponto.
/// </summary>
public sealed class DueloTestes
{
    private static readonly Carta Duelo = new("mp-d1", ModoDeJogo.MaisProvavel, NivelDaCarta.Leve,
        "Duelo de dancinha: {jogador} contra {jogador2}.", Duelo: true);

    private sealed record Mesa(Sala Sala, Jogador[] Todos)
    {
        public Jogador Duelista(int i) => Todos.Single(j => j.Id == Sala.Rodada!.Duelistas[i]);
        public List<Jogador> Jurados => Todos.Where(j => !Sala.Rodada!.Duelistas.Contains(j.Id)).ToList();
        public int Rodada => Sala.Rodada!.Numero;
    }

    private static Mesa Montar(int pessoas = 5)
    {
        var sala = new Sala("ABCD", new Baralho([Duelo]), new Random(2)) { ChanceDeVotacao = 0 };
        var todos = new[] { "Ana", "Beto", "Caio", "Duda", "Edu" }.Take(pessoas)
            .Select(n => sala.Entrar(n, false)).ToArray();
        sala.Configurar(todos[0].Token, new ConfiguracaoDoJogo(NivelDaCarta.Leve, [ModoDeJogo.MaisProvavel], true,
            Ritmo: RitmoDaBebida.Raiz));
        sala.Comecar(todos[0].Token);
        return new Mesa(sala, todos);
    }

    [Fact]
    public void DueloEhSempreVotadoNoCelularEntreOsDoisDaCarta()
    {
        var mesa = Montar();
        var rodada = mesa.Sala.Rodada!;

        Assert.True(rodada.Votacao);
        Assert.Equal(2, rodada.Duelistas.Count);
        Assert.Equal($"Duelo de dancinha: {mesa.Duelista(0).Nome} contra {mesa.Duelista(1).Nome}.", rodada.Texto);
        Assert.Equal(rodada.Duelistas, mesa.Sala.Visao(mesa.Todos[0].Token).Rodada!.Duelistas);
    }

    [Fact]
    public void QuemEstaNoDueloNaoVotaESoValeVotarEmUmDosDois()
    {
        var mesa = Montar();

        var erro = Assert.Throws<AcaoNaoPermitidaException>(() => mesa.Sala.Responder(
            mesa.Duelista(0).Token, mesa.Rodada, mesa.Duelista(0).Id.ToString()));
        Assert.Equal("Você está no duelo: quem decide é a turma.", erro.Message);

        var jurado = mesa.Jurados[0];
        erro = Assert.Throws<AcaoNaoPermitidaException>(
            () => mesa.Sala.Responder(jurado.Token, mesa.Rodada, mesa.Jurados[1].Id.ToString()));
        Assert.Equal("Vote em um dos dois do duelo.", erro.Message);
    }

    [Fact]
    public void QuandoOsJuradosVotamQuemPerdeLevaOPontoEQuemGanhaContaVitoria()
    {
        var mesa = Montar();
        var (primeiro, segundo) = (mesa.Duelista(0), mesa.Duelista(1));
        var jurados = mesa.Jurados;
        mesa.Sala.Responder(jurados[0].Token, mesa.Rodada, primeiro.Id.ToString());
        mesa.Sala.Responder(jurados[1].Token, mesa.Rodada, primeiro.Id.ToString());
        Assert.Equal(FaseDaSala.Carta, mesa.Sala.Fase);
        mesa.Sala.Responder(jurados[2].Token, mesa.Rodada, segundo.Id.ToString());

        var revelacao = mesa.Sala.Rodada!.Revelacao!;
        Assert.Equal(FaseDaSala.Revelada, mesa.Sala.Fase);
        Assert.Equal([primeiro.Id], revelacao.Escolhidos);
        Assert.Equal([segundo.Id], revelacao.Perderam);
        Assert.Equal(1, segundo.Pontos);
        Assert.Equal(0, primeiro.Pontos);
        Assert.Equal(1, primeiro.Estatisticas.DuelosVencidos);
        Assert.Equal(0, primeiro.Estatisticas.VotosRecebidos);
    }

    [Fact]
    public void EmpateNoDueloOsDoisLevamPonto()
    {
        var mesa = Montar(pessoas: 4);
        var (primeiro, segundo) = (mesa.Duelista(0), mesa.Duelista(1));
        mesa.Sala.Responder(mesa.Jurados[0].Token, mesa.Rodada, primeiro.Id.ToString());
        mesa.Sala.Responder(mesa.Jurados[1].Token, mesa.Rodada, segundo.Id.ToString());

        var revelacao = mesa.Sala.Rodada!.Revelacao!;
        Assert.Equal(2, revelacao.Perderam.Count);
        Assert.Equal(2, revelacao.Escolhidos.Count);
    }

    [Fact]
    public void UmEmCadaTresQuemEhMaisProvavelEhDuelo()
    {
        var cartas = Enumerable.Range(1, 9)
            .Select(i => new Carta($"mp-{i}", ModoDeJogo.MaisProvavel, NivelDaCarta.Leve, $"Quem {i}?"))
            .Append(Duelo)
            .ToList();
        var baralho = new Baralho(cartas);
        var sorteio = new Random(5);
        var configuracao = new ConfiguracaoDoJogo(NivelDaCarta.Leve, [ModoDeJogo.MaisProvavel], true);

        var duelos = Enumerable.Range(0, 1000)
            .Count(_ => baralho.Sortear(configuracao, new HashSet<string>(), 4, false, sorteio)!.Duelo);

        Assert.InRange(duelos / 1000.0, 0.25, 0.45);
    }

    [Fact]
    public void QuemMaisVenceDueloLevaPremio()
    {
        var ana = new Jogador { Id = Guid.NewGuid(), Token = "a", Nome = "Ana" };
        ana.Estatisticas.DuelosVencidos = 2;

        var premio = PremiosDaNoite.Calcular([ana], []).Single();

        Assert.Equal("Rei(nha) dos duelos", premio.Titulo);
        Assert.Equal("Venceu 2 duelos", premio.Descricao);
    }

    [Fact]
    public void BebaSeNaoTemMaisCartaDeVotacao()
    {
        var baralho = CatalogoDeCartas.Carregar();

        Assert.DoesNotContain(baralho.Cartas, c => c.Modo == ModoDeJogo.BebaSe &&
            (c.Texto.Contains("vota", StringComparison.OrdinalIgnoreCase) || c.Texto.Contains("decide")));
        var duelos = baralho.Cartas.Where(c => c.Duelo).ToList();
        Assert.True(duelos.Count >= 8);
        Assert.All(duelos, c =>
        {
            Assert.Equal(ModoDeJogo.MaisProvavel, c.Modo);
            Assert.Contains("{jogador}", c.Texto);
            Assert.Contains("{jogador2}", c.Texto);
        });
    }
}
