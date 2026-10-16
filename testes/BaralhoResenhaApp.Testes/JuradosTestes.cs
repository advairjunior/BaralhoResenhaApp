using BaralhoResenhaApp.Api.Dominio;
using BaralhoResenhaApp.Api.Infraestrutura;

namespace BaralhoResenhaApp.Testes;

/// <summary>
/// Jurados: o app elege uma pessoa e o resto dá nota de 1 a 5 estrelas, em
/// segredo ("o quanto {jogador} se veste bem?"). Média alta, a pessoa
/// distribui goles; média baixa, leva o ponto.
/// </summary>
public sealed class JuradosTestes
{
    private static readonly Carta Estilo = new("ju-1", ModoDeJogo.Jurados, NivelDaCarta.Leve,
        "De 1 a 5 estrelas: o quanto {jogador} se veste bem?");

    private sealed record Mesa(Sala Sala, Jogador[] Todos)
    {
        public Jogador Avaliado => Todos.Single(j => j.Id == Sala.Rodada!.Alvo);
        public List<Jogador> Jurados => Todos.Where(j => j.Id != Sala.Rodada!.Alvo).ToList();
        public int Rodada => Sala.Rodada!.Numero;
    }

    private static Mesa Montar()
    {
        var sala = new Sala("ABCD", new Baralho([Estilo]), new Random(6));
        var todos = new[] { "Ana", "Beto", "Caio", "Duda" }.Select(n => sala.Entrar(n, false)).ToArray();
        sala.Configurar(todos[0].Token, new ConfiguracaoDoJogo(NivelDaCarta.Leve, [ModoDeJogo.Jurados], true,
            Ritmo: RitmoDaBebida.Raiz));
        sala.Comecar(todos[0].Token);
        return new Mesa(sala, todos);
    }

    private static void Notas(Mesa mesa, params string[] notas)
    {
        var jurados = mesa.Jurados;
        for (var i = 0; i < jurados.Count; i++) mesa.Sala.Responder(jurados[i].Token, mesa.Rodada, notas[i]);
    }

    [Fact]
    public void OAppElegeUmaPessoaEOsOutrosDaoNota()
    {
        var mesa = Montar();

        Assert.Equal($"De 1 a 5 estrelas: o quanto {mesa.Avaliado.Nome} se veste bem?", mesa.Sala.Rodada!.Texto);
        Assert.True(mesa.Sala.Rodada.PedeResposta);
        var erro = Assert.Throws<AcaoNaoPermitidaException>(
            () => mesa.Sala.Responder(mesa.Avaliado.Token, mesa.Rodada, "5"));
        Assert.Equal("Essa é sobre você: espera a nota dos jurados.", erro.Message);
        erro = Assert.Throws<AcaoNaoPermitidaException>(
            () => mesa.Sala.Responder(mesa.Jurados[0].Token, mesa.Rodada, "6"));
        Assert.Equal("Dê uma nota de 1 a 5 estrelas.", erro.Message);
    }

    [Fact]
    public void MediaAltaAprovaEOAvaliadoDistribuiGoles()
    {
        var mesa = Montar();
        Notas(mesa, "5", "4", "4");

        var revelacao = mesa.Sala.Rodada!.Revelacao!;
        Assert.Equal(FaseDaSala.Revelada, mesa.Sala.Fase);
        Assert.Equal(4.3, revelacao.Media);
        Assert.Equal([4, 4, 5], revelacao.Notas);
        Assert.True(revelacao.Elogio);
        Assert.Equal([mesa.Avaliado.Id], revelacao.Escolhidos);
        Assert.Empty(revelacao.Perderam);
        Assert.Equal(0, mesa.Avaliado.Pontos);
    }

    [Fact]
    public void MediaBaixaReprovaEOAvaliadoLevaOPonto()
    {
        var mesa = Montar();
        Notas(mesa, "1", "2", "3");

        var revelacao = mesa.Sala.Rodada!.Revelacao!;
        Assert.Equal(2.0, revelacao.Media);
        Assert.Equal([mesa.Avaliado.Id], revelacao.Perderam);
        Assert.Equal(1, mesa.Avaliado.Pontos);
    }

    [Fact]
    public void NaMediaNinguemLeva()
    {
        var mesa = Montar();
        Notas(mesa, "3", "3", "4");

        var revelacao = mesa.Sala.Rodada!.Revelacao!;
        Assert.Equal(3.3, revelacao.Media);
        Assert.Empty(revelacao.Perderam);
        Assert.Empty(revelacao.Escolhidos);
    }

    [Fact]
    public void BancoTemCartasDeJuradosEmTodoNivelComAPessoaDaCarta()
    {
        var cartas = CatalogoDeCartas.Carregar().Cartas.Where(c => c.Modo == ModoDeJogo.Jurados).ToList();

        Assert.All(cartas, c => Assert.Contains("{jogador}", c.Texto));
        foreach (var nivel in new[] { NivelDaCarta.Leve, NivelDaCarta.Resenha, NivelDaCarta.Picante })
            Assert.True(cartas.Count(c => c.Nivel == nivel) >= 8, $"{nivel} tem poucas cartas de jurados");
    }
}
